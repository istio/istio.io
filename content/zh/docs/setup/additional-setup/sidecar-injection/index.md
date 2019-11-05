---
title: Installing the Sidecar
description: Install the Istio sidecar in application pods automatically using the sidecar injector webhook or manually using istioctl CLI.
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /docs/setup/kubernetes/automatic-sidecar-inject.html
    - /docs/setup/kubernetes/sidecar-injection/
    - /docs/setup/kubernetes/additional-setup/sidecar-injection/
---

## Injection

In order to take advantage of all of Istio's features, pods in the mesh must be running an Istio sidecar proxy.

The following sections describe two
ways of injecting the Istio sidecar into a pod: manually using the [`istioctl`](/docs/reference/commands/istioctl)
command or automatically using the Istio sidecar injector.

Manual injection directly modifies configuration, like deployments, and injects the proxy configuration into it.

Automatic injection injects at pod creation time using an admission controller.

Injection occurs by applying a template defined in the `istio-sidecar-injector` ConfigMap.

### Manual sidecar injection

To manually inject a deployment, use [`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject):

{{< text bash >}}
$ istioctl kube-inject -f @samples/sleep/sleep.yaml@ | kubectl apply -f -
{{< /text >}}

By default, this will use the in-cluster configuration. Alternatively, injection can be done using local copies of the configuration.

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.values}' > inject-values.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

Run `kube-inject` over the input file and deploy.

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --valuesFile inject-values.yaml \
    --filename @samples/sleep/sleep.yaml@ \
    | kubectl apply -f -
{{< /text >}}

Verify that the sidecar has been injected into the sleep pod with `2/2` under the READY column.

{{< text bash >}}
$ kubectl get pod  -l app=sleep
NAME                     READY   STATUS    RESTARTS   AGE
sleep-64c6f57bc8-f5n4x   2/2     Running   0          24s
{{< /text >}}

### Automatic sidecar injection

Sidecars can be automatically added to applicable Kubernetes pods using a
[mutating webhook admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) provided by Istio.

{{< tip >}}
While admission controllers are enabled by default, some Kubernetes distributions may disable them. If this is the case, follow the instructions to [turn on admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller).
{{< /tip >}}

When the injection webhook is enabled, any new pods that are created will automatically have a sidecar added to them.

Note that unlike manual injection, automatic injection occurs at the pod-level. You won't see any change to the deployment itself. Instead you'll want to check individual pods (via `kubectl describe`) to see the injected proxy.

#### Disabling or updating the webhook

The sidecar injecting webhook is enabled by default. If you wish to disable the webhook, you can
use [Helm](/docs/setup/install/helm/) to set option `sidecarInjectorWebhook.enabled` to `false`.

There are also a [variety of other options](/docs/reference/config/installation-options/#sidecarinjectorwebhook-options) that can be configured.

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
$ kubectl delete pod -l app=sleep
$ kubectl get pod -l app=sleep
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
{{< /text >}}

View detailed state of the injected pod. You should see the injected `istio-proxy` container and corresponding volumes. Be sure to substitute the correct name for the `Running` pod below.

{{< text bash >}}
$ kubectl describe pod -l app=sleep
{{< /text >}}

Disable injection for the `default` namespace and verify new pods are created without the sidecar.

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=sleep
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
{{< /text >}}

#### Understanding what happened

When Kubernetes invokes the webhook, the [`admissionregistration`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration-k8s-io)
configuration is applied. The default configuration injects the sidecar into
pods in any namespace with the `istio-injection=enabled label`. The
`istio-sidecar-injector` configuration map specifies the configuration for the
injected sidecar. To change how namespaces are selected for injection, you can
edit the `MutatingWebhookConfiguration` with the following command:

{{< text bash >}}
$ kubectl edit mutatingwebhookconfiguration istio-sidecar-injector
{{< /text >}}

{{< warning >}}
You should restart the sidecar injector pod(s) after modifying
the `MutatingWebhookConfiguration`.
{{< /warning >}}

For example, you can modify the `MutatingWebhookConfiguration` to always inject
the sidecar into every namespace, unless a label is set. Editing this
configuration is an advanced operation. Refer to the Kubernetes documentation
for the [`MutatingWebhookConfiguration` API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration-k8s-io)
for more information.

##### _**policy**_

`disabled` - The sidecar injector will not inject the sidecar into
pods by default. Add the `sidecar.istio.io/inject` annotation with
value `true` to the pod template spec to override the default and enable injection.

`enabled` - The sidecar injector will inject the sidecar into pods by
default. Add the `sidecar.istio.io/inject` annotation with
value `false` to the pod template spec to override the default and disable injection.

The following example uses the `sidecar.istio.io/inject` annotation to disable sidecar injection.

{{< text yaml >}}
apiVersion: apps/v1
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
      RewriteAppHTTPProbe bool                          `yaml:"rewriteAppHTTPProbe"`
      InitContainers      []corev1.Container            `yaml:"initContainers"`
      Containers          []corev1.Container            `yaml:"containers"`
      Volumes             []corev1.Volume               `yaml:"volumes"`
      DNSConfig           *corev1.PodDNSConfig          `yaml:"dnsConfig"`
      ImagePullSecrets    []corev1.LocalObjectReference `yaml:"imagePullSecrets"`
}
{{< /text >}}

The template is applied to the following data structure at runtime.

{{< text go >}}
type SidecarTemplateData struct {
    DeploymentMeta *metav1.ObjectMeta
    ObjectMeta     *metav1.ObjectMeta
    Spec           *corev1.PodSpec
    ProxyConfig    *meshconfig.ProxyConfig  // Defined by https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
    MeshConfig     *meshconfig.MeshConfig   // Defined by https://istio.io/docs/reference/config/service-mesh.html#meshconfig
}
{{< /text >}}

`ObjectMeta` and `Spec` are from the pod. `ProxyConfig` and `MeshConfig`
are from the `istio` ConfigMap in the `istio-system` namespace. Templates can conditionally
define injected containers and volumes with this data.

For example, the following template

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
