local helpers = require "spec.helpers"

describe("copy-header", function()
  local client

  setup(function()
    -- The host header is how the test is associated with the proper config for the apis listed below.
    local api1 = assert(helpers.dao.apis:insert { 
      name = "api-1", 
      hosts = { "test1.com" }, 
      upstream_url = helpers.mock_upstream_url,
    })

    local api2 = assert(helpers.dao.apis:insert {
      name = "api-2",
      hosts = { "test2.com" },
      upstream_url = helpers.mock_upstream_url,
    })

    assert(helpers.dao.plugins:insert {
      api_id = api1.id,
      name = "copy-header",
      config = {
        headers = {
          {
            ["original"] = "x-forwarded-for", 
            ["new"] = "copied-forwarded-for",
            ["client_ip_only"] = true
          }
        }
      }
    })

    assert(helpers.dao.plugins:insert {
      api_id = api2.id,
      name = "copy-header",
      config = {
        headers = {
          {
            ["original"] = "my-ips",
            ["new"] = "copied-my-ips",
          }
        }
      }
    })

    assert(helpers.start_kong {
      custom_plugins = "copy-header",
      nginx_conf = "spec/fixtures/custom_nginx.template"
    })
  end)

  teardown(function()
    helpers.stop_kong()
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then client:close() end
  end)

  describe("requests", function()
    it("does not set copied-forwarded-for when missing the x-forwarded-for header", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["host"] = "test1.com",
        }
      })
      assert.response(r).has.status(200)
      assert.request(r).has_no.header("copied-forwarded-for")
    end)

    it("does not set copied-forwarded-for when private ips are set in x-forwarded-for without a public ip", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["host"] = "test1.com",
          ["x-forwarded-for"] = "172.16.0.1, 10.10.10.10, 192.168.1.2"
        }
      })
      assert.response(r).has.status(200)
      assert.request(r).has_no.header("copied-forwarded-for")
    end)

    it("sets copied-forwarded-for to the client ip in x-forwarded-for", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request", 
        headers = {
          ["host"] = "test1.com",
          ["x-forwarded-for"] = "4.3.11.0"
        }
      })
      assert.response(r).has.status(200)
      local header_value = assert.request(r).has.header("copied-forwarded-for")
      assert.equal("4.3.11.0", header_value)
    end)

    it("sets copied-forwarded-for to the first public ip from a list of private and public ips in x-forwarded-for", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["host"] = "test1.com",
          ["x-forwarded-for"] = "172.16.0.1, 10.10.10.10, 192.168.1.2, 8.8.8.8, 4.2.2.2"
        }
      })
      assert.response(r).has.status(200)
      local header_value = assert.request(r).has.header("copied-forwarded-for")
      assert.equal("8.8.8.8", header_value)
    end)

    it("copies a header to a new header", function()
      local r = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["host"] = "test2.com",
          ["my-ips"] = "172.168.0.1, 10.10.10.10, 1.2.3.4"
        }
      })
      assert.response(r).has.status(200)
      local header_value = assert.request(r).has.header("copied-my-ips")
      assert.equal("172.168.0.1, 10.10.10.10, 1.2.3.4", header_value)
    end)
  end)
end)
