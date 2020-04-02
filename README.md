# SAP flavoured cf-for-k8s shalm chart

Install a SAP flavoured cf-for-k8s using shalm.

## Installation


1. [Install shalm](https://github.com/kramerul/shalm/blob/master/doc/installation.md)
1. Create a file `/tmp/docker-registry.yaml`, which describes the docker registry, you are using
   ```yaml
   username: _json_key
   password: <gcp-service-account>
   repository: gcr.io/.../cf-workloads
   ```
1. Find out the domain (e.g. from your gardener shoot by prefixing it with `cf.ingress` )
1. Set your `KUBECONFIG` environment variable accordingly
1. Install cf-for-k8s-gardener

```bash
DOMAIN=<your domain>
shalm apply https://github.com/akhinos/cf-for-k8s-gardener/archive/stable.zip \
                   --set domain="${DOMAIN}" \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml \
                   -t kapp
```

You can also clone the repo https://github.com/akhinos/cf-for-k8s-gardener, checkout the `stable` branch and use the following command for installation:

```
shalm apply cf-for-k8s-gardener \
                   --set domain="${DOMAIN}" \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml \
                   -t kapp
```

## Separate secrets for pull and push

If you would like to have separate secrets for pulling images, you have to create an additional file `/tmp/readonly-docker-registry.yaml`

   ```yaml
   username: _json_key
   password: <readonly-gcp-service-account>
   repository: gcr.io/.../cf-workloads
   ```

and pass this with the following flags to the installation

```
--set-yaml readonly_docker_registry=/tmp/readonly-docker-registry.yaml
```