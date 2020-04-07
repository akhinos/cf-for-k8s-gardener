def init(self,domain=None,docker_registry=None,readonly_docker_registry=None,):
  self.domain = domain
  self.__class__.name = "cf-for-k8s-gardener"
  if not docker_registry:
    fail("Mandatory parameter docker_registry is missing")

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry

  self.readonly_docker_registry = readonly_docker_registry
  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  overlays = self.helm("config",glob="ingress.yml") # Skip certificates.yml because it interrupts communication to capi
  self.cf4k8s = chart("https://github.com/akhinos/cf-for-k8s/archive/a85433bdb6d663dbab8abc5569e1d7ae952c9750.zip",domain=domain,ytt_files=[overlays],namespace="cf-system",docker_registry=docker_registry)

def credentials(self):
  return self.cf4k8s.credentials()

def uaa_credentials(self):
  return self.cf4k8s.uaa_credentials()