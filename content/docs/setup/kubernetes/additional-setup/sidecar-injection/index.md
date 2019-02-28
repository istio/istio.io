---
title: Installing the Sidecar
description: Instructions for installing the Istio sidecar in application pods automatically using the sidecar injector webhook or manually using istioctl CLI.
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /docs/setup/kubernetes/automatic-sidecar-inject.html
    - /docs/setup/kubernetes/sidecar-injection/
---

## Injection

Each pod in the mesh must be running an Istio compatible sidecar.

The following sections describe two
ways of injecting the Istio sidecar into a pod: manually using the `istioctl`
CLI tool or automatically using the Istio sidecar injector.

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
$ istioctl kube-inject -f @samples/sleep/sleep.yaml@ | kubectl apply -f -
{{< /text >}}

Alternatively, inject using local copies of the configuration.

{{< tip >}}
The `istioctl kube-inject` operation may not be repeated on the output
from a previous `kube-inject`.  The `kube-inject` operation is not idempotent.
For upgrade purposes, if using manual injection, it is recommended to keep
the original non-injected `yaml` file so that the data plane sidecars may be
updated.
{{< /tip >}}

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

Run `kube-inject` over the input file and deploy.

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename @samples/sleep/sleep.yaml@ \
    --output sleep-injected.yaml
$ kubectl apply -f sleep-injected.yaml
{{< /text >}}

Verify that the sidecar has been injected into the deployment.

{{< text bash >}}
$ kubectl get deployment sleep -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS          IMAGES                             SELECTOR
sleep     1         1         1            1           2h        sleep,istio-proxy   tutum/curl,unknown/proxy:unknown   app=sleep
{{< /text >}}

### Automatic sidecar injection

Sidecars can be automatically added to applicable Kubernetes pods using a
[mutating webhook admission controller](https://kubernetes.io/docs/admin/admission-controllers/). This feature requires Kubernetes 1.9 or later. Verify that the `kube-apiserver` process has the `admission-control` flag set with the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers added and listed in the correct order and the admissionregistration API is enabled.

{{< text bash >}}
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1alpha1
admissionregistration.k8s.io/v1beta1
{{< /text >}}

See [Kubernetes quick start](/docs/setup/kubernetes/install/kubernetes/) for instructions on installing Kubernetes version >= 1.9.

Note that unlike manual injection, automatic injection occurs at the pod-level. You won't see any change to the deployment itself. Instead you'll want to check individual pods (via `kubectl describe`) to see the injected proxy.

#### Disabling or updating the webhook

The sidecar injecting webhook is enabled by default. If you wish to disable the webhook, you can
use [Helm](/docs/setup/kubernetes/install/helm/) to generate an updated `istio.yaml`
with the option `sidecarInjectorWebhook.enabled` set to `false`. E.g.

{{< text bash >}}
$ helm template --namespace=istio-system --set sidecarInjectorWebhook.enabled=false install/kubernetes/helm/istio > istio.yaml
$ kubectl create ns istio-system
$ kubectl apply -f istio.yaml
{{< /text >}}

In addition, there are some other configuration parameters defined for the sidecar injector webhook
service in `values.yaml`. You can override the default values to customize the installation.

#### Deploying an app

Deploy sleep app. Verify both deployment and pod have a single container.

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
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

[admissionregistration.k8s.io/v1beta1#MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration-k8s-io)
configures when the webhook is invoked by Kubernetes. The default
supplied with Istio selects pods in namespaces with label
`istio-injection=enabled`.  The set of namespaces in which injection
is applied can be changed by editing the `MutatingWebhookConfiguration`
with `kubectl edit mutatingwebhookconfiguration
istio-sidecar-injector`.

{{< warning >}}
The sidecar injector pod(s) should be restarted after modifying the mutatingwebhookconfiguration.
{{< /warning >}}

The `istio-sidecar-injector` ConfigMap in the `istio-system` namespace has the default
injection policy and sidecar injection template.

##### _**policy**_

`disabled` - The sidecar injector will not inject the sidecar into
pods by default. Add the `sidecar.istio.io/inject` annotation with
value `true` to the pod template spec to override the default and enable injection.

`enabled` - The sidecar injector will inject the sidecar into pods by
default. Add the `sidecar.istio.io/inject` annotation with
value `false` to the pod template spec to override the default and disable injection.

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

when applied over a pod defined by the pod template spec in [`samples/sleep/sleep.yaml`]({{< github_tree >}}/samples/sleep/sleep.yaml)

#### More control: adding exceptions

There are cases where users do not have control of the pod creation, for instance, when they are created by someone else. Therefore they are unable to add the annotation `sidecar.istio.io/inject` in the pod, to explicitly instruct Istio whether to install the sidecar or not.

Think of auxiliary pods that might be created as an intermediate step while deploying an application. [OpenShift Builds](https://docs.okd.io/latest/dev_guide/builds/index.html), for example, creates such pods for building the source code of an application. Once the binary artifact is built, the application pod is ready to run and the auxiliary pods are discarded. Those intermediate pods should not get an Istio sidecar, even if the policy is set to `enabled` and the namespace is properly labeled to get automatic injection.

For such cases you can instruct Istio to **not** inject the sidecar on those pods, based on labels that are present in those pods. You can do this by editing the `istio-sidecar-injector` ConfigMap and adding the entry `neverInjectSelector`. It is an array of Kubernetes label selectors. They are `OR'd`, stopping at the first match. See an example:

{{< text yaml >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio-sidecar-injector
data:
  config: |-
    policy: enabled
    neverInjectSelector:
      - matchExpressions:
        - {key: openshift.io/build.name, operator: Exists}
      - matchExpressions:
        - {key: openshift.io/deployer-pod-for.name, operator: Exists}
    template: |-
      initContainers:
...
{{< /text >}}

The above statement means: Never inject on pods that have the label `openshift.io/build.name` **or** `openshift.io/deployer-pod-for.name` – the values of the labels don't matter, we are just checking if the keys exist. With this rule added, the OpenShift Builds use case illustrated above is covered, meaning auxiliary pods will not have sidecars injected (because source-to-image auxiliary pods **do** contain those labels).

For completeness, you can also use a field called `alwaysInjectSelector`, with similar syntax, which will always inject the sidecar on pods that match that label selector, regardless of the global policy.

The label selector approach gives a lot of flexibility on how to express those exceptions. Take a look at [these docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements) to see what you can do with them!

{{< tip >}}
It's worth noting that annotations in the pods have higher precedence than the label selectors. If a pod is annotated with `sidecar.istio.io/inject: "true/false"` then it will be honored. So, the order of evaluation is:

`Pod Annotations → NeverInjectSelector → AlwaysInjectSelector → Default Policy`
{{< /tip >}}

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
