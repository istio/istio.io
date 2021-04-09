---
---
## Prerequisites

1. [Download the Istio release](/docs/setup/getting-started/#download).

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. [Install a Helm client](https://helm.sh/docs/intro/install/) with a version higher than 3.1.1.

{{< warning >}}
Helm 2 is not supported for installing Istio.
{{< /warning >}}

The commands in this guide use the Helm charts that are included in the Istio release package located at `manifests/charts`.
