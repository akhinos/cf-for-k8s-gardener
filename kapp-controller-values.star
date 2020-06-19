load("@ytt:yaml", "yaml")

def api_server_ip():
    result = env("API_SERVER_IP")
    if len(result) == 0:
        return None
    return result

def certificate():
    result = env("CERTIFICATE")
    if len(result) == 0:
        return None
    return yaml.decode(result)

def docker_registry():
    result =  env("DOCKER_REGISTRY")
    if len(result) != 0:
        return yaml.decode(result)
    result = env("GCR_ADMIN_CREDENTIALS")
    if len(result) != 0:
        return { 'username': '_json_key', 'password': result, 'repository': 'gcr.io/sap-se-gcp-istio-dev/cf-workloads'}
    return None

def readonly_docker_registry():
    result = env("IMAGE_PULL_SECRETS")
    if len(result) != 0:
        return { 'username': '_json_key', 'password': result, 'repository': 'gcr.io/sap-se-gcp-istio-dev/cf-workloads'}
    return None

cf4k8s = chart(".", domain=env("CF_DOMAIN"), docker_registry=docker_registry(),readonly_docker_registry=readonly_docker_registry(),api_server_ip=api_server_ip(),certificate=certificate())
print(cf4k8s.kapp_controller_values())
