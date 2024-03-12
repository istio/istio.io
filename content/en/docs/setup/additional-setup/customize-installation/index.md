---
title: Customizing the installation configuration
description: Describes how to customize installation configuration options.
weight: 50
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/getting-started/#download).
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

In addition to installing any of Istio's built-in
[configuration profiles](/docs/setup/additional-setup/config-profiles/),
`istioctl install` provides a complete API for customizing the configuration.

- [The `IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/)

The configuration parameters in this API can be set individually using `--set` options on the command
line. For example, to enable debug logging in a default configuration profile, use this command:

{{< text bash >}}
$ istioctl install --set values.global.logging.level=debug
{{< /text >}}

Alternatively, the `IstioOperator` configuration can be specified in a YAML file and passed to
`istioctl` using the `-f` option:

{{< text bash >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
For backwards compatibility, the previous [Helm installation options](https://archive.istio.io/v1.4/docs/reference/config/installation-options/), with the exception of Kubernetes resource settings,
are also fully supported. To set them on the command line, prepend the option name with "`values.`".
For example, the following command overrides the `pilot.traceSampling` Helm configuration option:

{{< text bash >}}
$ istioctl install --set values.pilot.traceSampling=0.1
{{< /text >}}

Helm values can also be set in an `IstioOperator` CR (YAML file) as described in
[Customize Istio settings using the Helm API](#customize-istio-settings-using-the-helm-api), below.

If you want to set Kubernetes resource settings, use the `IstioOperator` API as described in
 [Customize Kubernetes settings](#customize-kubernetes-settings).
{{< /tip >}}

### Identify an Istio component

The `IstioOperator` API defines components as shown in the table below:

| Components |
| ------------|
`base` |
`pilot` |
`ingressGateways` |
`egressGateways` |
`cni` |
`istiodRemote` |

The configurable settings for each of these components are available in the API under `components.<component name>`.
For example, to use the API to change (to false) the `enabled` setting for the `pilot` component, use
`--set components.pilot.enabled=false` or set it in an `IstioOperator` resource like this:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      enabled: false
{{< /text >}}

All of the components also share a common API for changing Kubernetes-specific settings, under
`components.<component name>.k8s`, as described in the following section.

### Customize Kubernetes settings

The `IstioOperator` API allows each component's Kubernetes settings to be customized in a consistent way.

Each component has a [`KubernetesResourceSpec`](/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpec),
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
1. [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
1. [Toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
1. [Strategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
1. [Env](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
1. [Pod security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
1. [Volumes and volume mounts](https://kubernetes.io/docs/concepts/storage/volumes/)

All of these Kubernetes settings use the Kubernetes API definitions, so [Kubernetes documentation](https://kubernetes.io/docs/concepts/) can be used for reference.

The following example overlay file adjusts the resources and horizontal pod autoscaling
settings for Pilot:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
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

Use `istioctl install` to apply the modified settings to the cluster:

{{< text syntax="bash" repo="operator" >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### Customize Istio settings using the Helm API

The `IstioOperator` API includes a pass-through interface to the [Helm API](https://archive.istio.io/v1.4/docs/reference/config/installation-options/)
using the `values` field.

The following YAML file configures global and Pilot settings through the Helm API:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      traceSampling: 0.1 # override from 1.0
    global:
      monitoringPort: 15014
{{< /text >}}

Some parameters will temporarily exist in both the Helm and `IstioOperator` APIs, including Kubernetes resources,
namespaces and enablement settings. The Istio community recommends using the `IstioOperator` API as it is more
consistent, is validated, and follows the [community graduation process](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist).

### Configure gateways

Gateways are a special type of component, since multiple ingress and egress gateways can be defined. In the
[`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/), gateways are defined as a list type.
The `default` profile installs one ingress gateway, called `istio-ingressgateway`. You can inspect the default values
for this gateway:

{{< text bash >}}
$ istioctl profile dump --config-path components.ingressGateways
$ istioctl profile dump --config-path values.gateways.istio-ingressgateway
{{< /text >}}

These commands show both the `IstioOperator` and Helm settings for the gateway, which are used together to define the
generated gateway resources. The built-in gateways can be customized just like any other component.

{{< warning >}}
From 1.7 onward, the gateway name must always be specified when overlaying. Not specifying any name no longer
defaults to `istio-ingressgateway` or `istio-egressgateway`.
{{< /warning >}}

A new user gateway can be created by adding a new list entry:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
      - namespace: user-ingressgateway-ns
        name: ilb-gateway
        enabled: true
        k8s:
          resources:
            requests:
              cpu: 200m
          serviceAnnotations:
            cloud.google.com/load-balancer-type: "internal"
          service:
            ports:
            - port: 8060
              targetPort: 8060
              name: tcp-citadel-grpc-tls
            - port: 5353
              name: tcp-dns
{{< /text >}}

Note that Helm values (`spec.values.gateways.istio-ingressgateway/egressgateway`) are shared by all ingress/egress
gateways. If these must be customized per gateway, it is recommended to use a separate IstioOperator CR to generate
a manifest for the user gateways, separate from the main Istio installation:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
      - name: ilb-gateway
        namespace: user-ingressgateway-ns
        enabled: true
        # Copy settings from istio-ingressgateway as needed.
  values:
    gateways:
      istio-ingressgateway:
        debug: error
{{< /text >}}

## Advanced install customization

### Customizing external charts and profiles

The `istioctl` `install`, `manifest generate` and `profile` commands can use any of the following sources for charts and
profiles:

- compiled in charts. This is the default if no `--manifests` option is set. The compiled in charts are the same as those
in the `manifests/` directory of the Istio release `.tgz`.
- charts in the local file system, e.g., `istioctl install --manifests istio-{{< istio_full_version >}}/manifests`.

Local file system charts and profiles can be customized by editing the files in `manifests/`. For extensive changes,
we recommend making a copy of the `manifests` directory and make changes there. Note, however, that the content layout
in the `manifests` directory must be preserved.

Profiles, found under `manifests/profiles/`, can be edited and new ones added by creating new files with the
desired profile name and a `.yaml` extension. `istioctl` scans the `profiles` subdirectory and all profiles found there
can be referenced by name in the `IstioOperatorSpec` profile field. Built-in profiles are overlaid on the default profile YAML before user
overlays are applied. For example, you can create a new profile file called `custom1.yaml` which customizes some settings
from the `default` profile, and then apply a user overlay file on top of that:

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ --set profile=custom1 -f path-to-user-overlay.yaml
{{< /text >}}

In this case, the `custom1.yaml` and `user-overlay.yaml` files will be overlaid on the `default.yaml` file to obtain the
final values used as the input for manifest generation.

In general, creating new profiles is not necessary since a similar result can be achieved by passing multiple overlay
files. For example, the command above is equivalent to passing two user overlay files:

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ -f manifests/profiles/custom1.yaml -f path-to-user-overlay.yaml
{{< /text >}}

Creating a custom profile is only required if you need to refer to the profile by name through the `IstioOperatorSpec`.

### Patching the output manifest

The `IstioOperator` CR, input to `istioctl`, is used to generate the output manifest containing the
Kubernetes resources to be applied to the cluster. The output manifest can be further customized to add, modify or delete resources
through the `IstioOperator` [overlays](/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay) API, after it is
generated but before it is applied to the cluster.

The following example overlay file (`patch.yaml`) demonstrates the type of output manifest patching that can be done:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  hub: docker.io/istio
  tag: 1.1.6
  components:
    pilot:
      enabled: true
      namespace: istio-control
      k8s:
        overlays:
          - kind: Deployment
            name: istiod
            patches:
              # Select list item by value
              - path: spec.template.spec.containers.[name:discovery].args.[30m]
                value: "60m" # overridden from 30m
              # Select list item by key:value
              - path: spec.template.spec.containers.[name:discovery].ports.[containerPort:8080].containerPort
                value: 1234
              # Override with object (note | on value: first line)
              - path: spec.template.spec.containers.[name:discovery].env.[name:POD_NAMESPACE].valueFrom
                value: |
                  fieldRef:
                    apiVersion: v2
                    fieldPath: metadata.myPath
              # Deletion of list item
              - path: spec.template.spec.containers.[name:discovery].env.[name:REVISION]
              # Deletion of map item
              - path: spec.template.spec.containers.[name:discovery].securityContext
          - kind: Service
            name: istiod
            patches:
              - path: spec.ports.[name:https-dns].port
                value: 11111 # OVERRIDDEN
{{< /text >}}

Passing the file to `istioctl manifest generate -f patch.yaml` applies the above patches to the default profile output
manifest. The two patched resources will be modified as shown below (some parts of the resources are omitted for
brevity):

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
spec:
  template:
    spec:
      containers:
      - args:
        - 60m
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v2
              fieldPath: metadata.myPath
        name: discovery
        ports:
        - containerPort: 1234
---
apiVersion: v1
kind: Service
metadata:
  name: istiod
spec:
  ports:
  - name: https-dns
    port: 11111
---
{{< /text >}}

Note that the patches are applied in the given order. Each patch is applied over the output from the
previous patch. Paths in patches that don't exist in the output manifest will be created.

### List item path selection

Both the `istioctl --set` flag and the `k8s.overlays` field in `IstioOperator` CR support list item selection by `[index]`, `[value]` or by `[key:value]`.
The --set flag also creates any intermediate nodes in the path that are missing in the resource.
