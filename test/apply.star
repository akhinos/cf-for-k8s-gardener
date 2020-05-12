
load("@ytt:yaml", "yaml")

c = chart("../", default_identity_provider="myProvider")

def setup():
    k8s.apply({
        "kind": "service",
        "metadata" : { "name": "kubernetes", "namespace" : "default"},
        "spec": { "clusterIP" : "100.0.0.1" },
    })
    # This is only needed due to a bug in shalm
    k8s.apply({
        "kind": "deployments.apps",
        "metadata" : { "name": "cf-api-kpack-watcher", "namespace" : "cf-system"},
        "spec": { "template" : { "metadata" : {} } },
    })
    c.apply(k8s)

def tear_down():
    c.delete(k8s)


def test_kpack():
    kpack_watcher = k8s.get("deployments.apps","cf-api-kpack-watcher",namespace="cf-system")
    assert.eq(kpack_watcher.spec.template.metadata.annotations['traffic.sidecar.istio.io/excludeOutboundIPRanges'],"100.0.0.1/32")

def test_ingress():
    ingress = k8s.get("service","istio-ingressgateway",namespace="istio-system")
    assert.eq(ingress.metadata.annotations['dns.gardener.cloud/dnsnames'],"cf.local,*.cf.local,*.authentication.cf.local,*.xsuaa-api.cf.local,*.cpp.cf.local,*.cockpit.cf.local,operator.operationsconsole.cf.local")

def test_default_identity_provider():
    cm =  k8s.get("configmap","uaa-config",namespace="cf-system")
    uaa_config = yaml.decode(cm.data["uaa.yml"])
    print(uaa_config.keys())
    assert.eq(uaa_config["login"]["defaultIdentityProvider"],"myProvider")

setup()
test_kpack()
test_ingress()
test_default_identity_provider()
tear_down()