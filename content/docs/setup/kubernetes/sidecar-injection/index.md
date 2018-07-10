---
title: Installing the Istio sidecar
description: Instructions for installing the Istio sidecar in application pods automatically using the sidecar injector webhook or manually using istioctl CLI.
weight: 50
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /docs/setup/kubernetes/automatic-sidecar-inject.html
---

## Pod spec requirements

In order to be a part of the service mesh, each pod in the Kubernetes
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
  CLI tool or automatically using the Istio sidecar injector.  Note that the
  sidecar is not involved in traffic between containers in the same pod.

## Injection

Manual injection modifies the controller configuration, e.g. deployment. It
does this by modifying the pod template spec such that *all* pods for that
deployment are created with the injected sidecar. Adding/Updating/Removing
the sidecar requires modifying the entire deployment.

Automatic injection injects at pod creation time. The controller resource is
unmodified. Sidecars can be updated selectively by manually deleting a pods or
systematically with a deployment rolling update.

Manual and automatic injection both use the configuration from the
`istio-sidecar-injector` and `istio` ConfigMaps in the `istio-system`
namespace.  Manual injection can also optionally load configuration
from local files.

### Manual sidecar injection

Inject the sidecar into the deployment using the in-cluster configuration.

{{< text bash >}}
$ istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl apply -f -
{{< /text >}}

Alternatively, inject using local copies of the configuration.

> The `istioctl kube-inject` operation may not be repeated on the output
> from a previous `kube-inject`.  The `kube-inject` operation is not idempotent.
> For upgrade purposes, if using manual injection, it is recommended to keep
> the original non-injected `yaml` file so that the dataplane sidecars may be
> updated.

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

Run `kube-inject` over the input file and deploy.

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename samples/sleep/sleep.yaml \
    --output sleep-injected.yaml | kubectl apply -f -
{{< /text >}}

Verify that the sidecar has been injected into the deployment.

{{< text bash >}}
$ kubectl get deployment sleep -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS          IMAGES                             SELECTOR
sleep     1         1         1            1           2h        sleep,istio-proxy   tutum/curl,unknown/proxy:unknown   app=sleep
{{< /text >}}

### Automatic sidecar injection

Sidecars can be automatically added to applicable Kubernetes pods using a
[mutating webhook admission controller](https://kubernetes.io/docs/admin/admission-controllers/#validatingadmissionwebhook-alpha-in-18-beta-in-19). This feature requires Kubernetes 1.9 or later. Verify that the kube-apiserver process has the `admission-control` flag set with the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers added and listed in the correct order and the admissionregistration API is enabled.

{{< text bash >}}
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1alpha1
admissionregistration.k8s.io/v1beta1
{{< /text >}}

See [Kubernetes quick start](/docs/setup/kubernetes/quick-start/) for instructions on installing Kubernetes version >= 1.9.

Note that unlike manual injection, automatic injection occurs at the pod-level. You won't see any change to the deployment itself. Instead you'll want to check individual pods (via `kubectl describe`) to see the injected proxy.

#### Disabling or updating the webhook

The sidecar injecting webhook is enabled by default. If you wish to disable the webhook, you can
use [Helm](/docs/setup/kubernetes/helm-install/) to generate an updated istio.yaml
with the option `sidecarInjectorWebhook.enabled` set to `false`. E.g.

{{< text bash >}}
$ helm template --namespace=istio-system --set sidecarInjectorWebhook.enabled=false install/kubernetes/helm/istio > istio.yaml
$ kubectl create ns istio-system
$ kubectl apply -n istio-system -f istio.yaml
{{< /text >}}

In addition, there are some other configuration parameters defined for the sidecar injector webhook
service in `values.yaml`. You can override the default values to customize the installation.

#### Deploying an app

Deploy sleep app. Verify both deployment and pod have a single container.

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl get deployment -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES       SELECTOR
sleep     1         1         1            1           12m       sleep        tutum/curl   app=sleep
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Running       0          4
{{< /text >}}

Label the `default` namespace with `istio-injection=enabled`

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection
NAME           STATUS    AGE       ISTIO-INJECTION
default        Active    1h        enabled
istio-system   Active    1h
kube-public    Active    1h
kube-system    Active    1h
{{< /text >}}

Injection occurs at pod creation time. Kill the running pod and verify a new pod is created with the injected sidecar. The original pod has 1&#47;1 READY containers and the pod with injected sidecar has 2&#47;2 READY containers.

{{< text bash >}}
$ kubectl delete pod sleep-776b7bcdcd-7hpnk
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
{{< /text >}}

View detailed state of the injected pod. You should see the injected `istio-proxy` container and corresponding volumes. Be sure to substitute the correct name for the `Running` pod below.

{{< text bash >}}
$ kubectl describe pod sleep-776b7bcdcd-bhn9m
{{< /text >}}

Disable injection for the `default` namespace and verify new pods are created without the sidecar.

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod sleep-776b7bcdcd-bhn9m
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
{{< /text >}}

#### Understanding what happened

[admissionregistration.k8s.io/v1beta1#MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration)
configures when the webhook is invoked by Kubernetes. The default
supplied with Istio selects pods in namespaces with label
`istio-injection=enabled`.  The set of namespaces in which injection
is applied can be changed by editing the MutatingWebhookConfiguration
with `kubectl edit mutatingwebhookconfiguration
istio-sidecar-injector`.

> {{< warning_icon >}} The sidecar injector pod(s) should be restarted after modifying the mutatingwebhookconfiguration.

The `istio-sidecar-injector` ConfigMap in the `istio-system` namespace has the default
injection policy and sidecar injection template.

##### _**policy**_

`disabled` - The sidecar injector will not inject the sidecar into
pods by default. Add the `sidecar.istio.io/inject` annotation with
value `true` to the pod template spec to enable injection.

`enabled` - The sidecar injector will inject the sidecar into pods by
default. Add the `sidecar.istio.io/inject` annotation with
value `false` to the pod template spec to disable injection.

The following example uses the `sidecar.istio.io/inject` annotation to disable sidecar injection.

{{< text yaml >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ignored
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: ignored
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
{{< /text >}}

##### _**template**_

The sidecar injection template uses [https://golang.org/pkg/text/template](https://golang.org/pkg/text/template) which,
when parsed and executed, is decoded to the following
struct containing the list of containers and volumes to inject into the pod.

{{< text go >}}
type SidecarInjectionSpec struct {
      InitContainers   []v1.Container `yaml:"initContainers"`
      Containers       []v1.Container `yaml:"containers"`
      Volumes          []v1.Volume    `yaml:"volumes"`
      ImagePullSecrets []corev1.LocalObjectReference `yaml:"imagePullSecrets"`
}
{{< /text >}}

The template is applied to the following data structure at runtime.

{{< text go >}}
type SidecarTemplateData struct {
    ObjectMeta  *metav1.ObjectMeta
    Spec        *v1.PodSpec
    ProxyConfig *meshconfig.ProxyConfig  // Defined by https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
    MeshConfig  *meshconfig.MeshConfig   // Defined by https://istio.io/docs/reference/config/service-mesh.html#meshconfig
}
{{< /text >}}

`ObjectMeta` and `Spec` are from the pod. `ProxyConfig` and `MeshConfig`
are from the `istio` ConfigMap in the `istio-system` namespace. Templates can conditional
define injected containers and volumes with this data.

For example, the following template snippet from `install/kubernetes/istio-sidecar-injector-configmap-release.yaml`

{{< text plain >}}
containers:
- name: istio-proxy
  image: istio.io/proxy:0.5.0
  args:
  - proxy
  - sidecar
  - --configPath
  - {{ .ProxyConfig.ConfigPath }}
  - --binaryPath
  - {{ .ProxyConfig.BinaryPath }}
  - --serviceCluster
  {{ if ne "" (index .ObjectMeta.Labels "app") -}}
  - {{ index .ObjectMeta.Labels "app" }}
  {{ else -}}
  - "istio-proxy"
  {{ end -}}
{{< /text >}}

expands to

{{< text yaml >}}
containers:
- name: istio-proxy
  image: istio.io/proxy:0.5.0
  args:
  - proxy
  - sidecar
  - --configPath
  - /etc/istio/proxy
  - --binaryPath
  - /usr/local/bin/envoy
  - --serviceCluster
  - sleep
{{< /text >}}

when applied over a pod defined by the pod template spec in `samples/sleep/sleep.yaml`

#### Uninstalling the automatic sidecar injector

{{< text bash >}}
$ kubectl delete mutatingwebhookconfiguration istio-sidecar-injector
$ kubectl -n istio-system delete service istio-sidecar-injector
$ kubectl -n istio-system delete deployment istio-sidecar-injector
$ kubectl -n istio-system delete serviceaccount istio-sidecar-injector-service-account
$ kubectl delete clusterrole istio-sidecar-injector-istio-system
$ kubectl delete clusterrolebinding istio-sidecar-injector-admin-role-binding-istio-system
{{< /text >}}

The above command will not remove the injected sidecars from Pods. A
rolling update or simply deleting the pods and forcing the deployment
to create them is required.

Optionally, it may also be desirable to clean-up other resources that
were modified in this task.

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
