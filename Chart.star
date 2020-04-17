def init(self,domain=None, docker_registry=None, readonly_docker_registry=None, sub_domains = [ "", "*.","*.authentication.","*.xsuaa-api.","*.cpp.","*.cockpit.","operator.operationsconsole." ]):
  self.__class__.name = "cf-for-k8s-gardener"

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry

  self.sub_domains = sub_domains
  self.readonly_docker_registry = readonly_docker_registry
  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  overlays = self.helm("config",glob="ingress.yml") # Skip certificates.yml because it interrupts communication to capi
  self.cf4k8s = chart("https://github.com/akhinos/cf-for-k8s/archive/shalm.zip",domain=domain,ytt_files=[overlays],namespace="cf-system",docker_registry=docker_registry)

def domain(self):
  return self.cf4k8s.domain

def credentials(self):
  return self.cf4k8s.credentials()

def uaa_credentials(self):
  return self.cf4k8s.uaa_credentials()

def _set_domain(self,k8s):
  if not self.cf4k8s.domain:
    self.cf4k8s.domain = "cf." + k8s.host.partition('.')[2]

def apply(self,k8s):
  self._set_domain(k8s)
  self.cf4k8s.apply(k8s)
  self.__apply(k8s)

def delete(self,k8s):
  self._set_domain(k8s)
  self.__delete(k8s)
  self.cf4k8s.delete(k8s)
