# Kong Auth Integration

![Concepts](./images/auth.svg)

The idea is to get information about behind the scenes of access token, so before access the resources, you need to add jwt token, then token will pass to the 3rd party application then the return of the **BODY** will attach to the request in backend service, it can be in two ways:
- Authorization Headers
- Cookie ( if you implement CSRF protection, you might be attach automatically the access token)

### What's the parameter

- `token_header` name of the header which hold access token
	- type: **string**
	- default: **Authorization**
- `cookie_name` name of the cookie of which hold the access token
  - type: **string**
  - default: **access-token**
- `authentication_endpoint` url of the 3rd party authentication service
	- type: **URL**
	- required: **true**
	- method: **GET**

### What's the headers which attached into the request

payload body will attach in:
- headers `X-User-Payload`

## How to Install
For this example we used docker to install
### Build the docker Images
```bash
docker build -f ./Dockerfile -t zulfikar4568/kong-gateway .
```

### Start the Database
```bash
docker run -d --name "kong-quickstart-database" --network="kong-quickstart-net" -e "POSTGRES_DB=postgres" -e "POSTGRES_USER=kong" -e "POSTGRES_PASSWORD=kong" postgres:13
```

### Migrate database to kong
```bash
docker run --rm --network=kong-quickstart-net \
 -e "KONG_DATABASE=postgres" \
 -e "KONG_PG_HOST=kong-quickstart-database" \
 -e "KONG_PG_USER=kong" \
 -e "KONG_PG_PASSWORD=kong" \
 -e "KONG_PASSWORD=test" \
zulfikar4568/kong-gateway kong migrations bootstrap
```

### Run kong gateway using Docker
```bash
docker run -d --name=kong-gateway \
  --network=kong-quickstart-net \
	-e "KONG_DATABASE=postgres" \
	-e "KONG_PG_HOST=kong-quickstart-database" \
	-e "KONG_PG_USER=kong" \
	-e "KONG_PG_PASSWORD=kong" \
	-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
	-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
	-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
	-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
	-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
	-e "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
	-e "KONG_VERSION=" \
	-e "KONG_PREFIX=/usr/local/kong" \
  -p 8000:8000 \
  -p 8001:8001 \
  -p 8002:8002 \
  -p 8003:8003 \
  -p 8004:8004 \
  zulfikar4568/kong-gateway
```

### Try to put plugin in services
```bash
curl -X POST http://localhost:8001/services/example_service/plugins \
   --data "name=kong-auth-integration" \
   --data config.token_header=Authorization \
	 --data config.cookie_name=access-token \
   --data config.authentication_endpoint=http://localhost:3000/api/v1/auth/me
 ```
