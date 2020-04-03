# SAP flavoured cf-for-k8s shalm chart

Install a SAP flavoured cf-for-k8s using shalm.

## Installation


1. [Install shalm](https://github.com/kramerul/shalm/blob/master/doc/installation.md)
2. Enter github.tools.sap token into `$HOME/.shalm/config` as described [here](https://github.com/kramerul/shalm/blob/master/doc/repos.md#download-credentials). You can skip this step if you clone this repository.
3. Create a file `/tmp/docker-registry.yaml`, which describes the docker registry, you are using
   ```yaml
   username: _json_key
   password: <gcp-service-account>
   repository: gcr.io/sap-se-gcp-istio-dev/cf-workloads
   ```
4. Find out the domain (e.g. from your gardener shoot by prefixing it with `cf.ingress` )
5. Set your `KUBECONFIG` environment variable accordingly
6. Install cf-for-k8s-sap

```bash
DOMAIN=<your domain>
shalm apply https://github.tools.sap/api/v3/repos/c21s/cf-for-k8s-sap/zipball/stable \
                   --set domain="${DOMAIN}" \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml \
                   -t kapp
```

You can also clone the repo https://github.tools.sap/c21s/cf-for-k8s-sap, checkout the `stable` branch and use the following command for installation:

```
shalm apply cf-for-k8s-sap \
                   --set domain="${DOMAIN}" \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml \
                   -t kapp
```

## Separate secrets for pull and push

If you would like to have separate secrets for pulling images, you have to create an additional file `/tmp/readonly-docker-registry.yaml`

   ```yaml
   username: _json_key
   password: <readonly-gcp-service-account>
   repository: gcr.io/sap-se-gcp-istio-dev/cf-workloads
   ```

and pass this with the following flags to the installation

```
--set-yaml readonly_docker_registry=/tmp/readonly-docker-registry.yaml
```