---
title: Installing Istio Sidecar
overview: Instructions for installing the Istio sidecar in application pods automatically using the Istio initializer or manually using istioctl CLI.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

## Pod Spec Requirements

In order to be a part of the service mesh, each pod in the kubernetes
cluster must satisfy the following requirements:

1. _**Service association**:_ The pod must belong to a _single_
  [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/)
  (pods that belong to multiple services are not supported as of now).

1. _**Named ports**:_ Service ports must be named. The port names must be of
  the form `<protocol>[-<suffix>]` with _http_, _http2_, _grpc_, _mongo_, or _redis_
  as the `<protocol>` in order to take advantage of Istio's routing features.
  For example, `name: http2-foo` or `name: http` are valid port names, but
  `name: http2foo` is not.  If the port name does not begin with a recognized
  prefix or if the port is unnamed, traffic on the port will be treated as
  plain TCP traffic (unless the port explicitly uses `Protocol: UDP` to
  signify a UDP port).

1. _**Deployments with app label**:_ It is recommended that Pods deployed using
  the Kubernetes `Deployment` have an explicit `app` label in the
  Deployment specification. Each deployment specification should have a
  distinct `app` label with a value indicating something meaningful. The
  `app` label is used to add contextual information in distributed
  tracing.

1. _**Sidecar in every pod in mesh**:_ Finally, each pod in the mesh must be
  running an Istio compatible sidecar. The following sections describe two
  ways of injecting the Istio sidecar into a pod: manually using `istioctl`
  CLI tool or automatically using the Istio Initializer.  Note that the
  sidecar is not involved in traffic between containers in the same pod.

## Manual sidecar injection

The `istioctl` CLI has a convenience utility called
[kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject)
that can be used to add the Istio sidecar specification into kubernetes
workload specifications. Unlike the Initializers, `kube-inject` merely
transforms the YAML specification to include the Istio sidecar. You are
responsible for deploying the modified YAMLs using standard tools like
`kubectl`. For example, the following command adds the sidecars into pods
specified in sleep.yaml and submits the modified specification to Kubernetes:

```bash
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
```

### Example

Let us try to inject the Istio sidecar into a simple sleep service.

```bash
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
```

Kube-inject subcommand adds the Istio sidecar and the init container to the
deployment specification as shown in the transformed output below:

```yaml
... trimmed ...
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    sidecar.istio.io/status: injected-version-root@69916ebba0fc-0.2.6-081ffece00c82cb9de33cd5617682999aee5298d
  name: sleep
spec:
  replicas: 1
  template:
    metadata:
      annotations:
        sidecar.istio.io/status: injected-version-root@69916ebba0fc-0.2.6-081ffece00c82cb9de33cd5617682999aee5298d
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
      - name: istio-proxy
        image: docker.io/istio/proxy_debug:0.2.6
        args:
        ... trimmed ...
      initContainers:
      - name: istio-init
        image: docker.io/istio/proxy_init:0.2.6
        imagePullPolicy: IfNotPresent
        args:
        ... trimmed ...
---
```

The crux of sidecar injection lies in the `initContainers` and the
istio-proxy container. The output above has been trimmed for brevity.

Verify that sleep's deployment contains the sidecar. The
injected version corresponds to the image TAG of the injected sidecar
image. It may be different in your setup.

```bash
echo $(kubectl get deployment sleep -o jsonpath='{.metadata.annotations.sidecar\.istio\.io\/status}')
```

```bash
injected-version-9c7c291eab0a522f8033decd0f5b031f5ed0e126
```

You can view the full deployment with injected containers and volumes.

```bash
kubectl get deployment sleep -o yaml
```

## Automatic sidecar injection

Istio sidecars can be automatically injected into a Pod before deployment
using an alpha feature in Kubernetes called
[Initializers](https://kubernetes.io/docs/admin/extensible-admission-controllers/#what-are-initializers).

> Note: Kubernetes InitializerConfiguration is not namespaced and
> applies to workloads across the entire cluster. Do _not_ enable
> this feature in shared testing environments.

### Prerequisites

Initializers need to be explicitly enabled during cluster setup as outlined
[here](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature). 
Assuming RBAC is enabled in the cluster, you can enable the initializers in
different environments as follows:

* _GKE_

  ```bash
  gcloud container clusters create NAME \
      --enable-kubernetes-alpha \
      --machine-type=n1-standard-2 \
      --num-nodes=4 \
      --no-enable-legacy-authorization \
      --zone=ZONE
  ```

* _IBM Bluemix_ kubernetes clusters with v1.7.4 or newer versions have
  initializers enabled by default.

* _Minikube_

  Minikube version v0.22.1 or later is required for proper certificate
  configuration for the GenericAdmissionWebhook feature. Get the latest
  version from https://github.com/kubernetes/minikube/releases.

  ```bash
  minikube start \
      --extra-config=apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
      --kubernetes-version=v1.7.5
  ```

### Setup

You can now setup the Istio Initializer from the Istio install root directory.

```bash
kubectl apply -f install/kubernetes/istio-initializer.yaml
```

This creates the following resources:

1. The `istio-sidecar` InitializerConfiguration resource that 
specifies resources where Istio sidecar should be injected. By default
the Istio sidecar will be injected into `deployments`, `statefulsets`, `jobs`, and `daemonsets`.

1. The `istio-inject` ConfigMap with the default injection policy for the
initializer, a set of namespaces to initialize, and template parameters to
use during the injection itself. These options are explained in more detail
under [configuration options](#configuration-options).

1. The `istio-initializer` Deployment that runs the initializer controller.

1. The `istio-initializer-service-account` ServiceAccount that is used by the
`istio-initializer` deployment. The `ClusterRole` and
`ClusterRoleBinding` are defined in `install/kubernetes/istio.yaml`. Note
that `initialize` and `patch` are required on _all_ resource
types. It is for this reason that the initializer is run as its own
deployment and not embedded in another controller, e.g. istio-pilot.

### Verification

In order to test whether sidecar injection is working, let us take the
sleep service described above. Create the deployments and services.

```bash
kubectl apply -f samples/sleep/sleep.yaml
```

You can verify that sleep's deployment contains the sidecar. The
injected version corresponds to the image TAG of the injected sidecar
image. It may be different in your setup.

```bash
$ echo $(kubectl get deployment sleep -o jsonpath='{.metadata.annotations.sidecar\.istio\.io\/status}')
```

```bash
injected-version-9c7c291eab0a522f8033decd0f5b031f5ed0e126
```

You can view the full deployment with injected containers and volumes.

```bash
kubectl get deployment sleep -o yaml
```

### Understanding what happened

Here's what happened after the workload was submitted to Kubernetes:

1) kubernetes adds `sidecar.initializer.istio.io` to the list of
pending initializers in the workload.

2) istio-initializer controller observes a new uninitialized workload was created. 
It finds its configured name `sidecar.initializer.istio.io`
as the first in the list of pending initializers.

3) istio-initializer checks to see if it was responsible for
initializing workloads in the namespace of the workload. No further work is done
and the initializer ignores the workload if the initializer is not
configured for the namespace. By default the initializer is
responsible for all namespaces (see [configuration options](#configuration-options)).

4) istio-initializer removes itself from the list of pending
initializers. Kubernetes will not finish creating workloads if the
list of pending initializers is non-empty. A misconfigured initializer
means a broken cluster.

5) istio-initializer checks the default injection policy for the mesh
_and_ any possible per-workload overrides to determine whether the
sidecar should be injected.

6) istio-initializer injects the sidecar template into the workload
and submits it back to kubernetes via PATCH.

7) kubernetes finishes creating the workload as normal and the
workload includes the injected sidecar.

### Configuration options

The istio-initializer has a global default policy for injection as
well as per-workload overrides. The global policy is configured by the
`istio-inject` ConfigMap (see example below). The initializer pod must
be restarted to adopt new configuration changes.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio-inject
  namespace: istio-system
data:
  config: |-
    policy: "enabled"
    namespaces: [""] # everything, aka v1.NamepsaceAll, aka cluster-wide
    # excludeNamespaces: ["ns1", "ns2"]
    initializerName: "sidecar.initializer.istio.io"
    params:
      initImage: docker.io/istio/proxy_init:0.2.6
      proxyImage: docker.io/istio/proxy:0.2.6
      verbosity: 2
      version: 0.2.6
      meshConfigMapName: istio
      imagePullPolicy: IfNotPresent
```

The following are key parameters in the configuration:

1. _**policy**_

 `off` - Disable the initializer from modifying resources. The pending
 `sidecar.initializer.istio.io` initializer is still removed to
 avoid blocking creation of resources.

 `disabled` - The initializer will not inject the sidecar into
 resources by default for the namespace(s) being watched. Resources can
 enable injection using the `sidecar.istio.io/inject` annotation with
 value of `true`.

 `enabled` - The initializer will inject the sidecar into resources by
 default for the namespace(s) being watched. Resources can disable
 injection using the `sidecar.istio.io/inject` annotation with value of
 `false`.

2. _**namespaces**_

 This is a list of namespaces to watch and initialize. The special `""`
 namespace corresponds to `v1.NamespaceAll` and configures the
 initializer to initialize all namespaces. kube-system, kube-public, and 
 istio-system are exempt from initialization.

3. _**excludeNamespaces**_

 This is a list of namespaces to be excluded from istio initializer. It
 cannot be definend as `v1.NamespaceAll` or defined together with
 `namespaces`.

4. _**initializerName**_

 This must match the name of the initializer in the
 InitializerConfiguration. The initializer only processes workloads
 that match its configured name.

5. _**params**_

 These parameters allow you to make limited changes to the injected
 sidecar. Changing these values will not affect already deployed workloads.

### Overriding automatic injection

Individual workloads can override the global policy using the
`sidecar.istio.io/inject` annotation. The global policy applies
if the annotation is omitted.

If the value of the annotation is `true`, sidecar will be
injected regardless of the global policy.

If the value of the annotation is `false`, sidecar will _not_ be
injected regardless of the global policy.

The following truth table shows the combinations of global policy and
per-workload overrides.

|  policy  | workload annotation | injected |
| -------- | ------------------- | -------- |
| off      | N/A                 | no       |
| disabled | omitted             | no       |
| disabled | false               | no       |
| disabled | true                | yes      |
| enabled  | omitted             | yes      |
| enabled  | false               | no       |
| enabled  | true                | yes      |

For example, the following deployment will have sidecars injected, even if
the global policy is `disabled`.

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: myapp
  annotations:
    sidecar.istio.io/inject: "true"
spec:
  replicas: 1
  template:
    ...
```

This is a good way to use auto-injection in a cluster containing a mixture
of Istio and non-Istio services.


### Uninstalling Initializer

To remove the Istio initializer, run the following command:

```bash
kubectl delete -f install/kubernetes/istio-initializer.yaml
```

Note that the above command will not remove the injected sidecars from
Pods. To remove the sidecars, the pods must be redeployed without the
initializer.
