# [Gardener](https://gardener.cloud/) flavoured cf-for-k8s shalm chart

Install a [gardener](https://gardener.cloud/) flavoured cf-for-k8s using shalm.

## Installation


1. [Install shalm](https://github.com/wonderix/shalm/blob/master/doc/installation.md)
1. Create a file `/tmp/docker-registry.yaml`, which describes the docker registry, you are using
   ```yaml
   username: _json_key
   password: <gcp-service-account>
   repository: gcr.io/.../cf-workloads
   ```
1. Set your `KUBECONFIG` environment variable accordingly
1. Install cf-for-k8s-gardener

```bash
shalm apply https://github.com/akhinos/cf-for-k8s-gardener/archive/stable.zip \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml
```

You can also clone the repo https://github.com/akhinos/cf-for-k8s-gardener, checkout the `stable` branch and use the following command for installation:

```
shalm apply cf-for-k8s-gardener \
                   --set-yaml docker_registry=/tmp/docker-registry.yaml \
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

## Ease the creation of `docker-registry.yaml` for a google cloud based repository

```bash
export GCR_ADMIN_CREDENTIALS=..
export PRIVATE_HUB=gcr.io/...
jq -n --arg username _json_key \
      --arg password "$GCR_ADMIN_CREDENTIALS" \
      --arg repository $PRIVATE_HUB/cf-workloads \
      '{"username":$username, "password":$password, "repository":$repository}' \
      > /tmp/docker-registry.json
```