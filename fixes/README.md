# Fix for Cloud Controller

This directory is used to [add environment variables to kpack image](https://github.com/cloudfoundry/cloud_controller_ng/pull/1600). Additionally the `VCAP_SERVICES` variabble is renamed to `CNB_SERVICES`.

The patch file `0001-Add-environment-variables-to-kpack-image-CR.patch` is create with

```
git clone git@github.com:akhinos/cloud_controller_ng.git
cd cloud_controller_ng
git format-patch -M master..cnb_services
```
