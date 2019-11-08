---
title: Introducing the Istio Operator
description: Introduction to Istio's new operator-based installation and control plane management feature.
publishdate: 2019-11-12
subtitle:
attribution: Martin Ostrowski (Google), Frank Budinsky (IBM)
keywords: [install,configuration,istioctl,operator]
target_release: 1.4
---

Kubernetes [operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) provide
a pattern for encoding human operations knowledge in software and are a popular way to simplify
the administration of software infrastructure components.
Because Istio is complex to administer, it's a natural candidate for an operator.

Up until now, [Helm](https://github.com/helm/helm) has been the primary tool to install and upgrade Istio.
This approach worked well but had some disadvantages:

1. Users need to install another tool.
1. Supporting Istio's many small specializations cause Helm templates to become unwieldy.
1. Helm configurations are difficult to validate using Istio's proto-based APIs.
1. Upgrades sometimes require Istio specific hooks that have been difficult to implement and maintain with Helm.

Starting with Istio 1.4, the [Helm installation](/docs/setup/install/helm/) approach has been deprecated
in favor of a new [installation using {{< istioctl >}}](/docs/setup/install/istioctl/) approach.
Upgrading from Istio 1.4 onward (that is, versions not initially installed with Helm)
will also be done using a new [{{< istioctl >}} upgrade feature](/docs/setup/upgrade/istioctl-upgrade/).

The new `istioctl` commands use a
[Custom Resource Definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
to configure the installation.
The CRD is part of a new Istio operator implementation intended to simplify the common administrative tasks of
installation, upgrade, and complex configuration changes for Istio.
Validation and checking for installation and upgrade is tightly integrated with the tools to prevent
common errors and simplify troubleshooting.

## Istio Control Plane API

Every operator implementation requires a
[custom resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
to define its API. Istio's operator API is defined by the
[`IstioControlPlane` CRD](/docs/reference/config/istio.operator.v1alpha12.pb/),
which is generated from
[this proto](https://github.com/istio/operator/blob/release-1.4/pkg/apis/istio/v1alpha2/istiocontrolplane_types.proto).
The API supports all of Istio's current [configuration profiles](/docs/setup/additional-setup/config-profiles/)
using a single field to select the profile. For example, the following `IstioControlPlane` resource
configures Istio using the `demo` profile:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
{{< /text >}}

You can then customize the configuration with additional settings. For example, to disable telemetry:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
  telemetry:
    enabled: false
{{< /text >}}

## Installing with {{< istioctl >}}

The recommended way to use the Istio operator API is through a new set of `istioctl` commands.
For example, to install Istio into a cluster:

{{< text bash >}}
$ istioctl manifest apply -f <your-istiocontrolplane-config>
{{< /text >}}

Make changes to the installation configuration by editing the configuration
file and calling `istioctl manifest apply` again.

To upgrade to a new version of Istio:

{{< text bash >}}
$ istioctl x upgrade -f <your-istiocontrolplane-config-changes>
{{< /text >}}

In addition to specifying the complete configuration in an `IstioControlPlane` resource,
the `istioctl` commands can also be passed individual settings using a `--set` flag:

{{< text bash >}}
$ istioctl manifest apply --set telemetry.enabled=false
{{< /text >}}

There are also a number of other `istioctl` commands that, for example,
help you list, display, and compare configuration profiles and manifests.

Refer to the Istio [install instructions](/docs/setup/install/istioctl) for more details.

## Istio Controller (alpha)

Operator implementations use a Kubernetes controller to continuously monitor their
API resource and apply the corresponding configuration changes.
In Istio's case, the controller monitors and reacts to changes in an
`IstioControlPlane` resource for a cluster by updating the Istio installation configuration.

In the 1.4 release, the Istio controller is in the alpha phase of development and not fully
integrated with `istioctl`. It is, however,
[available for experimentation](/docs/setup/install/standalone-operator/) using `kubectl` commands.
For example, to install the controller and a default version of Istio into your cluster,
run the following command:

{{< text bash >}}
$ kubectl apply -f https://<repo URL>/operator.yaml
$ kubectl apply -f https://<repo URL>/default-cr.yaml
{{< /text >}}

You can then make changes to the Istio installation configuration:

{{< text bash >}}
$ kubectl edit istiocontrolplane example-istiocontrolplane -n istio-system
{{< /text >}}

As soon as the resource is updated, the controller will detect the changes and respond by updating
the Istio installation correspondingly.

Both the operator controller and `istioctl` commands share the same code.
The main difference is the execution context.
In the `istioctl` case, the operation runs in the admin user’s command execution and
security context, while in the controller case, a pod in the cluster runs the code in its security context.
In both cases, they validate configuration schemas and perform the same range of checks for installation
change or upgrade.

## Migration from Helm

To help ease the transition from previous configurations using Helm,
`istioctl` and the controller support pass-through access for the full Helm installation API.

You can pass Helm configuration options using `istioctl --set` by prepending the string `values.` to the option name.
For example, instead of this Helm command:

{{< text bash >}}
$ helm template ... --set global.mtls.enabled=true
{{< /text >}}

You can use this `istioctl` command:

{{< text bash >}}
$ istioctl manifest generate ... --set values.global.mtls.enabled=true
{{< /text >}}

You can also set Helm configuration values in an `IstioControlPlane` configuration resource.
See [Customize Istio settings using Helm](/docs/setup/install/istioctl/#customize-istio-settings-using-the-helm-api)
for details.

Another feature to help with the transition from Helm is the alpha
[{{< istioctl >}} manifest migrate](/docs/reference/commands/istioctl/#istioctl-manifest-migrate) command.
This command can be used to automatically convert a Helm `values.yaml` file to a corresponding `IstioControlPlane`
configuration.

## Implementation

Several frameworks have been created to help implement operators by generating stubs
for some or all of the components. The Istio operator was created with the help of a combination of
[kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
and [operator framework](https://github.com/operator-framework),
but follows the Istio convention of using a proto to represent the API.

More information about the implementation can be found in the README and ARCHITECTURE documents
in the [Istio operator repository](https://github.com/istio/operator).

## Summary

Starting in Istio 1.4, Helm installation is being replaced by new `istioctl` commands using
a new operator custom resource definition, `IstioControlPlane`, for the configuration API.
An alpha controller is also available for early experimentation with the operator.

The new `istioctl` commands and operator controller both validate configuration schemas and perform a range of
checks for installation change or upgrade. These checks are tightly integrated with the tools to prevent
common errors and simplify troubleshooting.

Going forward, we hope that this new approach will improve the user experience during Istio installation
and upgrade, better stabilize the installation API, and help users better manage and monitor their
Istio installations. Future work includes:

- `istioctl` and the controller will support canary based upgrades.
- the controller will continuously monitor and report on the health of Istio components
  and `istioctl` will report health whenever manifest commands are run.
- `istioctl manifest apply` option to read the `IstioControlPlane` resource from the cluster.
- `istioctl operator init` and `istioctl operator remove` commands to install and remove the controller.

We welcome your feedback about the new installation approach at [discuss.istio.io](https://discuss.istio.io/).
