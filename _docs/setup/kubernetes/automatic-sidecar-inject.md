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

1._Service association:_ The pod must belong to a _single_
  [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/)
  (pods that belong to multiple services are not supported as of now).

1._Named ports:_ Service ports must be named. The port names must begin
  with _http_, _http2_, _grpc_, or _mongo_ prefix in order to take advantage
  of Istio's routing features. For example, `name: http2-foo` or `name: http`
  are valid port names.  If the port name does not begin with a recognized
  prefix or if the port is unnamed, traffic on the port will be treated as
  plain TCP traffic (unless the port explicitly uses `Protocol: UDP` to
  signify a UDP port). HTTPS traffic will be treated as plain TCP
  traffic. Hence, ports using HTTPS should not use the prefixes specified
  above.

1._Deployments with app label:_ It is recommended that Pods deployed using
  the Kubernetes `Deployment` have an explicit `app` label in the
  Deployment specification. Each deployment specification should have a
  distinct `app` label with a value indicating something meaningful. The
  `app` label is used to add contextual information in distributed
  tracing.

1.Finally, each pod in the mesh must be running an Istio compatible
  sidecar. The following sections describe two ways of injecting the
  Istio sidecar into a pod: automatically using the Istio Initializer and
  manually using `istioctl` CLI tool.

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
      --cluster-version=1.7.5 \
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

In order to test whether sidecar injection is working, save the following
YAML snippet into `apps.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-one
  labels:
    app: service-one
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: http
  selector:
    app: service-one
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: service-one
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: service-one
    spec:
      containers:
      - name: app
        image: gcr.io/google_containers/echoserver:1.4
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: service-two
  labels:
    app: service-two
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: http-status
  selector:
    app: service-two
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: service-two
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: service-two
    spec:
      containers:
      - name: app
        image: gcr.io/google_containers/echoserver:1.4
        ports:
        - containerPort: 8080
```

Create the deployments and services.

```bash
kubectl apply -f apps.yaml
```

Verify that service-one's deployment had the sidecar injected. The
injected version corresponds to the image TAG of the injected sidecar
image. It may be different in your setup.

```bash
$ echo $(kubectl get deployment service-one -o jsonpath='{.metadata.annotations.sidecar\.istio\.io\/status}')
injected-version-9c7c291eab0a522f8033decd0f5b031f5ed0e126
```

You can view the full deployment with injected containers and volumes.

```bash
kubectl get deployment service-one -o yaml
```

<!-- Make a request from the client (service-one) to the server -->
<!-- (service-two) and verify the `x-request-id` appears in the server -->
<!-- proxy logs. -->

<!-- ```bash -->
<!-- CLIENT=$(kubectl get pod -l app=service-one -o jsonpath='{.items[0].metadata.name}') -->
<!-- SERVER=$(kubectl get pod -l app=service-two -o jsonpath='{.items[0].metadata.name}') -->

<!-- kubectl exec -it ${CLIENT} -c app -- curl service-two:80 | grep x-request-id -->
<!-- ``` -->
<!-- ```bash -->
<!-- x-request-id=a641eff7-eb82-4a4f-b67b-53cd3a03c399 -->
<!-- ``` -->
<!-- ```bash -->
<!-- kubectl logs ${CLIENT} istio-proxy | grep a641eff7-eb82-4a4f-b67b-53cd3a03c399 -->
<!-- ``` -->
<!-- ```bash -->
<!-- [2017-05-01T22:08:39.310Z] "GET / HTTP/1.1" 200 - 0 398 3 3 "-" "curl/7.47.0" "a641eff7-eb82-4a4f-b67b-53cd3a03c399" "service-two" "10.4.180.7:8080" -->
<!-- ``` -->

### Understanding what happened

Here's what happened after the workload was submitted to Kubernetes:

1) kubernetes adds `sidecar.initializer.istio.io` to the list of
pending initializers in the workload.

2) istio-initializer controller observes a new uninitialized workload was created. 
It finds its configured name `sidecar.initializer.istio.io`
as the first in the list of pending initializers.

3) istio-initializer checks to see if it was responsible for
initializing the namespace of the workload. No further work is done
and the initializer ignores the workload if the initializer is
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

### [Configuration options](#configuration-options)

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
    initializerName: "sidecar.initializer.istio.io"
    params:
      initImage: docker.io/istio/proxy_init:0.2.6
      proxyImage: docker.io/istio/proxy:0.2.6
      verbosity: 2
      version: 0.2.6
      meshConfigMapName: istio
      imagePullPolicy: IfNotPresent
```

1._policy_

 `off` - Disable the initializer from modifying resources. The pending
 `status.sidecar.istio.io initializer` initializer is still removed to
 avoid blocking creation of resources.

 `disabled` - The initializer will not inject the sidecar into
 resources by default for the namespace(s) being watched. Resources can
 enable injection using the `sidecar.istio.io/inject` annotation with
 value of `true`.

 `enabled` - The initializer will inject the sidecar into resources by
 default for the namespace(s) being watched. Resources can disable
 injection using the `sidecar.istio.io/inject` annotation with value of
 `false`.

2._namespaces_

 This is a list of namespaces to watch and initialize. The special `""`
 namespace corresponds to `v1.NamespaceAll` and configures the
 initializer to initialize all namespaces. kube-system, kube-public, and 
 istio-system are exempt from initialization.

3._initializerName_

 This must match the name of the initializer in the
 InitializerConfiguration. The initializer only processes workloads
 that match its configured name.

4._params_

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

### Uninstall

```bash
kubectl delete -f install/kubernetes/istio-initializer.yaml
```
