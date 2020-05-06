FROM cloudfoundry/cloud-controller-ng:d1cf638f6b7bf5038073c51b8661e68aede859b0@sha256:f5bda8e6e15bf84d6bcc4baf820ffc19cf85c1cff5409c2fd549af9d20a3fccd

WORKDIR /cloud_controller_ng

COPY 0001-Add-environment-variables-to-kpack-image-CR.patch /cloud_controller_ng/
RUN patch -i 0001-Add-environment-variables-to-kpack-image-CR.patch --strip=1

COPY 0001-Ignore-updates-of-buildpack-e.g.-second-cf-push.patch /cloud_controller_ng/
RUN patch -i 0001-Ignore-updates-of-buildpack-e.g.-second-cf-push.patch --strip=1


