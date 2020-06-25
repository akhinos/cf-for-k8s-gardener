# Testing external databases


See [Slack](https://cloudfoundry.slack.com/archives/CH9LF6V1P/p1591210825480300)

## Purpose

The purpose of this document is to describe how continous integration tests can be used to ensure that cf-for-k8s can be installed in combination with an external database.

## Database Test Cases


| Test-Case/Cluster-Type                     | Kind            | GKE Cluster    |
|--------------------------------------------|-----------------|----------------|
| Install with Local DB                      | Already exists? | Already exists |
| Install with External DB (in same cluster) | Not required    | Required<sup>(1)<sup>       |
| Install with External DB (outside cluster) | Not required    | Required       |
| Upgrade with External DB                   | Not required    | Out of scope   |

As you can see in the table above, currently two tests are missing for the combination of GKE Cluster with an external database. The type of database to use is discussed in the next section.

(1) This test should ensure that network problems are detected correctly.

## External database options

* **GCP:** Create external GCP database using [terraform](https://github.com/cloudfoundry/cf-for-k8s/tree/master/deploy/gke/terraform) to create 
* **AWS:** Create external AWS database using terraform
* **Zalando:** Setup External database within the same cluster with [Zalando Postgres Operator](https://github.com/zalando/postgres-operator)
* **Bitnami:** Setup External database within the same cluster with bitnami chart from cf-for-k8s/build/postgres/_vendir/bitnami/postgresql

| Goal                                            | GCP                | AWS                | Zalando            | Bitnami            |
|-------------------------------------------------|--------------------|--------------------|--------------------|--------------------|
| Test external Network                           | :white_check_mark: | :white_check_mark: | :x:                | :x:                |
| Accessible from outside                         | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                |
| TLS (Connect securely)                          | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                |
| Creation time/Deletion time                     | ?                  | 7 min/7 min        | ?                  | ?                  |
| Stays up whilst cf-for-k8s or the cluster rolls | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Test communication between cloud providers      | :x:                | :white_check_mark: | :x:                | :x:                |

It seems that the creation of external databases might take quite long. Perhaps this could run in parallel with the creation of the cluster.

## Test frequency

Tests could be run in two modes:

* **Nightly:** Tests are running each night on a fixed branch (develop)
* **PR:** Tests are running for each PR


**PR** would be preferred if testing time is less than 30 minutes. Otherwise we should switch to **Nightly** builds.

## Testing matrix

Currently, there seems to be no support in Concourse for testing matrices. If testing matrix is required, it must be implemented manually.


## Open questions

* Are Credentials for GCP and AWS are provided by VMWare inside Concourse?
* Should tests run in newly created clusters/ databases? Currently, test for cf-for-k8s are [reusing the existing cluster](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s?group=infrastructure). Clusters are only created manually (without triggers).