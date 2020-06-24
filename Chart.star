
shalm_certificate = certificate

default_domain = "example.com"
def init(self,domain=default_domain, docker_registry=None, readonly_docker_registry=None, 
         sub_domains = [ "", "*.","*.authentication.","*.xsuaa-api.","*.cpp.","*.cockpit.","operator.operationsconsole." ],
         certificate = None,
         default_identity_provider=None, api_server_ip=None):

  self.__class__.name = "cf-for-k8s"
  self.domain = domain
  self.app_domains= None
  self.docker_registry = docker_registry

  self.cf_admin_password = user_credential("cf-admin-password-shalm",username="admin")
  self.secret_key = user_credential("secret-key-shalm",username="admin")
  self.cf_db_admin_password = user_credential("cf-db-admin-password-shalm",username="admin")
  self.capi_database_password = user_credential("capi-database-password-shalm",username="admin")
  self.ca = shalm_certificate("ca-shalm",is_ca=True,domains=["cf-root-ca.local"])
  self.system_certificate = shalm_certificate("system-certificate-shalm",signer=self.ca,domains=["*.cf-system.svc.cluster.local" ])
  self.log_cache_ca = shalm_certificate("log-cache-ca-shalm",is_ca=True)
  self.log_cache = shalm_certificate("log-cache-shalm",signer=self.log_cache_ca,domains=["log-cache"])
  self.log_cache_metrics = shalm_certificate("log-cache-metrics-shalm",signer=self.log_cache_ca,domains=["log-cache-metrics"])
  self.log_cache_gateway = shalm_certificate("log-cache-gateway-shalm",signer=self.log_cache_ca,domains=["log-cache-gateway","localhost"])
  self.log_cache_syslog = shalm_certificate("log-cache-syslog-shalm",signer=self.log_cache_ca,domains=["log-cache-syslog"])
  self.metric_proxy_ca = shalm_certificate("metrics-proxy-ca-shalm",is_ca=True)
  self.metric_proxy = shalm_certificate("metrics-proxy-shalm",signer=self.metric_proxy_ca,domains=["metric-proxy"])

  # Not really required
  self.workloads_certificate = shalm_certificate("workloads-certificate-shalm",signer=self.ca,domains=["*.apps.test.local"])
  self.internal_certificate = shalm_certificate("internal-certificate-shalm",signer=self.ca,domains=["*.cf-system.svc.cluster.local"])

  self.uaa_db_password= user_credential("uaa-db-password-shalm",username="admin")
  self.uaa_admin_client_secret= user_credential("uaa-admin-client-secret-shalm",username="admin")
  self.uaa_jwt_policy_signing_key = shalm_certificate("uaa-jwt-policy-signing-key-shalm",signer=self.ca,domains=["uaa-jwt-policy-signing-key"])
  self.uaa_login_service_provider = shalm_certificate("uaa-login-service-provider-shalm",signer=self.ca,domains=["uaa-login-service-provider"])
  self.uaa_encryption_key_passphrase= user_credential("uaa-encryption-key-passphrase-shalm",username="admin")
  self.docker_registry_http_secret= user_credential("docker-registry-http-secret-shalm",username="admin")

  if not readonly_docker_registry:
    readonly_docker_registry = docker_registry
  self.sub_domains = sub_domains
  self.certificate = certificate
  self.api_server_ip = api_server_ip
  if self.api_server_ip == None:
    self.api_server_ip = "100.64.0.1"
  self.default_identity_provider = default_identity_provider
  self.readonly_docker_registry = readonly_docker_registry

def kapp_controller_values(self):
  return str(self.ytt(inject("shalm2ytt",self=self),"kapp-controller"))

def _set_domain(self,k8s):
  if not self.domain == default_domain:
    self.domain = "cf." + k8s.host.partition('.')[2]
  self.app_domains= [ self.domain ]

def template(self,glob=""):
  return self.ytt( inject("shalm2ytt",self=self), "overlays", inject("kubecf-compatibility",self=self) )

def apply(self,k8s):
  self._set_domain(k8s)
  k8s_service = k8s.get("service","kubernetes",namespace="default")
  self.api_server_ip = k8s_service.spec.clusterIP
  k8s.tool = "kapp"
  self.__apply(k8s)

def delete(self,k8s):
  self._set_domain(k8s)
  k8s.tool = "kapp"
  self.__delete(k8s)

def credentials(self):
  return struct(username=self.cf_admin_password.username, password=self.cf_admin_password.password,url="https://api." + self.domain)

def uaa_credentials(self):
  return struct(url="https://uaa." + self.domain,client_secret=self.uaa_admin_client_secret.password, client_id=self.uaa_admin_client_secret.username)
