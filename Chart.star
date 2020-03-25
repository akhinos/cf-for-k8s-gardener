def init(self,domain=None):
  self.domain = domain
  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  self.cf4k8s = chart("https://github.com/kramerul/cf-for-k8s/archive/shalm.zip",domain=domain,ytt_files=[self.helm("config",glob="ingress.yml")],namespace="cf-system")

def credentials(self):
  return self.cf4k8s.credentials()

def uaa_credentials(self):
  return self.cf4k8s.uaa_credentials()