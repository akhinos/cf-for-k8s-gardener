# Fix for Cloud Controller

This directory is used to rename the `VCAP_SERVICES` variable to `CNB_SERVICES`.

The patch file `0001-Add-environment-variables-to-kpack-image-CR.patch` is create with

```
git clone git@github.com:akhinos/cloud_controller_ng.git
cd cloud_controller_ng
git format-patch -M cnb_services^..cnb_services
```
