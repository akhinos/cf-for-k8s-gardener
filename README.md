# SAP flavoured cf-for-k8s shalm chart

Install a SAP flavoured cf-for-k8s using shalm.

## Installation

1. Install shalm [prerequisites](https://github.com/kramerul/shalm/blob/master/README.md#prerequisite)
2. [Install shalm](https://github.com/kramerul/shalm/blob/master/README.md#install-binary)
3. Enter github.tools.sap token into `$HOME/.shalm/config` as described [here](https://github.com/kramerul/shalm/blob/master/README.md#download-credentials) (You can skip this step, if you clone this repo)
4. Put your pull and push secrets for your gcp docker registry into `/tmp/image_pull_secrets.json` and `/tmp/gcr-admin-credentials.json` respectively
5. Find out the domain (e.g. from your gardener shoot by prefixing it with `cf.ingress` )
6. Set your `KUBECONFIG` environment variable accordingly
7. Install cf-for-k8s

```bash
DOMAIN=<your domain>
shalm apply https://github.tools.sap/api/v3/repos/c21s/cf-for-k8s-sap/zipball/stable \
                   --set-file image_pull_secrets=/tmp/image_pull_secrets.json \
                   --set domain="${DOMAIN}" \
                   --set-yaml gcp_service_account=/tmp/gcr-admin-credentials.json \
                   -t kapp
```

You can also clone the repo https://github.tools.sap/c21s/cf-for-k8s-sap, **checkout the `stable` branch** and use

```
shalm apply cf-for-k8s-sap \
                   --set-file image_pull_secrets=/tmp/image_pull_secrets.json \
                   --set domain="${DOMAIN}" \
                   --set-yaml gcp_service_account=/tmp/gcr-admin-credentials.json \
                   -t kapp
```
