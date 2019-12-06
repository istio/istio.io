---
title: Customizable Install with Istioctl
description: Install and customize any Istio configuration profile for in-depth evaluation or production use.
weight: 10
keywords: [istioctl,kubernetes]
---

Follow this guide to install and configure an Istio mesh for in-depth evaluation or production use.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/docs/setup/getting-started) instead.

This installation guide uses the [`istioctl`](/docs/reference/commands/istioctl/) command line
tool to provide rich customization of the Istio control plane and of the sidecars for the Istio data plane.
It has user input validation to help prevent installation errors and customization options to
override any aspect of the configuration.

Using these instructions, you can select any one of Istio's built-in
[configuration profiles](/docs/setup/additional-setup/config-profiles/)
and then further customize the configuration for your specific needs.

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/getting-started/#download).
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

## Install Istio using the default profile

The simplest option is to install the `default` Istio
[configuration profile](/docs/setup/additional-setup/config-profiles/)
using the following command:

{{< text bash >}}
$ istioctl manifest apply
{{< /text >}}

This command installs the `default` profile on the cluster defined by your
Kubernetes configuration. The `default` profile is a good starting point
for establishing a production environment, unlike the larger `demo` profile that
is intended for evaluating a broad set of Istio features.

If you want to enable security on top of the `default` profile, you can set the
security related configuration parameters:

{{< text bash >}}
$ istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true
{{< /text >}}

In general, you can use the `--set` flag in `istioctl` as you would with
[Helm](/docs/setup/install/helm/). The only difference is you must
prefix the setting paths with `values.` because this is the path to the Helm pass-through API, described below.

## Install from external charts

By default, `istioctl` uses compiled-in charts to generate the install manifest. These charts are released together with
`istioctl` for auditing and customization purposes and can be found in the release tar in the
`install/kubernetes/operator/charts` directory.
`istioctl` can also use external charts rather than the compiled-in ones. To select external charts, set
`installPackagePath` to a local file system path:

{{< text bash >}}
$ istioctl manifest apply --set installPackagePath=~/istio-releases/istio-{{< istio_full_version >}}/install/kubernetes/operator/charts
{{< /text >}}

If using the `istioctl` {{< istio_full_version >}} binary, this command will result in the same installation as `istioctl manifest apply` alone, because it points to the
same charts as the compiled-in ones.
Other than for experimenting with or testing new features, we recommend using the compiled-in charts rather than external ones to ensure compatibility of the
`istioctl` binary with the charts.

## Install a different profile

Other Istio configuration profiles can be installed in a cluster by passing the
profile name on the command line. For example, the following command can be used
to install the `demo` profile:

{{< text bash >}}
$ istioctl manifest apply --set profile=demo
{{< /text >}}

## Display the list of available profiles

You can display the names of Istio configuration profiles that are
accessible to `istioctl` by using this command:

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    minimal
    remote
    sds
    default
    demo
{{< /text >}}

## Display the configuration of a profile

You can view the configuration settings of a profile. For example, to view the setting for the `demo` profile
run the following command:

{{< text bash >}}
$ istioctl profile dump demo
autoInjection:
  components:
    injector:
      enabled: true
      k8s:
        replicaCount: 1
        strategy:
          rollingUpdate:
            maxSurge: 100%
            maxUnavailable: 25%
  enabled: true
cni:
  components:
    cni:
      enabled: false
  enabled: false
...
{{< /text >}}

To view a subset of the entire configuration, you can use the `--config-path` flag, which selects only the portion
of the configuration under the given path:

{{< text bash >}}
$ istioctl profile dump --config-path trafficManagement.components.pilot demo
enabled: true
k8s:
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
  - name: GODEBUG
    value: gctrace=1
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  - name: CONFIG_NAMESPACE
    value: istio-config
  hpaSpec:
    maxReplicas: 5
    metrics:
...
{{< /text >}}

## Show differences in profiles

The `profile diff` sub-command can be used to show the differences between profiles,
which is useful for checking the effects of customizations before applying changes to a cluster.

You can show differences between the default and demo profiles using these commands:

{{< text bash >}}
$ istioctl profile dump default > 1.yaml
$ istioctl profile dump demo > 2.yaml
$ istioctl profile diff 1.yaml 2.yaml
 gateways:
   components:
     egressGateway:
-      enabled: false
+      enabled: true
...
           requests:
-            cpu: 100m
-            memory: 128Mi
+            cpu: 10m
+            memory: 40Mi
         strategy:
...
{{< /text >}}

## Generate a manifest before installation

You can generate the manifest before installing Istio using the `manifest generate`
sub-command, instead of `manifest apply`.
For example, use the following command to generate a manifest for the `default` profile:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

Inspect the manifest as needed, then apply the manifest using this command:

{{< text bash >}}
$ kubectl apply -f $HOME/generated-manifest.yaml
{{< /text >}}

{{< tip >}}
This command might show transient errors due to resources not being available in
the cluster in the correct order.
{{< /tip >}}

## Show differences in manifests

You can show the differences in the generated manifests in a YAML style diff between the default profile and a
customized install using these commands:

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f samples/operator/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yam1 2.yaml
Differences of manifests are:

Object Deployment:istio-system:istio-pilot has diffs:

spec:
  template:
    spec:
      containers:
        '[0]':
          resources:
            requests:
              cpu: 500m -> 1000m
              memory: 2048Mi -> 4096Mi
      nodeSelector: -> map[master:true]
      tolerations: -> [map[effect:NoSchedule key:dedicated operator:Exists] map[key:CriticalAddonsOnly
        operator:Exists]]


Object HorizontalPodAutoscaler:istio-system:istio-pilot has diffs:

spec:
  maxReplicas: 5 -> 10
  minReplicas: 1 -> 2
{{< /text >}}

## Verify a successful installation

You can check if the Istio installation succeeded using the `verify-install` command
which compares the installation on your cluster to a manifest you specify.

If you didn't generate your manifest prior to deployment, run the following command to
generate it now:

{{< text bash >}}
$ istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
{{< /text >}}

Then run the following `verify-install` command to see if the installation was successful:

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

## Customizing the configuration

In addition to installing any of Istio's built-in
[configuration profiles](/docs/setup/additional-setup/config-profiles/),
`istioctl manifest` provides a complete API for customizing the configuration.

- [The `IstioControlPlane` API](/docs/reference/config/istio.operator.v1alpha12.pb/)

The configuration parameters in this API can be set individually using `--set` options on the command
line. For example, to enable the security feature in a default configuration profile, use this command:

{{< text bash >}}
$ istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true
{{< /text >}}

Alternatively, the `IstioControlPlane` configuration can be specified in a YAML file and passed to
`istioctl` using the `-f` option:

{{< text bash >}}
$ istioctl manifest apply -f samples/operator/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
For backwards compatibility, the previous [Helm installation options](/docs/reference/config/installation-options/)
are also fully supported. To set them on the command line, prepend the option name with "`values.`".
For example, the following command overrides the `pilot.traceSampling` Helm configuration option:

{{< text bash >}}
$ istioctl manifest apply --set values.pilot.traceSampling=0.1
{{< /text >}}

Helm values can also be set in an `IstioControlPlane` definition as described in
[Customize Istio settings using the Helm API](#customize-istio-settings-using-the-helm-api), below.
{{< /tip >}}

### Identify an Istio feature or component

The `IstioControlPlane` API groups control plane components by feature, as shown in the table below:

| Feature | Components |
|---------|------------|
`base` | `CRDs`
`trafficManagement` | `pilot`
`policy` | `policy`
`telemetry` | `telemetry`
`security` | `citadel`, `nodeAgent`, `certManager`
`configManagement` | `galley`
`gateways` | `ingressGateway`, `egressGateway`
`autoInjection` | `injector`
`coreDNS` | `coreDNS`
`thirdParty` | `cni`

In addition to the core Istio components, third-party addon features and components are also available. These can only
be enabled and configured through the Helm pass-through API:

| Feature | Components |
|---------|------------|
`telemetry` | `prometheus`, `prometheusOperator`, `grafana`, `kiali`, `tracing`

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

### Customize Kubernetes settings

The `IstioControlPlane` API allows each component's Kubernetes settings to be customized in a consistent way.

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
          nodeSelector:
            master: "true"
          tolerations:
          - key: dedicated
            operator: Exists
            effect: NoSchedule
          - key: CriticalAddonsOnly
            operator: Exists
{{< /text >}}

Use `manifest apply` to apply the modified settings to the cluster:

{{< text syntax="bash" repo="operator" >}}
$ istioctl manifest apply -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### Customize Istio settings using the Helm API

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
    global:
      monitoringPort: 15050
{{< /text >}}

Some parameters will temporarily exist in both the Helm and `IstioControlPlane` APIs, including Kubernetes resources,
namespaces and enablement settings. The Istio community recommends using the `IstioControlPlane` API as it is more
consistent, is validated, and follows the [community graduation process](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist).

## Uninstall Istio

To uninstall Istio, run the following command:

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete -f -
{{< /text >}}
