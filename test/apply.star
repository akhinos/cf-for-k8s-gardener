
c = chart("../")

def setup():
    k8s.apply({
        "kind": "service",
        "metadata" : { "name": "kubernetes", "namespace" : "default"},
        "spec": { "clusterIP" : "100.0.0.1" },
    })
    # This is only needed due to a bug in shalm
    k8s.apply({
        "kind": "deployments.apps",
        "metadata" : { "name": "capi-kpack-watcher", "namespace" : "cf-system"},
        "spec": { "template" : { "metadata" : {} } },
    })
    c.apply(k8s)

def tear_down():
    c.delete(k8s)


def test_kpack():
    kpack_watcher = k8s.get("deployments.apps","capi-kpack-watcher",namespace="cf-system")
    assert.eq(kpack_watcher.spec.template.metadata.annotations['traffic.sidecar.istio.io/excludeOutboundIPRanges'],"100.0.0.1/32")

def test_ingress():
    ingress = k8s.get("service","istio-ingressgateway",namespace="istio-system")
    assert.eq(ingress.metadata.annotations['dns.gardener.cloud/dnsnames'],"cf.local,*.cf.local,*.authentication.cf.local,*.xsuaa-api.cf.local,*.cpp.cf.local,*.cockpit.cf.local,operator.operationsconsole.cf.local")


setup()
test_kpack()
test_ingress()
tear_down()