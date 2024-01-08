This plugin using
```lua
- local http = require "resty.http"
- local cookie = require "resty.cookie"
```
By default `resty.http` already exists in default kong image, but unfortunately `resty.cookie` not exists in kong default image. you can verify with `luarocks list` after you ssh inside container of kong

If we look at this [documentation](https://docs.konghq.com/kubernetes-ingress-controller/latest/plugins/custom/#helm), this is install using helm, and pointing the plugin as configmap, but again since `resty.cookie` we need to custom the image

## Example
### 1. So instead we need to use custom image that you build from this repository.
Build the image
```bash
docker build -f ./Dockerfile -t <your-username>/kong-gateway .
docker tag <your-username>/kong-gateway:latest <your-username>/kong-gateway:1.0
docker push <your-username>/kong-gateway:1.0
```
### 2. Create config map file
```bash
# Make sure you're in right directory
cd kong-auth-integration

# Create namespaces
kubectl create namespace kong

# Create Configmap Custom Plugin which later will used for helm
kubectl create configmap kong-plugin-kong-auth-integration --from-file=kong/plugins/kong-auth-integration -n kong
```

### 3. For this example using helm to install kong, you refer to [this](https://artifacthub.io/packages/helm/kong/kong)
Create `values.yaml`
```yaml
image:
  repository: <your-username>/kong-gateway
  tag: "1.0"

# Admin API, To interract with the kong configuration
admin:
  enabled: true
  type: LoadBalancer
  http:
    enabled: true
  tls:
    enabled: false

# Important
plugins:
  configMaps:
  - pluginName: kong-auth-integration
    name: kong-plugin-kong-auth-integration

# You need enabled this env
env:
  database: "postgres"

# Use this if we used internal database
postgresql:
  enabled: true
  auth:
    postgresPassword: kong
    password: kong

# you can enable if you want
ingressController:
  enabled: false

# We disable the manager since we will use Admin PI
manager:
  enabled: false
```

### 3. Install kong using Helm
```bash
# Install the kong gateway using
helm install kong kong/kong -n kong --create-namespace --values values.yaml

# Check the status of the all pod
kubectl get all -n kong
```

### 4. Create Custom Plugin configuration
Create `plugin.yaml`
```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: kong-auth-integration
config:
  token_header: Authorization
  cookie_name: access-token
  authentication_endpoint: http://host.docker.internal:4500/api/v1/session/me
plugin: kong-auth-integration

```

```bash
kubectl apply -f plugin.yaml -n kong
```

### 5. Access the Admin API
Open the url `http://<your-ip-node>:8100`
