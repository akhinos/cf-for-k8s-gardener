def init(self,domain=None, docker_registry=None, readonly_docker_registry=None, 
         sub_domains = [ "", "*.","*.authentication.","*.xsuaa-api.","*.cpp.","*.cockpit.","operator.operationsconsole." ],
         certificate = None,
         db_chart_url = None,
         default_identity_provider=None, api_server_ip=None):
  self.__class__.name = "cf-for-k8s-gardener"

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry
  self.sub_domains = sub_domains
  self.certificate = certificate
  self.api_server_ip = api_server_ip
  if self.api_server_ip == None:
    self.api_server_ip = "100.64.0.1"
  self.default_identity_provider = default_identity_provider
  self.readonly_docker_registry = readonly_docker_registry
  self.cf4k8s = chart("https://github.com/akhinos/cf-for-k8s/archive/shalm.zip",
    domain=domain,
    overlays=[inject("overlays",self=self), inject("value-overlays",self=self)],
    namespace="cf-system",
    docker_registry=docker_registry)

  self.database = None
  if db_chart_url:
    self.database = chart(db_chart_url, namespace="c21s-db",ca=self.cf4k8s.ca)
    self.database.create_database("capi")
    self.database.create_database("uaa")

def kapp_controller_values(self):
  return str(self.ytt("kapp-controller/cf-values.yaml",self.cf4k8s.values(),inject("value-overlays/values.yaml",self=self)))

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
  k8s_service = k8s.get("service","kubernetes",namespace="default")
  self.api_server_ip = k8s_service.spec.clusterIP
  if self.database:
    self.database.apply(k8s)
    self.capi_db_credentials = self.database.credentials("capi",k8s)
    self.uaa_db_credentials = self.database.credentials("uaa",k8s)

  self._set_domain(k8s)
  self.cf4k8s.apply(k8s)
  self.__apply(k8s)

def delete(self,k8s):
  self._set_domain(k8s)
  self.__delete(k8s)
  self.cf4k8s.delete(k8s)
  if self.database:
    self.database.delete(k8s)
