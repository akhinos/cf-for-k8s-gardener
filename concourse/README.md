# Pipeline definition using python

## Prerequisites

```bash
cd ~/workspace
git clone git@github.com:kramerul/py-cicd
```

## Upload pipeline definition

```bash
./pipeline.py --concourse > test.yaml && fly -t concourse-sapcloud-garden set-pipeline -c  test.yaml -p "py-cicd"
```

## Run local test

```bash
./pipeline.py --job cf-for-k8s --task install
./pipeline.py --job cf-for-k8s --task upstream_tests
```