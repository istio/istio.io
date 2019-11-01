---
title: Introducing the Istio Operator
description: Introduction to Istio's new operator-based installation and control plane management feature.
publishdate: 2019-11-04
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
In addition to needing to install another tool, this approach is not so desireable because it lacks
schematic validation, allowing invalid configurations to be applied, which can then only be detected
after installation. With operators, on the other hand, the API is schematized in a
CRD (Custom Resource Definition) which is validated.

The newly released Istio operator simplifies the common administrative tasks of installation,
upgrade, and complex configuration changes for Istio.
Starting with Istio 1.4, the [Helm installation](/docs/setup/install/helm/) approach has been deprecated
in favor of a new operator-based [installation using {{< istioctl >}}](/docs/setup/install/operator/).
Upgrading from Istio 1.4 onward (that is, versions not initially installed with Helm)
will also be done using a new [{{< istioctl >}} upgrade feature](/docs/setup/upgrade/istioctl-upgrade/).

## Istio Control Plane API

An operator implementation requires a CRD (Custom Resource Definition) to define the API.
The Istio operator CRD is defined by the [`IstioControlPlane` API](/docs/reference/config/istio.operator.v1alpha12.pb/).
This API supports all of Istio's current [configuration profiles](/docs/setup/additional-setup/config-profiles/)
using a single field to select the profile. For example, the following CRD configures Istio using the `demo` profile:

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

## Istio Controller (alpha)

An operator implementation also requires a Kubernetes controller to continuously monitors the CRD
and apply the corresponding configuration changes.
The Istio controller is a pod in your cluster that reacts to changes in an
`IstioControlPlane` CRD for the cluster by updating the Istio installation configuration.

In the 1.4 release, the Istio controller is still in the alpha phase of development and not fully
integrated with `istioctl`. It is, however, available for experimentation using `kubectl` commands.
For example, to install the controller and a default version of Istio into your cluster,
run the following command:

{{< text bash >}}
$ kubectl apply -f https://<repo URL>/<version>/operator-profile-default.yaml
{{< /text >}}

You can then make changes to the Istio installation configuration:

{{< text bash >}}
$ kubectl edit istiocontrolplane example-istiocontrolplane -n istio-system
{{< /text >}}

To upgrade to a new version of Istio, run:

{{< text bash >}}
$ kubectl apply -f https://<repo URL>/<new version>/operator-profile-default.yaml
{{< /text >}}

Refer to [standalone operator](/docs/ops/setup/standalone-operator/) for more details.

## Using the {{< istioctl >}} CLI

In the meantime, until the controller is thouroughly tested and better integrated with `istioctl`,
the preferred way to use the operator API is through a new set of `istioctl` CLI commands.
The same code is executed, the main difference being the execution context.
In the CLI case, the operation runs in the admin user’s CLI execution and
security context, while in the controller case, a pod in the cluster runs the code in its security context.
In both cases, the API is schematized and validated.

To install Istio into a cluster:

{{< text bash >}}
$ istioctl manifest apply -f <your-config-crd>
{{< /text >}}

Make changes to the installation configuration by editing the configuration
file and calling `istioctl manifest apply` again.

To upgrade to a new version of Istio:

{{< text bash >}}
$ istioctl x upgrade -f <your-config-changes-crd>
{{< /text >}}

In additon to specifying the complete configuration in an `IstioControlPlane` CRD,
the `istioctl` commands can also be passed individual settings using a `--set` flag.
There are also a number of other `istioctl` commands that, for example,
help you list, display, and compare configuration profiles and manifests.
Refer to the Istio [install instructions](/docs/setup/install/) for more details.

## Migration from Helm

The `istioctl` command includes several features to help ease the trasition from previous
configurations using Helm:

1. Pass Helm configuration options using `istioctl --set` by prepending the string “values.“
    to the option name. For example, instead of this helm command:

    {{< text bash >}}
    $ helm template ... --set global.mtls.enabled=true
    {{< /text >}}

    You can use this `istioctl` command:

    {{< text bash >}}
    $ istioctl manifest generate ... --set values.global.mtls.enabled=true
    {{< /text >}}

1. Automated migration from helm `values.yaml` using the `istioctl manifest migrate` command (alpha in Istio 1.4).

1. The full helm installation API can also be accessed as a pass-through from `istioctl` and controller.
   See [Customize Istio settings using the Helm API](/docs/setup/install/operator/#customize-istio-settings-using-the-helm-api)
   for details. 

## Implementation

Several frameworks have been created to help implement operators by generating stubs
for some or all of the components. The Istio operator was created with the help of a combination of
[kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
and [operator framework](https://github.com/operator-framework),
but follows the Istio convention of using a proto to represent the API.
 
More information about the implementation can be found in the README and ARCHITECTURE documents
in the [Istio operator repository](https://github.com/istio/operator). 

## Future work

- `istioctl` and the controller will support canary based upgrades. 
- the controller will continuously monitor and report on the health of Istio components
  and `istioctl` will report health whenever manifest commands are run. 
- `istioctl manifest apply` option to read the CRD from the cluster.
- `istioctl operator init` and `istioctl operator remove` commands to install and remove the controller.
