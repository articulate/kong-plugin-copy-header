return {
  no_consumer = false, 
  fields = {
    headers = {type = "table"} 
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    return true
  end
}
