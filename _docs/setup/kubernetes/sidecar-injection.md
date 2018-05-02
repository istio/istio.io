---
title: Installing the Istio Sidecar
description: Instructions for installing the Istio sidecar in application pods automatically using the sidecar injector webhook or manually using istioctl CLI.

weight: 50

---
{% include home.html %}

> The following requires Istio 0.5 or greater. See
> [https://archive.istio.io/v0.4/docs/setup/kubernetes/sidecar-injection](https://archive.istio.io/v0.4/docs/setup/kubernetes/sidecar-injection)
> for Istio 0.4 or prior.
>
> In previous releases, the Kubernetes initializer feature was used for automatic proxy injection. This was an Alpha feature, subject to change/removal,
> and not enabled by default in Kubernetes. Starting in Kubernetes 1.9 it was replaced by a beta feature called
> [mutating webhooks](https://kubernetes.io/docs/admin/admission-controllers/#mutatingadmissionwebhook-beta-in-19), which is now enabled by default in
> Kubernetes 1.9 and beyond. Starting with Istio 0.5.0 the automatic proxy injection uses mutating webhooks, and support for injection by initializer has been
> removed. Users who cannot upgrade to Kubernetes 1.9 should use manual injection.

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
  CLI tool or automatically using the Istio Initializer.  Note that the
  sidecar is not involved in traffic between containers in the same pod.

## Injection

Manual injection modifies the controller configuration, e.g. deployment. It
does this by modifying the pod template spec such that *all* pods for that
deployment are created with the injected sidecar. Adding/Updating/Removing
the sidecar requires modifying the entire deployment.

Automatic injection injects at pod creation time. The controller resource is
unmodified. Sidecars can be updated selectively by manually deleting a pods or
systematically with a deployment rolling update.

Manual and automatic injection use the same templated configuration. Automatic
injection loads the configuration from the `istio-inject` ConfigMap in the
`istio-system` namespace. Manual injection can load from a local file or from
the ConfigMap.

Two variants of the injection configuration are provided with the default
install: `istio-sidecar-injector-configmap-release.yaml`
and `istio-sidecar-injector-configmap-debug.yaml`. The injection configmap includes
the default injection policy and sidecar injection template. The debug version
includes debug proxy images and additional logging and core dump functionality used
for debugging the sidecar proxy.

### Manual sidecar injection

Use the built-in defaults template and dynamically fetch the mesh
configuration from the `istio` ConfigMap. Additional parameter overrides
are available via flags (see `istioctl kube-inject --help`).

```command
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
```

`kube-inject` can also be run without access to a running Kubernetes
cluster. Create local copies of the injection and mesh configmap.

```command
$ kubectl create -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml \
    --dry-run \
    -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
```

Run `kube-inject` over the input file.

```command
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename samples/sleep/sleep.yaml \
    --output sleep-injected.yaml
```

Deploy the injected YAML file.

```command
$ kubectl apply -f sleep-injected.yaml
```

Verify that the sidecar has been injected into the deployment.

```command
$ kubectl get deployment sleep -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS          IMAGES                             SELECTOR
sleep     1         1         1            1           2h        sleep,istio-proxy   tutum/curl,unknown/proxy:unknown   app=sleep
```

### Automatic sidecar injection

Sidecars can be automatically added to applicable Kubernetes pods using a
[mutating webhook admission controller](https://kubernetes.io/docs/admin/admission-controllers/#validatingadmissionwebhook-alpha-in-18-beta-in-19). This feature requires Kubernetes 1.9 or later. Verify that the kube-apiserver process has the `admission-control` flag set with the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers added and listed in the correct order and the admissionregistration API is enabled.

```command
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1beta1
admissionregistration.k8s.io/v2beta2
```

See the Kubernetes [quick start]({{home}}/docs/setup/kubernetes/quick-start.html) guide for instructions on installing Kubernetes version >= 1.9.

Note that unlike manual injection, automatic injection occurs at the pod-level. You won't see any change to the deployment itself. Instead you'll want to check individual pods (via `kubectl describe`) to see the injected proxy.

#### Installing the webhook

To enable the sidecar injection webhook, you can use [Helm]({{home}}/docs/setup/kubernetes/helm-install.html)
to install Istio with the option sidecar-injector.enabled set to true. E.g.

```command
$ helm install --namespace=istio-system --set sidecar-injector.enabled=true install/kubernetes/helm/istio
```

Alternatively, you can also use Helm to generate the yaml file and install it manually. E.g.

```command
$ helm template --namespace=istio-system --set sidecar-injector.enabled=true install/kubernetes/helm/istio > istio.yaml
```

```command
$ kubectl apply -f istio.yaml
```

In addition, there are some other configuration parameters defined for sidecar
injector webhook service in `values.yaml`. You can override the default
values to customize the installation.

#### Deploying an app

Deploy sleep app. Verify both deployment and pod have a single container.

```command
$ kubectl apply -f samples/sleep/sleep.yaml
```
```command
$ kubectl get deployment -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES       SELECTOR
sleep     1         1         1            1           12m       sleep        tutum/curl   app=sleep
```

```command
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Running       0          4
```

Label the `default` namespace with `istio-injection=enabled`

```command
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection
NAME           STATUS    AGE       ISTIO-INJECTION
default        Active    1h        enabled
istio-system   Active    1h
kube-public    Active    1h
kube-system    Active    1h
```

Injection occurs at pod creation time. Kill the running pod and verify a new pod is created with the injected sidecar. The original pod has 1/1 READY containers and the pod with injected sidecar has 2/2 READY containers.

```command
$ kubectl delete pod sleep-776b7bcdcd-7hpnk
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
```

View detailed state of the injected pod. You should see the injected `istio-proxy` container and corresponding volumes. Be sure to substitute the correct name for the `Running` pod below.

```command
$ kubectl describe pod sleep-776b7bcdcd-bhn9m
```

Disable injection for the `default` namespace and verify new pods are created without the sidecar.

```command
$ kubectl label namespace default istio-injection-
$ kubectl delete pod sleep-776b7bcdcd-bhn9m
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
```

#### Understanding what happened

[admissionregistration.k8s.io/v1beta1#MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration)
configures when the webhook is invoked by Kubernetes. The default
supplied with Istio selects pods in namespaces with label `istio-injection=enabled`.
This can be changed by modifying the MutatingWebhookConfiguration in
`install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml`.

The `istio-inject` ConfigMap in the `istio-system` namespace the default
injection policy and sidecar injection template.

##### _**policy**_

`disabled` - The sidecar injector will not inject the sidecar into
pods by default. Add the `sidecar.istio.io/inject` annotation with
value `true` to the pod template spec to enable injection.

`enabled` - The sidecar injector will inject the sidecar into pods by
default. Add the `sidecar.istio.io/inject` annotation with
value `false` to the pod template spec to disable injection.

The following example uses the `sidecar.istio.io/inject` annotation to disable sidecar injection.

```yaml
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
```

##### _**template**_

The sidecar injection template uses [https://golang.org/pkg/text/template](https://golang.org/pkg/text/template) which,
when parsed and executed, is decoded to the following
struct containing the list of containers and volumes to inject into the pod.

```golang
type SidecarInjectionSpec struct {
      InitContainers []v1.Container `yaml:"initContainers"`
      Containers     []v1.Container `yaml:"containers"`
      Volumes        []v1.Volume    `yaml:"volumes"`
}
```

The template is applied to the following data structure at runtime.

```golang
type SidecarTemplateData struct {
    ObjectMeta  *metav1.ObjectMeta
    Spec        *v1.PodSpec
    ProxyConfig *meshconfig.ProxyConfig  // Defined by https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
    MeshConfig  *meshconfig.MeshConfig   // Defined by https://istio.io/docs/reference/config/service-mesh.html#meshconfig
}
```

`ObjectMeta` and `Spec` are from the pod. `ProxyConfig` and `MeshConfig`
are from the `istio` ConfigMap in the `istio-system` namespace. Templates can conditional
define injected containers and volumes with this data.

For example, the following template snippet from `install/kubernetes/istio-sidecar-injector-configmap-release.yaml`

{% raw %}
```yaml
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
```
{% endraw %}

expands to

```yaml
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
```

when applied over a pod defined by the pod template spec in [samples/sleep/sleep.yaml](https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml).

#### Uninstalling the webhook

```command
$ kubectl delete -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

The above command will not remove the injected sidecars from
Pods. A rolling update or simply deleting the pods and forcing
the deployment to create them is required.

Optionally, if may be also be desirable to clean-up other resources that were created in this task. This includes the secret holding the cert/key and CSR used to sign them, as well as any namespace that was labeled for injection.

```command
$ kubectl -n istio-system delete secret sidecar-injector-certs
$ kubectl delete csr istio-sidecar-injector.istio-system
$ kubectl label namespace default istio-injection-
```
