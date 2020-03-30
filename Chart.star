def init(self,domain=None,image_pull_secrets=None):
  self.domain = domain

  if not image_pull_secrets:
    fail("mandatory parameter image_pull_secrets not given")

  self.image_pull_secrets = image_pull_secrets

  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  overlays = self.helm("config",glob="ingress.yml") # Skip certificates.yml because it interrupts communication to capi
  self.cf4k8s = chart("https://github.com/kramerul/cf-for-k8s/archive/shalm.zip",domain=domain,ytt_files=[overlays],namespace="cf-system")

def credentials(self):
  return self.cf4k8s.credentials()

def uaa_credentials(self):
  return self.cf4k8s.uaa_credentials()