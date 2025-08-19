---
---
## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/application-requirements/).

1. [Install the latest Helm client](https://helm.sh/docs/intro/install/). Helm versions released before the [oldest currently-supported Istio release](docs/releases/supported-releases/#support-status-of-istio-releases) are not tested, supported, or recommended.

1. Configure the Helm repository:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
