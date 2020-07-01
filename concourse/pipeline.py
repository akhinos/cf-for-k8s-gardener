#!/usr/bin/env python3
import sys
import os
import json
sys.path.append(os.getenv("HOME") + "/workspace/py-cicd")
from concourse import *
import hvac
import kubernetes 
import yaml
import requests
import time
from cron import Cron

def shoot_kubeconfig(name):
    return ShootManager().get(name).kubeconfig()

def write_json(filename,data):
    with open(filename,'w') as f:
        f.write(json.dumps(data))

with Pipeline("py-cicd",image_resource={"type": "docker-image","source": {"repository": "gcr.io/sap-se-gcp-istio-dev/ci-image","tag": "latest", "username" : "_json_key","password":"((IMAGE_PULL_SECRETS))"}}) as pipeline:
    pipeline.path_append(os.getenv("HOME") + "/workspace/c21s/bin")
    from shoot import ShootManager
    pipeline.resource("7:00", Cron("0 0 7 * * 1-5"))
    pipeline.resource("cf-for-k8s-gardener", GitRepo("https://github.com/akhinos/cf-for-k8s-gardener"))
    pipeline.resource("cf-for-k8s", GitRepo("https://github.com/akhinos/cf-for-k8s"))
    pipeline.resource("product-sapcf-compliance",GitRepo("https://github.tools.sap/c21s/product-sapcf-compliance",username="istio-serviceuser",password="((GITHUB_TOOLS_SAP_TOKEN))"))

    with pipeline.job("cf-for-k8s") as job:
        cf_for_k8s_gardener = job.get("cf-for-k8s-gardener",trigger=False)
        job.get("7:00",trigger=True)
        shoot = "uli"
        certificate_secret = "CERTIFICATE_" + shoot.upper()


        @job.task( secrets={"gardener_kubeconfig_content": "GARDENER_KUBECONFIG_CONTENT","gcr_admin_credentials" : "GCR_ADMIN_CREDENTIALS", "image_pull_secrets" : "IMAGE_PULL_SECRETS", 
                "certificate" : OptionalSecret(certificate_secret),"vault_role_id" : OptionalSecret("VAULT_ROLE_ID") , "vault_secret_id" : OptionalSecret("VAULT_SECRET_ID") },timeout="30m")
        def install(gardener_kubeconfig_content, gcr_admin_credentials, image_pull_secrets, vault_role_id=None, vault_secret_id=None, certificate=None):
            kubeconfig = shoot_kubeconfig(shoot)
            CHART_URL="${1:-cf-for-k8s-gardener}"

            write_json("/tmp/docker_registry.json",{ "username":"_json_key", "password":gcr_admin_credentials, "repository":"gcr.io/sap-se-gcp-istio-dev/cf-workloads"})
            write_json("/tmp/readonly_docker_registry.json",{ "username":"_json_key", "password":image_pull_secrets, "repository":"gcr.io/sap-se-gcp-istio-dev/cf-workloads"})
            args = []
            if certificate and len(certificate) > 3:
                with open("/tmp/certificate.json",'w') as f:
                    f.write(certificate)
                args = args + [ "--set-yaml", "certificate=/tmp/certificate.json"]
            
            os.environ['KUBECONFIG'] = kubeconfig.file()
            shell(['shalm' ,'apply' ,cf_for_k8s_gardener ,
                '--set-yaml' ,'docker_registry=/tmp/docker_registry.json' ,
                '--set-yaml' ,'readonly_docker_registry=/tmp/readonly_docker_registry.json' ,
                '-n' ,'cf-system'] + args)
 
            if vault_role_id:
                kubeconfig.load()
                core = kubernetes.client.CoreV1Api(kubernetes.client.ApiClient())
                secret = core.read_namespaced_secret("cf-4-k8s-ingressgateway-certs", "istio-system")
                certificate = { "ca.crt": secret.data["ca.crt"], "tls.crt": secret.data["tls.crt"], "tls.key": secret.data["tls.key"], "certificate-hash": secret.metadata.labels["cert.gardener.cloud/certificate-hash"] }
                vault = hvac.Client(url='https://vault.tools.sap',verify=False,namespace='scp/teams/cki')
                vault.auth_approle(vault_role_id, vault_secret_id)
                vault.write('/concourse/garden/' + certificate_secret,value=json.dumps(certificate))


        cf_for_k8s = job.get("cf-for-k8s",trigger=False)

        @job.task(secrets={"gardener_kubeconfig_content": "GARDENER_KUBECONFIG_CONTENT"},timeout="30m")
        def upstream_tests(gardener_kubeconfig_content):
            kubeconfig = shoot_kubeconfig(shoot)
            kubeconfig.load()
            core = kubernetes.client.CoreV1Api(kubernetes.client.ApiClient())
            uaa_config = yaml.full_load(core.read_namespaced_config_map("uaa-config-ver-1", "cf-system").data["uaa.yml"])
            password = uaa_config['scim']['users'][0].split("|")[1]
            domain="cf." + shoot + ".istio.shoot.canary.k8s-hana.ondemand.com"
            api_endpoint = "https://api." + domain
            while True:
                try:
                    r = requests.get(api_endpoint)
                    break
                except Exception as exc:
                    print(exc)
                    print("Load balancer not ready, waiting a bit...")
                    time.sleep(10.0)
            os.environ['SMOKE_TEST_API_ENDPOINT'] = api_endpoint
            os.environ['SMOKE_TEST_USERNAME'] = "admin"
            os.environ['SMOKE_TEST_PASSWORD'] = password
            os.environ['SMOKE_TEST_APPS_DOMAIN'] = domain
            print("Running tests against " + api_endpoint)
            shell(["go","test","-v","."],cwd=os.path.join(cf_for_k8s,"tests/smoke"))

        product_sapcf_compliance = job.get("product-sapcf-compliance",trigger=False)

        @job.task(secrets={"gardener_kubeconfig_content": "GARDENER_KUBECONFIG_CONTENT"},timeout="30m")
        def compliance_test(gardener_kubeconfig_content):
            print(product_sapcf_compliance)