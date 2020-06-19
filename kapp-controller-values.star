load("@ytt:yaml", "yaml")

def api_server_ip():
    result = env("API_SERVER_IP")
    if len(result) == 0:
        return None
    return result

# certificate = yaml.decode(env("CERTIFICATE"))
docker_registry = yaml.decode(env("DOCKER_REGISTRY"))
cf4k8s = chart(".", domain=env("CF_DOMAIN"), docker_registry=docker_registry,api_server_ip=api_server_ip())
print(cf4k8s.kapp_controller_values())
