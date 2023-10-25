local http = require "resty.http"
local cookie = require "resty.cookie"

local TokenHandler = {
  PRIORITY = 1000,
  VERSION = "0.1",
}

local function authenticate_access_token(conf, access_token, customer_id)
  local httpc = http:new()

  -- Call the endpoint of authentication
  local res, err = httpc:request_uri(conf.authentication_endpoint, {
    method = "GET",
    ssl_verify = false,
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. access_token }
  })

  -- If response doesn't obtain then internal server error
  if not res then
    kong.log.err("Failed to call authentication endpoint: ",err)
    return kong.response.exit(500, "Internal Server Error")
  end

  if res.status ~= 200 then
      kong.log.err("Authentication endpoint responded with status: ", res.status)

      -- Not allowed if 401
      if res.status == 401 then
        return kong.response.exit(401, "Unauthorized, You are not allowed access the resource!")  --unauthorized
      end

      return kong.response.exit(res.status)
  end

  -- Return the payload then forward to the client
  kong.service.request.add_header("X-User-Payload", res.body)

  return true
end

function TokenHandler:access(conf)
  local ck = cookie:new()
  local header_access_token = kong.request.get_headers()[conf.token_header]
  local cookie_access_token, err = ck:get(conf.cookie_name)

  -- Check header_access_token and cookie_access_token
  if not (header_access_token or cookie_access_token) then
    ngx.log(ngx.ERR, err)
    kong.response.exit(401, "Unauthorized, You are not allowed access the resource!")  --unauthorized
  end

  -- replace Bearer prefix
  if header_access_token then
    header_access_token = header_access_token:sub(8,-1) -- drop "Bearer "
  end

  -- Access token
  local access_token

  if cookie_access_token then
    access_token = cookie_access_token
  elseif header_access_token then
    access_token = header_access_token
  else
    kong.response.exit(401, "Unauthorized, You are not allowed access the resource!")  --unauthorized
  end

  authenticate_access_token(conf, access_token)

end

return TokenHandler
