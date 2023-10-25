local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "kong-auth-integration"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          { authentication_endpoint = typedefs.url({ required = true }) },
          { token_header = typedefs.header_name { default = "Authorization", required = true }, },
          { cookie_name = { type = "string", default = "access-token", required = false }, },
        },
      },
    },
  },
}

return schema
