---
title: Installing Istio Sidecar
overview: Instructions for installing the Istio sidecar in application pods automatically using the Istio initializer or manually using istioctl CLI.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

_NOTE_: the following requires Istio 0.5.0 or greater. See https://archive.istio.io/v0.4/docs/setup/kubernetes/sidecar-injection for versions 0.4.0 or older.

# Pod Spec Requirements

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
  
# Injection

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
includes debug proxy images and additional loggin and core dump functionality using 
for debugging the sidecar proxy. 

## Manual sidecar injection

`kube-inject` is designed to be run offline without access to a running Kubernetes
cluster. Create local copies of the injection and mesh configmap.


```
$ kubectl create -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml \
    -o=jsonpath='{.data.config}' > inject-config.yaml
    
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
```
  `
Run `kube-inject` over the input YAML file and save and deploy the injected YAML file.

```
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename samples/sleep/sleep.yaml \
    --output sleep-injected.yaml
$ kubectl apply -f sleep-injected.yaml    
```

Alternatively, this can be performed in a single step. This uses the built-in default template and dynamically fetches the mesh configuration from the `istio` ConfigMap. Additional parameter overrides are available via flags (see `istioctl kube-inject --help`).

```
kubectl apply -f <(~istioctl kube-inject -f samples/sleep/sleep.yaml)
```

Verify that the sidecar has been injected into the deployment.

```
$ kubectl get deployment sleep -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS          IMAGES                             SELECTOR
sleep     1         1         1            1           2h        sleep,istio-proxy   tutum/curl,unknown/proxy:unknown   app=sleep
```

## Automatic sidecar injection

See [validatingadmissionwebhook-alpha-in-18-beta-in-19](https://kubernetes.io/docs/admin/admission-controllers/#validatingadmissionwebhook-alpha-in-18-beta-in-19) for overview of webhook admission controller.

### Prerequisites

Kubernetes 1.9 cluster is required with `admissionregistration.k8s.io/v1beta1` enabled.

```
$ kubectl api-versions | grep admissionregistration.k8s.io/v1beta1
admissionregistration.k8s.io/v1beta1
```

#### GKE

1.9.1 is available for non-whitelisted early access users with alpha clusters (see https://cloud.google.com/kubernetes-engine/release-notes#january-16-2018). 

```bash
gcloud container clusters create <cluster-name> \
    --enable-kubernetes-alpha 
    --cluster-version=1.9.1-gke.0 
    --zone=<zone>
    --project <project-name>
    
gcloud container clusters get-credentials <cluster-name> \
    --zone <zone> \
    --project <project-name>
    
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)
```

#### minikube 

TODO(https://github.com/istio/istio.github.io/issues/885)

#### IBM Cloud Container Service

TODO(https://github.com/istio/istio.github.io/issues/887)

#### AWS with Kops

TODO(https://github.com/istio/istio.github.io/issues/886)

### Installing the Webhook 

Install base Istio.

```
$ kubectl apply -f install/kubernetes/istio.yaml
```

Webhooks requires a signed cert/key pair. Use `install/kubernetes/webhook-create-signed-cert.sh` to generate 
a cert/key pair signed by the Kubernetes' CA. The resulting cert/key file is stored as a Kubernetes 
secret for the sidecar injector webhook to consume.

_Note_: Kubernetes CA approval requires permissions to create and approve CSR. See 
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster and 
`install/kubernetes/webhook-create-signed-cert.sh` for more information.

```
$ ./install/kubernetes/webhook-create-signed-cert.sh \
    --service istio-sidecar-injector \
    --namespace istio-system \
    --secret sidecar-injector-certs
```

Install the sidecar injection configmap. 

```
$ kubectl apply -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml
```

Set the `caBundle` in the webhook install YAML that the Kubernetes api-server 
uses to invoke the webhook. 

```
$ cat install/kubernetes/istio-sidecar-injector.yaml | \
     ./install/kubernetes/webhook-patch-ca-bundle.sh > \
     install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

Install the sidecar injector webhook.

```
$ kubectl apply -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

The sidecar injector webhook should now be running.

```
$ kubectl -n istio-system get deployment -listio=sidecar-injector
NAME                     DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-sidecar-injector   1         1         1            1           1d
```

NamespaceSelector decides whether to run the webhook on an object based on whether the namespace for that object matches the selector (see https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors). The default webhook configuration uses `istio-injection=enabled`. 

View namespaces showing `istio-injection` label and verify the `default` namespace is not labeled.

```
$ kubectl get namespace -L istio-injection
NAME           STATUS        AGE       ISTIO-INJECTION
default        Active        1h        
istio-system   Active        1h        
kube-public    Active        1h        
kube-system    Active        1h
```

#### Deploying an app

Deploy sleep app. Verify both deployment and pod have a single container.

```
$ kubectl apply -f samples/sleep/sleep.yaml 

$ kubectl get deployment -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES       SELECTOR
sleep     1         1         1            1           12m       sleep        tutum/curl   app=sleep

$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Running       0          4
```

Label `default` namespace with `istio-injection=enabled`

```
$ kubectl label namespace default istio-injection=enabled

$ kubectl get namespace -L istio-injection
NAME           STATUS    AGE       ISTIO-INJECTION
default        Active    1h        enabled
istio-system   Active    1h        
kube-public    Active    1h        
kube-system    Active    1h  
```

Injection occurs at pod creation time. Kill the running pod and verify a new pod is created with the injected sidecar.

```
$ kubectl delete pod sleep-776b7bcdcd-7hpnk 

$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
```

Disable injection for the `default` namespace and verify new pods are created without the sidecar.

```
$ kubectl label namespace default istio-injection

$ kubectl delete pod sleep-776b7bcdcd-bhn9m 

$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
```

#### Understanding what happened

[admissionregistration.k8s.io/v1alpha1#MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.9/#mutatingwebhookconfiguration-v1beta1-admissionregistration) 
configures when the webhook is invoked by Kubernetes. The default 
supplied with Istio selects pods in namespaces with label `istio-injection=enabled`. 
This can be changed by modifying the MutatingWebhookConfiguration 
`install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml`.

The `istio-inject` ConfigMap in `istio-system` contains the default 
injection policy and sidecar injection template.

1. _**policy**_
    
`disabled` - The sidecar injector will not inject the sidecar into
pods by default. Pods can enable injection using the `sidecar.istio.io/inject` 
annotation with value of `true`.
   
`enabled` - The sidecar injector will inject the sidecar into pods by
default. Pods can disable injection using the `sidecar.istio.io/inject`
annotation with value of `false`.
    
2. _**template**_
   
The sidecar injection template uses https://golang.org/pkg/text/template which, 
when parsed and exectuted, is decoded to the following 
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
    ObjectMeta  *metav1.ObjectMeta       // 
	  Spec        *v1.PodSpec              // 
	  ProxyConfig *meshconfig.ProxyConfig  // Defined by https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
	  MeshConfig  *meshconfig.MeshConfig   // Defined by https://istio.io/docs/reference/config/service-mesh.html#meshconfig 
}
```

`ObjectMeta` and `Spec` are from the to-be-injected Pod. `ProxyConfig` and `MeshConfig` 
are from the `istio` ConfigMap in the `istio-system` namespace. Templates can conditional 
define injected containers/volumes based on per-pod values. 

For example, the following template snippet from install/kubernetes/istio-sidecar-injector-configmap-release.yaml

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

```
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
 
when applied over a pod defined by the pod template spec in `sample/sleep/sleep.yaml`.

### Uninstalling the webhook

```
$ kubectl delete -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

The above command will not remove the injected sidecars from
Pods. A rolling update or simply deleting the pods and forcing
the deployment to create them is required.


