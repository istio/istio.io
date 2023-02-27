---
---
## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. [Install the Helm client](https://helm.sh/docs/intro/install/), version 3.6 or above.

1. Configure the Helm repository:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
