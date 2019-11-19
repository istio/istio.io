---
title: Demystifying Istio's Sidecar Injection Model
description: De-mystify how Istio manages to plugin its data-plane components into an existing deployment.
publishdate: 2019-01-31
subtitle:
attribution: Manish Chugtu
twitter: chugtum
keywords: [kubernetes,sidecar-injection, traffic-management]
target_release: 1.0
---
A simple overview of an Istio service-mesh architecture always starts with describing the control-plane and data-plane.

[From Istio’s documentation:](/docs/ops/architecture/)

{{< quote >}}
An Istio service mesh is logically split into a data plane and a control plane.

The data plane is composed of a set of intelligent proxies (Envoy) deployed as sidecars. These proxies mediate and control all network communication between microservices along with Mixer, a general-purpose policy and telemetry hub.

The control plane manages and configures the proxies to route traffic. Additionally, the control plane configures Mixers to enforce policies and collect telemetry.
{{< /quote >}}

{{< image width="40%"
    link="./arch-2.svg"
    alt="The overall architecture of an Istio-based application."
    caption="Istio Architecture"
    >}}

It is important to understand that the sidecar injection into the application pods happens automatically, though manual injection is also possible. Traffic is directed from the application services to and from these sidecars without developers needing to worry about it. Once the applications are connected to the Istio service mesh, developers can start using and reaping the benefits of all that the service mesh has to offer. However, how does the data plane plumbing happen and what is really required to make it work seamlessly? In this post, we will deep-dive into the specifics of the sidecar injection models to gain a very clear understanding of how sidecar injection works.

## Sidecar injection

In simple terms, sidecar injection is adding the configuration of additional containers to the pod template. The added containers needed for the Istio service mesh are:

`istio-init`
This [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) is used to setup the `iptables` rules so that inbound/outbound traffic will go through the sidecar proxy. An init container is different than an app container in following ways:

- It runs before an app container is started and it always runs to completion.
- If there are many init containers, each should complete with success before the next container is started.

So, you can see how this type of container is perfect for a set-up or initialization job which does not need to be a part of the actual application container. In this case, `istio-init` does just that and sets up the `iptables` rules.

`istio-proxy`
This is the actual sidecar proxy (based on Envoy).

### Manual injection

In the manual injection method, you can use [`istioctl`](/docs/reference/commands/istioctl) to modify the pod template and add the configuration of the two containers previously mentioned. For both manual as well as automatic injection, Istio takes the configuration from the `istio-sidecar-injector` configuration map (configmap) and the mesh's `istio` configmap.

Let’s look at the configuration of the `istio-sidecar-injector` configmap, to get an idea of what actually is going on.

{{< text bash yaml>}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
SNIPPET from the output:

policy: enabled
template: |-
  initContainers:
  - name: istio-init
    image: docker.io/istio/proxy_init:1.0.2
    args:
    - "-p"
    - [[ .MeshConfig.ProxyListenPort ]]
    - "-u"
    - 1337
    .....
    imagePullPolicy: IfNotPresent
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
    restartPolicy: Always

  containers:
  - name: istio-proxy
    image: [[ if (isset .ObjectMeta.Annotations "sidecar.istio.io/proxyImage") -]]
    "[[ index .ObjectMeta.Annotations "sidecar.istio.io/proxyImage" ]]"
    [[ else -]]
    docker.io/istio/proxyv2:1.0.2
    [[ end -]]
    args:
    - proxy
    - sidecar
    .....
    env:
    .....
    - name: ISTIO_META_INTERCEPTION_MODE
      value: [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String ]]
    imagePullPolicy: IfNotPresent
    securityContext:
      readOnlyRootFilesystem: true
      [[ if eq (or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String) "TPROXY" -]]
      capabilities:
        add:
        - NET_ADMIN
    restartPolicy: Always
    .....
{{< /text >}}

As you can see, the configmap contains the configuration for both, the `istio-init` init container and the `istio-proxy` proxy container. The configuration includes the name of the container image and arguments like interception mode, capabilities, etc.

From a security point of view, it is important to note that `istio-init` requires `NET_ADMIN` capabilities to modify `iptables` within the pod's namespace and so does `istio-proxy` if configured in `TPROXY` mode. As this is restricted to a pod's namespace, there should be no problem. However, I have noticed that recent open-shift versions may have some issues with it and a workaround is needed. One such option is mentioned at the end of this post.

To modify the current pod template for sidecar injection, you can:

{{< text bash >}}
$ istioctl kube-inject -f demo-red.yaml | kubectl apply -f -
{{< /text >}}

OR

To use modified configmaps or local configmaps:

- Create `inject-config.yaml` and `mesh-config.yaml` from the configmaps

    {{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
    {{< /text >}}

- Modify the existing pod template, in my case, `demo-red.yaml`:

    {{< text bash >}}
$ istioctl kube-inject --injectConfigFile inject-config.yaml --meshConfigFile mesh-config.yaml --filename demo-red.yaml --output demo-red-injected.yaml
    {{< /text >}}

- Apply the `demo-red-injected.yaml`

    {{< text bash >}}
$ kubectl apply -f demo-red-injected.yaml
    {{< /text >}}

As seen above, we create a new template using the `sidecar-injector` and the mesh configuration to then apply that new template using `kubectl`. If we look at the injected YAML file, it has the configuration of the Istio-specific containers, as we discussed above. Once we apply the injected YAML file, we see two containers running. One of them is the actual application container, and the other is the `istio-proxy` sidecar.

{{< text bash >}}
    $ kubectl get pods | grep demo-red
    demo-red-pod-8b5df99cc-pgnl7   2/2       Running   0          3d
{{< /text >}}

The count is not 3 because the `istio-init` container is an init type container that exits after doing what it supposed to do, which is setting up the `iptable` rules within the pod. To confirm the init container exit, let’s look at the output of `kubectl describe`:

{{< text bash yaml>}}
$ kubectl describe pod demo-red-pod-8b5df99cc-pgnl7
SNIPPET from the output:

Name:               demo-red-pod-8b5df99cc-pgnl7
Namespace:          default
.....
Labels:             app=demo-red
                    pod-template-hash=8b5df99cc
                    version=version-red
Annotations:        sidecar.istio.io/status={"version":"3c0b8d11844e85232bc77ad85365487638ee3134c91edda28def191c086dc23e","initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs...
Status:             Running
IP:                 10.32.0.6
Controlled By:      ReplicaSet/demo-red-pod-8b5df99cc
Init Containers:
  istio-init:
    Container ID:  docker://bef731eae1eb3b6c9d926cacb497bb39a7d9796db49cd14a63014fc1a177d95b
    Image:         docker.io/istio/proxy_init:1.0.2
    Image ID:      docker-pullable://docker.io/istio/proxy_init@sha256:e16a0746f46cd45a9f63c27b9e09daff5432e33a2d80c8cc0956d7d63e2f9185
    .....
    State:          Terminated
      Reason:       Completed
    .....
    Ready:          True
Containers:
  demo-red:
    Container ID:   docker://8cd9957955ff7e534376eb6f28b56462099af6dfb8b9bc37aaf06e516175495e
    Image:          chugtum/blue-green-image:v3
    Image ID:       docker-pullable://docker.io/chugtum/blue-green-image@sha256:274756dbc215a6b2bd089c10de24fcece296f4c940067ac1a9b4aea67cf815db
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
  istio-proxy:
    Container ID:  docker://ca5d690be8cd6557419cc19ec4e76163c14aed2336eaad7ebf17dd46ca188b4a
    Image:         docker.io/istio/proxyv2:1.0.2
    Image ID:      docker-pullable://docker.io/istio/proxyv2@sha256:54e206530ba6ca9b3820254454e01b7592e9f986d27a5640b6c03704b3b68332
    Args:
      proxy
      sidecar
      .....
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
    .....
{{< /text >}}

As seen in the output, the `State` of the `istio-init` container is `Terminated` with the `Reason` being `Completed`. The only two containers running are the main application `demo-red` container and the `istio-proxy` container.

### Automatic injection

Most of the times, you don’t want to manually inject a sidecar every time you deploy an application, using the [`istioctl`](/docs/reference/commands/istioctl) command, but would prefer that Istio automatically inject the sidecar to your pod. This is the recommended approach and for it to work, all you need to do is to label the namespace where you are deploying the app with `istio-injection=enabled`.

Once labeled, Istio injects the sidecar automatically for any pod you deploy in that namespace. In the following example, the sidecar gets automatically injected in the deployed pods in the `istio-dev` namespace.

{{< text bash >}}
$ kubectl get namespaces --show-labels
NAME           STATUS    AGE       LABELS
default        Active    40d       <none>
istio-dev      Active    19d       istio-injection=enabled
istio-system   Active    24d       <none>
kube-public    Active    40d       <none>
kube-system    Active    40d       <none>
{{< /text >}}

But how does this work? To get to the bottom of this, we need to understand Kubernetes admission controllers.

[From Kubernetes documentation:](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

{{< tip >}}
An admission controller is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object, but after the request is authenticated and authorized. You can define two types of admission webhooks, validating admission Webhook and mutating admission webhook. With validating admission Webhooks, you may reject requests to enforce custom admission policies. With mutating admission Webhooks, you may change requests to enforce custom defaults.
{{< /tip >}}

For automatic sidecar injection, Istio relies on `Mutating Admission Webhook`. Let’s look at the details of the  `istio-sidecar-injector` mutating webhook configuration.

{{< text bash yaml >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml
SNIPPET from the output:

apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"admissionregistration.k8s.io/v1beta1","kind":"MutatingWebhookConfiguration","metadata":{"annotations":{},"labels":{"app":"istio-sidecar-injector","chart":"sidecarInjectorWebhook-1.0.1","heritage":"Tiller","release":"istio-remote"},"name":"istio-sidecar-injector","namespace":""},"webhooks":[{"clientConfig":{"caBundle":"","service":{"name":"istio-sidecar-injector","namespace":"istio-system","path":"/inject"}},"failurePolicy":"Fail","name":"sidecar-injector.istio.io","namespaceSelector":{"matchLabels":{"istio-injection":"enabled"}},"rules":[{"apiGroups":[""],"apiVersions":["v1"],"operations":["CREATE"],"resources":["pods"]}]}]}
  creationTimestamp: 2018-12-10T08:40:15Z
  generation: 2
  labels:
    app: istio-sidecar-injector
    chart: sidecarInjectorWebhook-1.0.1
    heritage: Tiller
    release: istio-remote
  name: istio-sidecar-injector
  .....
webhooks:
- clientConfig:
    service:
      name: istio-sidecar-injector
      namespace: istio-system
      path: /inject
  name: sidecar-injector.istio.io
  namespaceSelector:
    matchLabels:
      istio-injection: enabled
  rules:
  - apiGroups:
    - ""
    apiVersions:
    - v1
    operations:
    - CREATE
    resources:
    - pods
{{< /text >}}

This is where you can see the webhook `namespaceSelector` label that is matched for sidecar injection with the label `istio-injection: enabled`. In this case, you also see the operations and resources for which this is done when the pods are created. When an `apiserver` receives a request that matches one of the rules, the `apiserver` sends an admission review request to the webhook service as specified in the `clientConfig:`configuration with the `name: istio-sidecar-injector` key-value pair. We should be able to see that this service is running in the `istio-system` namespace.

{{< text bash >}}
$ kubectl get svc --namespace=istio-system | grep sidecar-injector
istio-sidecar-injector   ClusterIP   10.102.70.184   <none>        443/TCP             24d
{{< /text >}}

This configuration ultimately does pretty much the same as we saw in manual injection. Just that it is done automatically during pod creation, so you won’t see the change in the deployment. You need to use `kubectl describe` to see the sidecar proxy and the init proxy.

The automatic sidecar injection not only depends on the `namespaceSelector` mechanism of the webhook, but also on the default injection policy and the per-pod override annotation.

If you look at the `istio-sidecar-injector` ConfigMap again, it has the default injection policy defined. In our case, it is enabled by default.

{{< text bash yaml>}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
SNIPPET from the output:

policy: enabled
template: |-
  initContainers:
  - name: istio-init
    image: "gcr.io/istio-release/proxy_init:1.0.2"
    args:
    - "-p"
    - [[ .MeshConfig.ProxyListenPort ]]
{{< /text >}}

You can also use the annotation `sidecar.istio.io/inject` in the pod template to override the default policy. The following example disables the automatic injection of the sidecar for the pods in a `Deployment`.

{{< text yaml>}}
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

This example shows there are many variables, based on whether the automatic sidecar injection is controlled in your namespace, ConfigMap, or pod and they are:

- webhooks `namespaceSelector` (`istio-injection: enabled`)
- default policy (Configured in the ConfigMap `istio-sidecar-injector`)
- per-pod override annotation (`sidecar.istio.io/inject`)

The [injection status table](/docs/ops/common-problems/injection/) shows a clear picture of the final injection status based on the value of the above variables.

## Traffic flow from application container to sidecar proxy

Now that we are clear about how a sidecar container and an init container are injected into an application manifest, how does the sidecar proxy grab the inbound and outbound traffic to and from the container? We did briefly mention that it is done by setting up the `iptable` rules within the pod namespace, which in turn is done by the `istio-init` container. Now, it is time to verify what actually gets updated within the namespace.

Let’s get into the application pod namespace we deployed in the previous section and look at the configured iptables. I am going to show an example using `nsenter`. Alternatively, you can enter the container in a privileged mode to see the same information. For folks without access to the nodes, using `exec` to get into the sidecar and running `iptables` is more practical.

{{< text bash >}}
$ docker inspect b8de099d3510 --format '{{ .State.Pid }}'
4125
{{< /text  >}}

{{< text bash >}}
$ nsenter -t 4215 -n iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N ISTIO_INBOUND
-N ISTIO_IN_REDIRECT
-N ISTIO_OUTPUT
-N ISTIO_REDIRECT
-A PREROUTING -p tcp -j ISTIO_INBOUND
-A OUTPUT -p tcp -j ISTIO_OUTPUT
-A ISTIO_INBOUND -p tcp -m tcp --dport 80 -j ISTIO_IN_REDIRECT
-A ISTIO_IN_REDIRECT -p tcp -j REDIRECT --to-ports 15001
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ISTIO_REDIRECT
-A ISTIO_OUTPUT -m owner --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
-A ISTIO_REDIRECT -p tcp -j REDIRECT --to-ports 15001
{{< /text >}}

The output above clearly shows that all the incoming traffic to port 80, which is the port our `red-demo` application is listening, is now `REDIRECTED` to port `15001`, which is the port that the `istio-proxy`, an Envoy proxy,  is listening. The same holds true for the outgoing traffic.

This brings us to the end of this post. I hope it helped to de-mystify how Istio manages to inject the sidecar proxies into an existing deployment and how Istio routes the traffic to the proxy.

{{< idea >}}
Update: In place of `istio-init`, there now seems to be an option of using the new CNI, which removes the need for the init container and associated privileges. This [`istio-cni`](https://github.com/istio/cni) plugin sets up the pods' networking to fulfill this requirement in place of the current Istio injected pod `istio-init` approach.
{{< /idea >}}
