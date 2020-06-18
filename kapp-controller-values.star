load("@ytt:yaml", "yaml")

# certificate = yaml.decode(env("CERTIFICATE"))
docker_registry = yaml.decode(env("DOCKER_REGISTRY"))
cf4k8s = chart(".", domain=env("CF_DOMAIN"), docker_registry=docker_registry)
print(cf4k8s.kapp_controller_values())
