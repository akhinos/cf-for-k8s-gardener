# Testing external databases


This document is based on a [thread started in slack Slack](https://cloudfoundry.slack.com/archives/CH9LF6V1P/p1591210825480300)

## Purpose

The purpose of this document is to describe how continuous integration tests can be used to ensure that cf-for-k8s can be installed in combination with external databases.

## Database Test Cases


| Test-Case/Cluster-Type                     | Kind            | GKE Cluster           | Azure Cluster  |
|--------------------------------------------|-----------------|-----------------------|----------------|
| Install with Local DB                      | Already exists? | Already exists        | Already exists |
| Install with External DB (in same cluster) | Not required    | Required<sup>(1)<sup> | Out of scope   |
| Install with External DB (outside cluster) | Not required    | Required<sup>(1)<sup> | Out of scope   |
| Upgrade with External DB                   | Not required    | Out of scope          | Out of scope   |

(1) It makes sense to test both variants, because internal cluster communication and internet communication could react differently to networking changes (e.g. istio egress configuration changes).

As you can see in the table above, currently two tests are missing for the combination of GKE Cluster with an external database. The type of database to use is discussed in the next section.

## External database options

* **GCP:** Create external GCP database using [terraform](https://github.com/cloudfoundry/cf-for-k8s/tree/master/deploy/gke/terraform) to create 
* **AWS:** Create external AWS database using terraform
* **Zalando:** Setup External database within the same cluster with [Zalando Postgres Operator](https://github.com/zalando/postgres-operator)
* **Bitnami:** Setup External database within the same cluster with [bitnami chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql)
* **Bitnami HA:** Setup External database within the same cluster with [bitnami HA chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql-ha/)

| Goal                                            | GCP                | AWS                | Zalando            | Bitnami            | Bitnami HA         |
|-------------------------------------------------|--------------------|--------------------|--------------------|--------------------|--------------------|
| Test external Network                           | :white_check_mark: | :white_check_mark: | :x:                | :x:                | :x:                |
| Accessible from outside  (over ingress)         | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                | :white_check_mark: |
| TLS (Connect securely)                          | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                | :white_check_mark: |
| Stays up whilst cf-for-k8s or the cluster rolls | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Test communication between cloud providers      | :x:                | :white_check_mark: | :x:                | :x:                | :x:                |

To cover most variants,
* **AWS** should be used to test external databases
* **Zalando** or **Bitnami HA** should be used to test external databases located in the same kubernetes cluster

## Test times

The following times are looked up in concourse or measured by hand to get an estimation of the duration of external database tests:

| Group                            | Action                                                                                                                                     | Time (min) |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|------------|
| RDS Database Server              | Create external RDS database on AWS                                                                                                        | 7.0        |
|                                  | Destroy external RDS database on AWS                                                                                                       | 7.0        |
| Cluster internal Database Server | Install Zalado postgres-operator                                                                                                           | 0.1        |
|                                  | Create database server                                                                                                                     | 2.0        |
|                                  | Destroy database server                                                                                                                    | 0.1        |
| Database                         | `CREATE DATABASE` on postgresql                                                                                                            | 0.1        |
|                                  | `DROP DATABASE` on postgresql                                                                                                              | 0.1        |
| k8s Cluster                      | Create GKE cluster using terraform                                                                                                         | 6.0        |
|                                  | Destroy GKE cluster using terraform                                                                                                        | 2.5        |
|                                  | Create AWS cluster using gardener                                                                                                          | 6.5        |
| cf-for-k8s                       | Install                                                                                                                                    | 5.5        |
|                                  | Uninstall                                                                                                                                  | 1.0        |
| Tests                            | Run cf-for-k8s unit test                                                                                                                   | 1.0        |
|                                  | Push test app                                                                                                                              | 1.0        |
|                                  | [validate-cf-for-k8s-pr](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s/jobs/validate-cf-for-k8s-pr/builds/165) | 17.0       |


## Test frequency

Tests could be run in two modes:

* **Nightly:** Tests are running each night on a fixed branch (develop)
* **PR:** Tests are running for each PR


**PR** would be preferred if testing time is less than 30 minutes. Otherwise we should switch to **Nightly** builds.

With the times from the section above an external database test will need

| Action                          | Time (min) |
|---------------------------------|------------|
| validate-cf-for-k8s-pr          | 17.0       |
| `CREATE DATABASE` on postgresql | 0.1        |
| `DROP DATABASE` on postgresql   | 0.1        |
| **Overall time**                | 17.2       |

if the external database servers are created upfront and are reused for different tests, with different databases. 

Using a new RDS instance for each test would add a 14 minutes extra. The creation of the RDS could be run in parallel to the creation of the k8s cluster. This will save time but will cost additional effort.

Using a cluster internal external database will add 2 minutes extra:

| Action                           | Time (min) |
|----------------------------------|------------|
| validate-cf-for-k8s-pr           | 17.0       |
| `CREATE DATABASE` on postgresql  | 0.1        |
| `DROP DATABASE` on postgresql    | 0.1        |
| Install Zalado postgres-operator | 0.1        |
| Create database server           | 2.0        |
| Destroy database server          | 0.1        |
| **Overall time**                 | 19.4       |

## Testing matrix

The existing test already cover the following dimensions:
* k8s version (newest, oldest)
* Cloud Provider (GKE, Azure)

Adding external database tests will add an additional dimension.

Therefore, it would be nice to have some support for this in Concourse. Unfortunately, Concourse doesn't support test martrices.

An alternative might be to use ytt to render the pipeline. This would allow the reuse of fragments for different test dimensions.

## Component tests for capi and uaa

* There are already [integration tests for uaa](https://github.com/cloudfoundry/uaa/blob/develop/run-integration-tests.sh) which cover different databases.

* The [cloud controller unit tests](https://github.com/cloudfoundry/cloud_controller_ng#unit-tests) are already using external databases.

It seems that no other database tests are required on component level.

## Proposal

Tests for external databases will be added
* they will run on **PR** base
* they will test external database connection in two variants
  * external AWS RDS database
  * cluster internal postgresql database created with [postgres-operator](https://github.com/zalando/postgres-operator)

The following jobs will be added/modified in Concourse
* in the [infrastructure group](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s?group=infrastructure) new jobs will be added to create and destroy an external database server (AWS RDS) using terraform
* the [validate-cf-for-k8s-pr job](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s/jobs/validate-cf-for-k8s-pr/builds/165) will be used as template to implement two additional jobs to execute the external database tests. To avoid copying code, ytt could be used to render the pipeline.


## Open questions

* Will AWS credentials be provided by VMWare inside Concourse?
* Could ytt be used to render the pipelines? The only drawback would be that yaml references need to be replaced by ytt functions.
