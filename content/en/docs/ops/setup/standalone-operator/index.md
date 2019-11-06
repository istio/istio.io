---
title: Standalone Operator Install [Experimental]
description: Instructions to install Istio in a Kubernetes cluster using the Istio operator.
weight: 11
keywords: [kubernetes, operator]
aliases:
---

This guide installs Istio using the standalone Istio
[operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
The only dependencies required are a supported Kubernetes cluster and the `kubectl` command.

{{< warning >}}
To install Istio for production use, we recommend [installing with {{< istioctl >}}](/docs/setup/install/istioctl/)
instead, which is a stable feature.
{{< /warning >}}

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/).

## Install

To install the Istio `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/)
using the operator, run the following command:

{{< text bash >}}
$ kubectl apply -f https://preliminary.istio.io/operator.yaml
{{< /text >}}

This command deploys the operator controller and applies an `IstioControlPlane` custom resource
that selects the Istio `demo` profile.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
{{< /text >}}

The controller, once initialized, will detect the
`IstioControlPlane` resource and then install the Istio components corresponding
to the specified (`demo`) configuration.

Now that the controller is running, you can change the Istio configuration by editing or replacing
the `IstioControlPlane` resource. For example, you can switch the installation to the `default`
profile with the following command:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

You can also enable or disable specific features or components.
For example, to disable the telemetry feature change:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
  telemetry:
    enabled: false
EOF
{{< /text >}}

Refer to the [`IstioControlPlane` API](/docs/reference/config/istio.operator.v1alpha12.pb/)
for the complete set of configuration options.

## Uninstall

Delete the Istio operator and Istio deployment:

{{< text bash >}}
$ kubectl -n istio-operator get IstioControlPlane example-istiocontrolplane -o=json | jq '.metadata.finalizers = null' | kubectl delete -f -
$ kubectl delete ns istio-operator --grace-period=0 --force
$ kubectl delete ns istio-system --grace-period=0 --force
{{< /text >}}
