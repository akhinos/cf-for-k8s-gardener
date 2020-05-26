def init(self,domain=None, docker_registry=None, readonly_docker_registry=None, 
         sub_domains = [ "", "*.","*.authentication.","*.xsuaa-api.","*.cpp.","*.cockpit.","operator.operationsconsole." ],
         certificate = None,
         db_chart_url = None,
         default_identity_provider=None):
  self.__class__.name = "cf-for-k8s-gardener"

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry
  self.sub_domains = sub_domains
  self.certificate = certificate
  self.default_identity_provider = default_identity_provider
  self.readonly_docker_registry = readonly_docker_registry
  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  self.cf4k8s = chart("https://github.com/akhinos/cf-for-k8s/archive/shalm.zip",
    domain=domain,
    overlays=[inject("overlays",self=self)],
    namespace="cf-system",
    docker_registry=docker_registry)

  self.database = None
  if db_chart_url:
    self.database = chart(db_chart_url, namespace="c21s-db",ca=self.cf4k8s.ca)
    self.database.create_database("capi")
    self.database.create_database("uaa")


def domain(self):
  return self.cf4k8s.domain

def credentials(self):
  return self.cf4k8s.credentials()

def uaa_credentials(self):
  return self.cf4k8s.uaa_credentials()

def _set_domain(self,k8s):
  if not self.cf4k8s.domain:
    self.cf4k8s.domain = "cf." + k8s.host.partition('.')[2]
  self.cf4k8s.app_domains= [ self.cf4k8s.domain ]

def apply(self,k8s):
  if self.database:
    self.database.apply(k8s)
    self.capi_db_credentials = self.database.credentials("capi",k8s)
    self.uaa_db_credentials = self.database.credentials("uaa",k8s)

  self._set_domain(k8s)
  self.cf4k8s.apply(k8s)
  self.__apply(k8s)
  self.fix_kpack_watcher(k8s)

def fix_kpack_watcher(self,k8s):
  k8s.tool = "kubectl"
  k8s_service = k8s.get("service","kubernetes",namespace="default")
  kpack_watcher = k8s.get("deployments.apps","cf-api-kpack-watcher",namespace="cf-system")
  if not kpack_watcher.spec.template.metadata.get('annotations',None):
    kpack_watcher.spec.template.metadata.annotations = {}
  kpack_watcher.spec.template.metadata.annotations['traffic.sidecar.istio.io/excludeOutboundIPRanges'] = k8s_service.spec.clusterIP + '/32'
  k8s.tool = "kubectl"
  k8s.apply(kpack_watcher,namespace="cf-system")

def delete(self,k8s):
  self._set_domain(k8s)
  self.__delete(k8s)
  self.cf4k8s.delete(k8s)
  if self.database:
    self.database.delete(k8s)
