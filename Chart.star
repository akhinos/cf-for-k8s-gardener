def init(self,domain=None):
  self.cf4k8s = chart("https://github.com/kramerul/cf-for-k8s/archive/shalm.zip",domain=domain,gardener=True)

# https://github.com/<org>/<repo>/archive/<branch>.zip
 
# shalm apply https://github.com/kramerul/cf-for-k8s/archive/shalm.zip --set domain=cf.ingress.....
 
# shalm apply . --set domain=cf.ingress.....
 
# shalm apply https://github.com/<org>/<repo>/archive/<branch>.zip --set domain=cf.ingress.....