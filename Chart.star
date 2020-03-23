def init(self,domain=None):
  self.cf4k8s = chart("https://github.com/kramerul/cf-for-k8s/archive/shalm.zip",domain=domain,gardener=True,namespace="default")
