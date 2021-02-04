---
title: Install with Istioctl
description: Install and customize any Istio configuration profile for in-depth evaluation or production use.
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to install and configure an Istio mesh for in-depth evaluation or production use.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/docs/setup/getting-started) instead.

This installation guide uses the [istioctl](/docs/reference/commands/istioctl/) command line
tool to provide rich customization of the Istio control plane and of the sidecars for the Istio data plane.
It has user input validation to help prevent installation errors and customization options to
override any aspect of the configuration.

Using these instructions, you can select any one of Istio's built-in
[configuration profiles](/docs/setup/additional-setup/config-profiles/)
and then further customize the configuration for your specific needs.

The `istioctl` command supports the full [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/)
via command-line options for individual settings or for passing a yaml file containing an `IstioOperator`
{{<gloss CRDs>}}custom resource (CR){{</gloss>}}.

{{< tip >}}
Providing the full configuration in an `IstioOperator` CR is considered an Istio best practice for production
environments. It also gives you the option of completely delegating the job of install management to an
[Istio Operator](/docs/setup/install/operator), instead of doing it manually using `istioctl`.
{{< /tip >}}

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
$ istioctl install
{{< /text >}}

This command installs the `default` profile on the cluster defined by your
Kubernetes configuration. The `default` profile is a good starting point
for establishing a production environment, unlike the larger `demo` profile that
is intended for evaluating a broad set of Istio features.

Various settings can be configured to modify the installations. For example, to enable access logs:

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
Many of the examples on this page and elsewhere in the documentation are written using `--set` to modify installation
parameters, rather than passing a configuration file with `-f`. This is done to make the examples more compact.
The two methods are equivalent, but `-f` is strongly recommended for production. The above command would be written as
follows using `-f`:

{{< text yaml >}}
# my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

{{< text bash >}}
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
The full API is documented in the [`IstioOperator` API reference](/docs/reference/config/istio.operator.v1alpha1/).
In general, you can use the `--set` flag in `istioctl` as you would with
Helm, and the Helm `values.yaml` API is currently supported for backwards compatibility. The only difference is you must
prefix the legacy `values.yaml` paths with `values.` because this is the prefix for the Helm pass-through API.
{{< /tip >}}

## Install from external charts

By default, `istioctl` uses compiled-in charts to generate the install manifest. These charts are released together with
`istioctl` for auditing and customization purposes and can be found in the release tar in the
`manifests` directory.
`istioctl` can also use external charts rather than the compiled-in ones. To select external charts, set
the `manifests` flag to a local file system path:

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

If using the `istioctl` {{< istio_full_version >}} binary, this command will result in the same installation as `istioctl install` alone, because it points to the
same charts as the compiled-in ones.
Other than for experimenting with or testing new features, we recommend using the compiled-in charts rather than external ones to ensure compatibility of the
`istioctl` binary with the charts.

## Install a different profile

Other Istio configuration profiles can be installed in a cluster by passing the
profile name on the command line. For example, the following command can be used
to install the `demo` profile:

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## Check what's installed

The `istioctl` command saves the `IstioOperator` CR that was used to install Istio in a copy of the CR named `installed-state`.
Instead of inspecting the deployments, pods, services and other resources that were installed by Istio, for example:

{{< text bash >}}
$ kubectl -n istio-system get deploy
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
istio-egressgateway    1/1     1            1           25s
istio-ingressgateway   1/1     1            1           24s
istiod                 1/1     1            1           20s
{{< /text >}}

You can inspect the `installed-state` CR, to see what is installed in the cluster, as well as all custom settings.
For example, dump its content into a YAML file using the following command:

{{< text bash >}}
$ kubectl -n istio-system get IstioOperator installed-state -o yaml > installed-state.yaml
{{< /text >}}

The `installed-state` CR is also used to perform checks in some `istioctl` commands and should therefore not be removed.

## Display the list of available profiles

You can display the names of Istio configuration profiles that are
accessible to `istioctl` by using this command:

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
{{< /text >}}

## Display the configuration of a profile

You can view the configuration settings of a profile. For example, to view the setting for the `demo` profile
run the following command:

{{< text bash >}}
$ istioctl profile dump demo
components:
  egressGateways:
  - enabled: true
    k8s:
      resources:
        requests:
          cpu: 10m
          memory: 40Mi
    name: istio-egressgateway

...
{{< /text >}}

To view a subset of the entire configuration, you can use the `--config-path` flag, which selects only the portion
of the configuration under the given path:

{{< text bash >}}
$ istioctl profile dump --config-path components.pilot demo
enabled: true
k8s:
  env:
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
{{< /text >}}

## Show differences in profiles

The `profile diff` sub-command can be used to show the differences between profiles,
which is useful for checking the effects of customizations before applying changes to a cluster.

You can show differences between the default and demo profiles using these commands:

{{< text bash >}}
$ istioctl profile diff default demo
 gateways:
   egressGateways:
-  - enabled: false
+  - enabled: true
...
     k8s:
        requests:
-          cpu: 100m
-          memory: 128Mi
+          cpu: 10m
+          memory: 40Mi
       strategy:
...
{{< /text >}}

## Generate a manifest before installation

You can generate the manifest before installing Istio using the `manifest generate`
sub-command.
For example, use the following command to generate a manifest for the `default` profile:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

The generated manifest can be used to inspect what exactly is installed as well as to track changes to the manifest
over time. While the `IstioOperator` CR represents the full user configuration and is sufficient for tracking it,
the output from `manifest generate` also captures possible changes in the underlying charts and therefore can be
used to track the actual installed resources.

The output from `manifest generate` can also be used to install Istio using `kubectl apply` or equivalent. However,
these alternative installation methods may not apply the resources with the same sequencing of dependencies as
`istioctl install` and are not tested in an Istio release.

{{< warning >}}
If attempting to install and manage Istio using `istioctl manifest generate`, please note the following caveats:

1. The Istio namespace (`istio-system` by default) must be created manually.

1. While `istioctl install` will automatically detect environment specific settings from your Kubernetes context,
`manifest generate` cannot as it runs offline, which may lead to unexpected results. In particular, you must ensure
that you follow [these steps](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) if your
Kubernetes environment does not support third party service account tokens.

1. `kubectl apply` of the generated manifest may show transient errors due to resources not being available in the
cluster in the correct order.

1. `istioctl install` automatically prunes any resources that should be removed when the configuration changes (e.g.
if you remove a gateway). This does not happen when you use `istio manifest generate` with `kubectl` and these
resources must be removed manually.

{{< /warning >}}

## Show differences in manifests

You can show the differences in the generated manifests in a YAML style diff between the default profile and a
customized install using these commands:

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f operator/samples/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yaml 2.yaml
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
        nodeSelector:
          master: "true"
        tolerations:
        - key: dedicated
          operator: Exists
          effect: NoSchedule
        - key: CriticalAddonsOnly
          operator: Exists
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
      monitoringPort: 15050
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
- charts in the local file system, e.g., `istioctl install --manifests istio-{{< istio_full_version >}}/manifests`
- charts in GitHub, e.g., `istioctl install --manifests https://github.com/istio/istio/releases/download/{{< istio_full_version >}}/istio-{{< istio_full_version >}}-linux-arm64.tar.gz`

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

## Uninstall Istio

To completely uninstall Istio from a cluster, run the following command:

{{< text bash >}}
$ istioctl x uninstall --purge
{{< /text >}}

{{< warning >}}
The optional `--purge` flag will remove all Istio resources, including cluster-scoped resources that may be shared with other Istio control planes.
{{< /warning >}}

Alternatively, to remove only a specific Istio control plane, run the following command:

{{< text bash >}}
$ istioctl x uninstall <your original installation options>
{{< /text >}}

or

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
