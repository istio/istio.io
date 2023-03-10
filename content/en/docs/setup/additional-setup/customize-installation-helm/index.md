---
title: Advanced Helm Chart Customization
description: Describes how to customize installation configuration options when installing with helm.
weight: 55
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/getting-started/#download).
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).
1. [Usage of helm for Istio installation](/docs/setup/install/helm).
1. Helm version that supports post rendering. (>= 3.1)
1. kubectl or kustomize.

## Advanced Helm Chart Customization

Istio's helm chart tries to incorporate most of the attributes needed by users for their specific requirements. However, it does not
contain every possible Kubernetes value you may want to tweak. While it is not practical to have such a mechanism in place, in this
document we will demonstrate a method which would allow you to do some advanced helm chart customization without the need to directly
modify Istio's helm chart.

### Using Helm with kustomize to post-render Istio charts

Using the Helm `post-renderer` capability, you can tweak the installation manifests to meet your requirements easily.
`Post-rendering` gives the flexibility to manipulate, configure, and/or validate rendered manifests before they are installed by Helm.
This enables users with advanced configuration needs to use tools like Kustomize to apply configuration changes without the need
for any additional support from the original chart maintainers.

### Adding a value to an already existing chart

In this example, we will add a `sysctl` value to Istio’s `ingress-gateway` deployment. We are going to:

1. Create a `sysctl` deployment customization patch template.
1. Apply the patch using Helm `post-rendering`.
1. Verify that the `sysctl` patch was correctly applied to the pods.

## Create the Kustomization

First, we create a `sysctl` patch file, adding a `securityContext` to the `ingress-gateway` pod with the additional attribute:

{{< text bash >}}
$ cat > sysctl-ingress-gw-customization.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    spec:
      securityContext:
          sysctls:
          - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
            value: "10"
EOF
{{< /text >}}

The below shell script helps to bridge the gap between Helm `post-renderer` and Kustomize, as the former works with `stdin/stdout`
and the latter works with files.

{{< text bash >}}
$ cat > kustomize.sh <<EOF
#!/bin/sh
cat > base.yaml
exec kubectl kustomize # you can also use "kustomize build ." if you have it installed.
EOF
$ chmod +x ./kustomize.sh
{{< /text >}}

Finally, let us create the `kustomization` yaml file, which is the input for `kustomize`
with the set of resources and associated customization details.

{{< text bash >}}
$ cat > kustomization.yaml <<EOF
resources:
- base.yaml
patchesStrategicMerge:
- sysctl-ingress-gw-customization.yaml
EOF
{{< /text >}}

## Apply the Kustomization

Now that the Kustomization file is ready, let us use Helm to make sure this gets applied properly.

### Add the Helm repository for Istio

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

### Render and Verify using Helm Template

We can use Helm `post-renderer` to validate rendered manifests before they are installed by Helm

{{< text bash >}}
$ helm template istio-ingress istio/gateway --namespace istio-ingress --post-renderer ./kustomize.sh | grep -B 2 -A 1 netfilter.nf_conntrack_tcp_timeout_close_wait
{{< /text >}}

In the output, check for the newly added `sysctl` attribute for `ingress-gateway` pod:

{{< text yaml >}}
    securityContext:
      sysctls:
      - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
        value: "10"
{{< /text >}}

### Apply the patch using Helm `Post-Renderer`

Use the below command to install an Istio ingress-gateway, applying our customization using Helm `post-renderer`:

{{< text bash >}}
$ kubectl create ns istio-ingress
$ helm upgrade -i istio-ingress istio/gateway --namespace istio-ingress --wait --post-renderer ./kustomize.sh
{{< /text >}}

## Verify the Kustomization

Examine the ingress-gateway deployment, you will see the newly manipulated `sysctl` value:

{{< text bash >}}
$ kubectl -n istio-ingress get deployment istio-ingress -o yaml
{{< /text >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  …
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    metadata:
      …
    spec:
      securityContext:
        sysctls:
        - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
          value: "10"
{{< /text >}}

## Additional Information

For further detailed information about the concepts and techniques described in this document, please refer to:

1. [IstioOperator - Customize Installation](/docs/setup/additional-setup/customize-installation)
1. [Advanced Helm Techniques](https://helm.sh/docs/topics/advanced/)
1. [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
