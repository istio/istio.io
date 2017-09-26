---
title: Automatic sidecar injection
overview: Instructions for installing the Istio initializer in Kubernetes to automatically inject the Istio sidecar into pods.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

This page provides instructions to setup the Istio Initializer for automatic sidecar
proxy injection. You'll learn how to enable the prerequisite alpha
features in your cluster, enable the initializer, and fine-tune the
configuration of the initializer itself and your workloads to enable
automatic sidecar proxy injection.

## What's an initializer?

See [What are initializers](https://kubernetes.io/docs/admin/extensible-admission-controllers/#what-are-initializers) and
[Kubernetes Initializer Tutorial](https://github.com/kelseyhightower/kubernetes-initializer-tutorial) for
a general overview of Kubernetes initializers. The Istio Initializer performs the same function as
[istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject) automatically
for cluster workloads.

Note: Kubernetes InitializerConfiguration is not namespaced and
applies to workloads across the entire cluster. Do _not_ enable
this feature in shared testing environments.

## Prerequisites

Kubernetes DynamicAdmissionControl is required for transparent proxy
injection (via initializer) and configuration validation. This is an
alpha feature that must be explicitly enabled.

The following steps assume RBAC is enabled.

### Google Container Engine

Create an alpha cluster on GKE:

```bash
gcloud container clusters create NAME \
    --cluster-version=1.7.5 \
    --enable-kubernetes-alpha \
    --machine-type=n1-standard-2 \
    --num-nodes=4 \
    --no-enable-legacy-authorization \
    --zone=ZONE
```

### IBM Bluemix Container Service
If your cluster is v1.7.4 or newer, you'll have the required [alpha feature](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature) enabled by default.  

### Minikube

Create a cluster with DynamicAdmissionControl enabled on Minikube:

Minikube version v0.22.1 or later is required for proper certificate
configuration for GenericAdmissionWebhook feature. Get the latest
version from https://github.com/kubernetes/minikube/releases.

```bash
minikube start \
    --extra-config=apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.7.5
```

## Installing the initializer

```bash
kubectl apply -f install/kubernetes/istio-initializer.yaml
```

This creates four resources: Deployment, ConfigMap, InitializerConfiguration, and ServiceAccount

### InitializerConfiguration

The `istio-sidecar` InitializerConfiguration configures what resources are subject to
initialization. By default `deployments`, `statefulsets`, `jobs`, and
`daemonsets` are enabled.

### ConfigMap

The `istio-inject` ConfigMap contains the default injection
policy for the initializer, namespace(s) to initialize, and template
parameters to use during the injection itself. These options are
explained in more detail under [additional configuration options](#additional-configuration-options).

### Deployment

The `istio-initializer` Deployment runs the initializer controller.

### ServiceAccount

The `istio-initializer-service-account` ServiceAccount is used by the
`istio-initializer` deployment. The `ClusterRole` and
`ClusterRoleBinding` are defined in `install/kubernetes/istio.yaml`. Note
that `initialize` and `patch` are required on _all_ workload resource
types. It is for this reason that the initializer is run as its own
deployment and not embedded in another controller, e.g. istio-pilot.

## Automatic injection

Example deployment and service to demonstrate this task. Save this as
`apps.yaml`.

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
injected version corresponds to the image TAG of the injected proxy
image. It may be different in your setup.

```bash
$ echo $(kubectl get deployment service-one -o jsonpath='{.metadata.annotations.sidecar\.istio\.io\/status}')
injected-version-9c7c291eab0a522f8033decd0f5b031f5ed0e126
```

You can view the full deployment with injected containers and volumes.

```bash
kubectl get deployment service-one -o yaml
```

Make a request from the client (service-one) to the server
(service-two) and verify the `x-request-id` appears in the server
proxy logs.

```bash
CLIENT=$(kubectl get pod -l app=service-one -o jsonpath='{.items[0].metadata.name}')
SERVER=$(kubectl get pod -l app=service-two -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it ${CLIENT} -c app -- curl service-two:80 | grep x-request-id
```
```bash
x-request-id=a641eff7-eb82-4a4f-b67b-53cd3a03c399
```
```bash
kubectl logs ${CLIENT} proxy | grep a641eff7-eb82-4a4f-b67b-53cd3a03c399
```
```bash
[2017-05-01T22:08:39.310Z] "GET / HTTP/1.1" 200 - 0 398 3 3 "-" "curl/7.47.0" "a641eff7-eb82-4a4f-b67b-53cd3a03c399" "service-two" "10.4.180.7:8080"
```

## Understanding what happened

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
responsible for all namespaces (see [additional configuration options](#additional-configuration-options)).

4) istio-initializer removes itself from the list of pending
initializers. Kubernetes will not finish creating workloads if the
list of pending initializers is non-empty. A misconfigured initializer
means a broken cluster.

5) istio-initializer checks the default injection policy for the mesh
_and_ any possible per-workload overrides to determine whether the
sidecar proxy should be injected.

6) istio-initializer injects the sidecar template into the workload
and submits it back to kubernetes via PATCH.

7) kubernetes finishes creating the workload as normal and the
workload includes the injected sidecar proxy.

## [Additional configuration options](#additional-configuration-options)

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
      initImage: docker.io/istio/proxy_init:0.2.4
      proxyImage: docker.io/istio/proxy:0.2.4
      verbosity: 2
      version: 0.2.4
      meshConfigMapName: istio
      imagePullPolicy: IfNotPresent
```

### _policy_

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

##### workload overrides

Individual workloads can override the global policy using the
`sidecar.istio.io/inject` annotation. The global policy applies
if the annotation is omitted.

If the value of the annotation is `true`, sidecar proxy will be
injected regardless of the global policy.

If the value of the annotation is `false`, sidecar proxy will _not_ be
injected regardless of the global policy.

The following truth table shows the combinations of global policy and
per-workload overrides.

|  policy  | workload annotation | injected |
| -------- | ------------------- | -------- |
| off      | N/A                 | no       |
| disabled | omitted          | no       |
| disabled | false               | no       |
| disabled | true                | yes      |
| enabled  | omitted                | yes      |
| enabled  | false               | no       |
| enabled  | true                | yes      |

### _namespaces_

This is a list of namespaces to watch and initialize. The special `""`
namespace corresponds to `v1.NamespaceAll` and configures the
initializer to initialize all namespaces. kube-system, kube-public, and 
istio-system are exempt from initialization.

### _initializerName_

This must match the name of the initializer in the
InitializerConfiguration. The initializer only processes workloads
that match its configured name.

### _params_

These parameters allow you to make limited changes to the injected sidecar
proxy. Changing these values will not affect already deployed
workloads.

## Cleanup

```bash
kubectl delete -f install/kubernetes/istio-initializer.yaml
```
