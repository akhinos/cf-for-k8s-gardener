def init(self,domain=None, docker_registry=None, readonly_docker_registry=None, 
         sub_domains = [ "", "*.","*.authentication.","*.xsuaa-api.","*.cpp.","*.cockpit.","operator.operationsconsole." ],
         app_domain_prefix = None,
         db_chart_url = None):
  self.__class__.name = "cf-for-k8s-gardener"

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry
  self.sub_domains = sub_domains
  self.readonly_docker_registry = readonly_docker_registry
  self.istio_ingressgateway_credential_name = "cf-4-k8s-ingressgateway-certs"
  self.cf4k8s = chart("https://github.com/akhinos/cf-for-k8s/archive/shalm.zip",
    domain=domain,
    ytt_files=self._overlays,  # must be lazy
    namespace="cf-system",
    docker_registry=docker_registry)
  self.cc_db = None
  if db_chart_url:
    self.cc_db = chart(db_chart_url, namespace="c21s-db")
    self.cc_db_values = {}
    self.cc_db_values.adapter = self.cc_db.get_db_type()
    self.cc_db_values.port = self.cc_db.get_port()
    self.cc_db_values.host = self.cc_db.get_service()
    self.cc_db_values.user = self.cc_db.get_user()
    self.cc_db_values.database = self.cc_db.get_database()


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

def _overlays(self):
  return [ self.helm("config/values"), self.helm("config/overlays") ]

def apply(self,k8s):
  if self.cc_db:
    self.cc_db.apply(k8s)
    self.cc_db_values.password = self.cc_db.get_password(k8s)

  self._set_domain(k8s)
  self.cf4k8s.apply(k8s)
  self.__apply(k8s)
  self.fix_kpack_watcher(k8s)

def fix_kpack_watcher(self,k8s):
  k8s.tool = "kubectl"
  k8s_service = k8s.get("service","kubernetes",namespace="default")
  kpack_watcher = k8s.get("deployments.apps","capi-kpack-watcher",namespace="cf-system")
  if not kpack_watcher.spec.template.metadata.get('annotations',None):
    kpack_watcher.spec.template.metadata.annotations = {}
  kpack_watcher.spec.template.metadata.annotations['traffic.sidecar.istio.io/excludeOutboundIPRanges'] = k8s_service.spec.clusterIP + '/32'
  k8s.tool = "kubectl"
  k8s.apply(kpack_watcher,namespace="cf-system")

def delete(self,k8s):
  self._set_domain(k8s)
  self.__delete(k8s)
  self.cf4k8s.delete(k8s)
  if self.cc_db:
    self.cc_db.delete(k8s)
