---
title: Operator CLI-based Installation
description: Install and configure Istio using the Istio Operator CLI.
weight: 25
keywords: [operator,kubernetes,helm]
---

Follow this guide to install and configure an Istio mesh using an alternate
installation method: the Istio {{<gloss operator>}}Operator CLI{{</gloss>}}
installation.

The Istio Operator CLI offers a new installation method with the option of
installing Istio using a one-line command. It has user input
validation to help prevent installation errors and customization options to
override any aspect of the configuration.

The Operator install is accessed via [`istioctl`](/docs/reference/commands/istioctl/)
commands.

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/#downloading-the-release).
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/).

## Install Istio using the default profile

The simplest option is to install a default Istio configuration using a one-line command:

{{< text bash >}}
$ istioctl manifest apply
{{< /text >}}

This command installs a profile named `default` on the cluster defined by your
Kubernetes configuration. The `default` profile is smaller and more suitable
for establishing a production environment, unlike the larger `demo` profile that
is intended for evaluating a broad set of Istio features.

You can view the `default` profile configuration settings by using this command:

{{< text bash >}}
$ istioctl profile dump
{{< /text >}}

To view a subset of the entire configuration, you can use the `--config-path` flag, which selects only the portion
of the configuration under the given path:

{{< text bash >}}
$ istioctl profile dump --config-path trafficManagement.components.pilot
{{< /text >}}

## Install a different profile

Other Istio configuration profiles can be installed in a cluster using this command:

{{< text bash >}}
$ istioctl manifest apply --set profile=demo
{{< /text >}}

In the example above, `demo` is one of the profile names from the output of
the [`istioctl profile list`](/docs/reference/commands/istioctl/#istioctl-experimental-profile-list) command.

## Display the profile list

You can display the names of Istio configuration profiles that are
accessible to `istioctl` by using this command:

{{< text bash >}}
$ istioctl profile list
{{< /text >}}

## Customize Istio settings using the `IstioControlPlane` API

You can change a feature or component setting by using the [`IstioControlPlane` API](/docs/reference/config/istio.operator.v1alpha12.pb/).

### Identify the feature or component

The API groups Istio control plane components by feature, as shown in the table below:

| Feature | Components |
|---------|------------|
`Base` | CRDs
`Traffic Management` | Pilot
`Policy` | Policy
`Telemetry` | Telemetry
`Security` | Citadel
`Security` | Node agent
`Security` | Cert manager
`Configuration management` | Galley
`Gateways` | Ingress gateway
`Gateways` | Egress gateway
`AutoInjection` | Sidecar injector

In addition to the core Istio components, third-party addon features and components are also available:

| Feature | Components |
|---------|------------|
`Telemetry` | Prometheus
`Telemetry` | Prometheus Operator
`Telemetry` | Grafana
`Telemetry` | Kiali
`Telemetry` | Tracing
`ThirdParty` | CNI

Features can be enabled or disabled, which enables or disables all of the components that are a part of the feature.
Namespaces that components are installed into can be set by component, feature, or globally.

### Configure the feature or component settings

After you identify the name of the feature or component from the previous table, you can use the API to set the values
using the `--set` flag, or create an overlay file and use the `--filename` flag. The `--set` flag
works well for customizing a few parameters. Overlay files are designed for more extensive customization, or
tracking configuration changes.

The simplest customization is to turn a feature or component on or off from the configuration profile default.

To disable the telemetry feature in a default configuration profile, use this command:

{{< text bash >}}
$ istioctl manifest apply --set telemetry.enabled=false
{{< /text >}}

Alternatively, you can disable the telemetry feature using a configuration overlay file:

1. Create this file with the name `telemetry_off.yaml` and these contents:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  telemetry:
    enabled: false
{{< /text >}}

1. Use the `telemetry_off.yaml` overlay file with the `manifest apply` command:

{{< text bash >}}
$ istioctl manifest apply -f telemetry_off.yaml
{{< /text >}}

You can also use this approach to set the component-level configuration, such as enabling the node agent:

{{< text bash >}}
$ istioctl manifest apply --set security.components.nodeAgent.enabled=true
{{< /text >}}

Another customization is to select different namespaces for features and components. The following is an example
of installation namespace customization:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  defaultNamespace: istio-system
  security:
    namespace: istio-security
    components:
      citadel:
        namespace: istio-citadel
{{< /text >}}

Applying this file will cause the default profile to be applied, with components being installed into the following
namespaces:

- The Citadel component is installed into `istio-citadel` namespace
- All other components in the security feature installed into `istio-security` namespace
- Remaining Istio components installed into istio-system namespace

## Customize Kubernetes settings using the `IstioControlPlane` API

The `IstioControlPlane` API allows each component's Kubernetes settings to be customized in a consistent way.

### Identify the feature or component settings

Each component has a [`KubernetesResourceSpec`](/docs/reference/config/istio.operator.v1alpha12.pb/#KubernetesResourcesSpec),
which allows the following settings to be changed. Use this list to identify the setting to customize:

1. [Resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)
1. [Readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
1. [Replica count](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
1. [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
1. [`PodDisruptionBudget`](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)
1. [Pod annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
1. [Service annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
1. [`ImagePullPolicy`](https://kubernetes.io/docs/concepts/containers/images/)
1. [Priority class name](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)
1. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
1. [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)

All of these Kubernetes settings use the Kubernetes API definitions, so [Kubernetes documentation](https://kubernetes.io/docs/concepts/) can be used for reference.

### Configure the feature or component

After you identify the name of the feature or component from the previous list, you can use the `IstioControlPlane` API
to modify the default values using a configuration overlay file.

The following example overlay file adjusts the `TrafficManagement` feature's resources and horizontal pod autoscaling
settings for Pilot:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  trafficManagement:
    components:
      pilot:
        k8s:
          resources:
            requests:
              cpu: 1000m # override from default 500m
              memory: 4096Mi # ... default 2048Mi
          hpaSpec:
            maxReplicas: 10 # ... default 5
            minReplicas: 2  # ... default 1
{{< /text >}}

Use `manifest apply` to apply the modified settings to the cluster:

{{< text syntax="bash" repo="operator" >}}
$ istioctl manifest apply -f @samples/pilot-k8s.yaml@
{{< /text >}}

## Customize Istio settings using the Helm API

The `IstioControlPlane` API includes a pass-through interface to the [Helm API](/docs/reference/config/installation-options/)
using the `values` field.

The following YAML file configures global and Pilot settings through the Helm API:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
spec:
  trafficManagement:
    components:
      pilot:
        values:
          traceSampling: 0.1 # override from 1.0

  # global Helm settings
  values:
    monitoringPort: 15050
{{< /text >}}

Some parameters will temporarily exist in both the Helm and `IstioControlPlane` APIs, including Kubernetes resources,
namespaces and enablement settings. The Istio community recommends using the `IstioControlPlane` API as it is more
consistent, is validated, and follows the [community graduation process](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist).

## Show differences in profiles

The `profile diff` sub-command can be used to show the differences between profiles,
which is useful for checking the effects of customizations before applying changes to a cluster.

You can show differences between the default and demo profiles using these commands:

{{< text bash >}}
$ istioctl profile dump default > 1.yaml
$ istioctl profile dump demo > 2.yaml
$ istioctl profile diff 1.yaml 2.yaml
{{< /text >}}

## Show differences in manifests

You can show the differences in the generated manifests between the default profile and a customized install using these commands:

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f samples/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yam1 2.yaml
{{< /text >}}

## Inspect/modify a manifest before installation

You can inspect or modify the manifest before installing Istio using these steps:

Generate the manifest using this command:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

Inspect the manifest as needed, then apply the manifest using this command:

{{< tip >}}
This command might show transient errors due to resources not being available in
the cluster in the correct order.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f $HOME/generated-manifest.yaml
{{< /text >}}

## Verify a successful installation

You can check if the Istio installation succeeded using the `verify-install` command.
This compares the installation on your cluster to a manifest you specify
and displays the results:

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

## Uninstall Istio

To uninstall Istio, run the following command:

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete -f -
{{< /text >}}

