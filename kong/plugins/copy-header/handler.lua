local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local plugin = require("kong.plugins.base_plugin"):extend()

function plugin:new()
  plugin.super.new(self, plugin_name)
end

function plugin:access(plugin_conf)
  plugin.super.access(self)

  local headers = plugin_conf.headers

  -- this seems to be needed because biplane may be eating the array on a single entry in the config
  if headers.original then
    headers = { headers }
  end
    
  for _, header in pairs(headers) do
    if header.client_ip_only then
      local client_ip = get_client_ip(ngx.req.get_headers()[header.original])
      ngx.req.set_header(header.new, client_ip)
    else
      ngx.req.set_header(header.new, ngx.req.get_headers()[header.original])
    end
  end
end

function get_client_ip(ips)
  local pattern = "[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
  
  if ips ~= nil then
    for ip in ips:gmatch(pattern) do
      if is_public_ip(ip) then
        return ip
      end
    end
  end

  return nil
end

function is_public_ip(ip)
  class_a = "10%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
  class_b1 = "172%.1[6-9]%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
  class_b2 = "172%.2[0-9]%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
  class_b3 = "172%.3[01]%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
  class_c = "192%.168%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?"
 
  if ip:match(class_a) or ip:match(class_b1) or ip:match(class_b2) or
      ip:match(class_b3) or ip:match(class_c) then
    return false
  else 
    return true
  end
end

plugin.PRIORITY = 1000

return plugin
