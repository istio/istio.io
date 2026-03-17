---
---
## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/application-requirements/).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above. Helm 4 is also supported. Helm versions released before the [oldest currently-supported Istio release](/docs/releases/supported-releases/#support-status-of-istio-releases) are not tested, supported, or recommended.

1. Configure the Helm repository:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
