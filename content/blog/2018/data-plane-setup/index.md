---
title: Demystifying Istio's Sidecar Injection Model 
description: De-mystify how Istio manages to plugin its data-plane components into an existing deployment. Deep-dive into sidecar injection, how it is done whether manually or `namespaceSelector` based automatic injection. And also how the iptables are modified in the pod namespace to redirect the traffic to the injected proxy. 
publishdate: 2018-12-12
subtitle:
attribution: Manish CHUGTU
twitter: chugtum 
weight: 78
keywords: [kubernetes, istio, sidecar-injection, admission-controller, mutatingwebhook]

---
A simple overview of an Istio service-mesh architecture always starts with describing the control-plane and data-plane.

_*From Istio’s Documentation:*_

> An Istio service mesh is logically split into a data plane and a control plane.

> - The data plane is composed of a set of intelligent proxies (Envoy) deployed as sidecars. These proxies mediate and control all network communication between microservices along with Mixer, a general-purpose policy and telemetry hub.

> - The control plane manages and configures the proxies to route traffic. Additionally, the control plane configures Mixers to enforce policies and collect telemetry.

{{< image width="40%" ratio="33%" link="./arch-2.svg" caption="" >}}
It is important to understand that the sidecar injection into application pods happens automatically, though manual injection is also possible. Traffic is directed from the application services to and from these sidecars without developers needing to worry about it. Once they are connected to the Istio service mesh, they can start using and reaping the benefits of all that it has to offer. But how does the data plane plumbing happen and what is really required to make it work seamlessly? In this post we will deep-dive into the specifics of sidecar injection models for a very clear understanding of how it works.

## Sidecar Injection

In simple terms, sidecar injection is done by modifying the pod template with the configuration of additional containers. The containers that are added as a part of Istio service mesh are:

1. `istio-init`
This is an [Init Container] (<https://kubernetes.io/docs/concepts/workloads/pods/init-containers/>) that is used to setup the iptables rules so that inbound/outbound traffic will go through the sidecar proxy. An init container is different than an app container in following ways:

	- It runs before an app container is started and it always runs to completion.
	- If there are many init containers, each should complete with success before the next container is started.
   	So this is perfect for a set-up or initialization job which does not need to be a part of the actual application container. In this case, it does just that, which is to setup the iptables rules.

2. `istio-proxy`
       	This is the actual sidecar proxy (based on Envoy).

### Manual Injection

In the manual injection method, `istioctl` can be used to modify the pod template and update it with the configuration of the above two containers. For both manual as well as automatic injection, Istio takes the configuration from the `istio-sidecar-injector` configmap and the mesh configmap `istio`.
Let’s look at the configuration of `istio-sidecar-injector` configmap, to get an idea of what actually is going on.

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
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
    - "-m"
    - [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String ]]
    - "-i"
    [[ if (isset .ObjectMeta.Annotations "traffic.sidecar.istio.io/includeOutboundIPRanges") -]]
    - "[[ index .ObjectMeta.Annotations "traffic.sidecar.istio.io/includeOutboundIPRanges"  ]]"
    [[ else -]]
    - "*"
    [[ end -]]
    - "-x"
    [[ if (isset .ObjectMeta.Annotations "traffic.sidecar.istio.io/excludeOutboundIPRanges") -]]
    - "[[ index .ObjectMeta.Annotations "traffic.sidecar.istio.io/excludeOutboundIPRanges"  ]]"
    [[ else -]]
    - ""
    [[ end -]]
    - "-b"
    [[ if (isset .ObjectMeta.Annotations "traffic.sidecar.istio.io/includeInboundPorts") -]]
    - "[[ index .ObjectMeta.Annotations "traffic.sidecar.istio.io/includeInboundPorts"  ]]"
    [[ else -]]
    - [[ range .Spec.Containers -]][[ range .Ports -]][[ .ContainerPort -]], [[ end -]][[ end -]][[ end]]
    - "-d"
    [[ if (isset .ObjectMeta.Annotations "traffic.sidecar.istio.io/excludeInboundPorts") -]]
    - "[[ index .ObjectMeta.Annotations "traffic.sidecar.istio.io/excludeInboundPorts" ]]"
    [[ else -]]
    - ""
    [[ end -]]
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
    - --configPath
    - [[ .ProxyConfig.ConfigPath ]]
    - --binaryPath
    - [[ .ProxyConfig.BinaryPath ]]
    - --serviceCluster
    [[ if ne "" (index .ObjectMeta.Labels "app") -]]
    - [[ index .ObjectMeta.Labels "app" ]]
    [[ else -]]
    - "istio-proxy"
    [[ end -]]
    - --drainDuration
    - [[ formatDuration .ProxyConfig.DrainDuration ]]
    - --parentShutdownDuration
    - [[ formatDuration .ProxyConfig.ParentShutdownDuration ]]
    - --discoveryAddress
    - [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/discoveryAddress") .ProxyConfig.DiscoveryAddress ]]
    - --discoveryRefreshDelay
    - [[ formatDuration .ProxyConfig.DiscoveryRefreshDelay ]]
    - --connectTimeout
    - [[ formatDuration .ProxyConfig.ConnectTimeout ]]
    - --statsdUdpAddress
    - [[ .ProxyConfig.StatsdUdpAddress ]]
    - --proxyAdminPort
    - [[ .ProxyConfig.ProxyAdminPort ]]
    [[ if gt .ProxyConfig.Concurrency 0 -]]
    - --concurrency
    - [[ .ProxyConfig.Concurrency ]]
    [[ end -]]
    - --controlPlaneAuthPolicy
    - [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/controlPlaneAuthPolicy") .ProxyConfig.ControlPlaneAuthPolicy ]]
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: INSTANCE_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: ISTIO_META_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: ISTIO_META_INTERCEPTION_MODE
      value: [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String ]]
    imagePullPolicy: IfNotPresent
    securityContext:
      readOnlyRootFilesystem: true
      [[ if eq (or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String) "TPROXY" -]]
      capabilities:
        add:
        - NET_ADMIN
      runAsGroup: 1337
      [[ else -]]
      runAsUser: 1337
      [[ end -]]
    restartPolicy: Always
    resources:
      [[ if (isset .ObjectMeta.Annotations "sidecar.istio.io/proxyCPU") -]]
      requests:
        cpu: "[[ index .ObjectMeta.Annotations "sidecar.istio.io/proxyCPU" ]]"
        memory: "[[ index .ObjectMeta.Annotations "sidecar.istio.io/proxyMemory" ]]"
    [[ else -]]
      requests:
        cpu: 100m
        memory: 128Mi

    [[ end -]]
    volumeMounts:
    - mountPath: /etc/istio/proxy
      name: istio-envoy
    - mountPath: /etc/certs/
      name: istio-certs
      readOnly: true
  volumes:
  - emptyDir:
      medium: Memory
    name: istio-envoy
  - name: istio-certs
    secret:
      optional: true
      [[ if eq .Spec.ServiceAccountName "" -]]
      secretName: istio.default
      [[ else -]]
      secretName: [[ printf "istio.%s" .Spec.ServiceAccountName ]]
      [[ end -]]
{{< /text >}}

As can be seen, the configmap contains the configuration for both the init container `istio-init` as well as proxy container `istio-proxy`. The configuration includes the name of the container image and arguments like interception mode, capabilities etc.

From a security point of view, it is important to note that `istio-init` requires `NET_ADMIN` capabilities to be able to modify iptables within the pod namespace and so does `istio-proxy` if configured in `TPROXY` mode. As this is restricted to a pod namespace, there should be no problem, but I have noticed that recent open-shift versions may have some issues with it and a workaround is needed (One of such options is mentioned at the end of this post).

To modify the current pod template for sidecar injection, the user can do the following:

{{< text bash >}}
$ istioctl kube-inject -f demo-red.yaml | kubectl apply -f -
{{< /text >}}

_*OR*_

To use modified configmaps or local configmaps:

a) Create `inject-config.yaml` and `mesh-config.yaml` from the configmaps

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

b) Modify the existing pod template (Example: demo-red.yaml in my case)

{{< text bash >}}
$ istioctl kube-inject --injectConfigFile inject-config.yaml --meshConfigFile mesh-config.yaml --filename demo-red.yaml --output demo-red-injected.yaml
{{< /text >}}

c) Apply the demo-red-injected.yaml

{{< text bash >}}
$ kubectl apply -f demo-red-injected.yaml
{{< /text >}}

As seen above, we create a new template using the `sidecar-injector` and mesh configuration and apply that using `kubectl`. If we look at the injected yaml, it has the configuration of the istio specific containers, as discussed above. Once we apply the injected yaml, we would see 2 containers running. One of them is the actual application container, and the other is the `istio-proxy` sidecar.

{{< text bash >}}
$ kubectl get pods | grep demo-red
demo-red-pod-8b5df99cc-pgnl7   2/2       Running   0          3d
{{< /text >}}

The reason the count is not 3 is because the `istio-init` container is an `Init Container` type that exits after doing what it supposed to do, which is setting up the `iptable` rules within the pod.  Let’s look at the output of `kubectl describe`, to confirm the same.

{{< text bash >}}
$ kubectl describe pod demo-red-pod-8b5df99cc-pgnl7
Name:               demo-red-pod-8b5df99cc-pgnl7
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               c2-master.avi.local/10.160.146.64
Start Time:         Sun, 09 Dec 2018 18:12:27 -0800
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
    Port:          <none>
    Args:
      -p
      15001
      -u
      1337
      -m
      REDIRECT
      -i
      *
      -x

      -b

      -d

    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sun, 09 Dec 2018 18:12:28 -0800
      Finished:     Sun, 09 Dec 2018 18:12:29 -0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-8dwc2 (ro)
Containers:
  demo-red:
    Container ID:   docker://8cd9957955ff7e534376eb6f28b56462099af6dfb8b9bc37aaf06e516175495e
    Image:          chugtum/blue-green-image:v3
    Image ID:       docker-pullable://docker.io/chugtum/blue-green-image@sha256:274756dbc215a6b2bd089c10de24fcece296f4c940067ac1a9b4aea67cf815db
    Port:           <none>
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        100m
      memory:     200
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-8dwc2 (ro)
  istio-proxy:
    Container ID:  docker://ca5d690be8cd6557419cc19ec4e76163c14aed2336eaad7ebf17dd46ca188b4a
    Image:         docker.io/istio/proxyv2:1.0.2
    Image ID:      docker-pullable://docker.io/istio/proxyv2@sha256:54e206530ba6ca9b3820254454e01b7592e9f986d27a5640b6c03704b3b68332
    Port:          <none>
    Args:
      proxy
      sidecar
      --configPath
      /etc/istio/proxy
      --binaryPath
      /usr/local/bin/envoy
      --serviceCluster
      demo-red
      --drainDuration
      45s
      --parentShutdownDuration
      1m0s
      --discoveryAddress
      10.160.126.45:15007
      --discoveryRefreshDelay
      1s
      --connectTimeout
      10s
      --statsdUdpAddress
      10.160.126.44:9125
      --proxyAdminPort
      15000
      --controlPlaneAuthPolicy
      NONE
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:     100m
      memory:  128Mi
    Environment:
      POD_NAME:                      demo-red-pod-8b5df99cc-pgnl7 (v1:metadata.name)
      POD_NAMESPACE:                 default (v1:metadata.namespace)
      INSTANCE_IP:                    (v1:status.podIP)
      ISTIO_META_POD_NAME:           demo-red-pod-8b5df99cc-pgnl7 (v1:metadata.name)
      ISTIO_META_INTERCEPTION_MODE:  REDIRECT
    Mounts:
      /etc/certs/ from istio-certs (ro)
      /etc/istio/proxy from istio-envoy (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-8dwc2 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  istio-envoy:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  Memory
  istio-certs:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  istio.default
    Optional:    true
  default-token-8dwc2:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-8dwc2
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
{{< /text >}}

As is seen from the output, the state of `istio-init` is terminated with reason completed. The only two containers running are the main application container and the istio-proxy.

### Automatic Injection

Most of the times, you don’t want to manually inject a sidecar (using the `istioctl` command) every time you deploy an application, but would prefer that istio automatically inject the sidecar to your pod. This is a recommended approach and for this to work, all you need to do is to label the namespace where you are deploying the app with `istio-injection=enabled`.

Once done, any pod that you deploy in that namespace would have the sidecar injected automatically. In the following example, the sidecar would automatically get injected in the pods deployed in the istio-dev namespace.

{{< text bash >}}
$ kubectl get namespaces --show-labels
NAME           STATUS    AGE       LABELS
default        Active    40d       <none>
istio-dev      Active    19d       istio-injection=enabled
istio-system   Active    24d       <none>
kube-public    Active    40d       <none>
kube-system    Active    40d       <none>
{{< /text >}}

But how does this work ? To get to the bottom of this, we need to understand k8s admission controllers.

From Kubernetes documentation:

> An admission controller is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object, but after the request is authenticated and authorized. You can define two types of admission webhooks, validating admission Webhook and mutating admission webhook. With validating admission Webhooks, you may reject requests to enforce custom admission policies. With mutating admission Webhooks, you may change requests to enforce custom defaults.

For automatic sidecar injection, Istio relies on `Mutating Admission Webhook`. Let’s look at the details of the  `istio-sidecar-injector` mutating webhook configuration.

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml
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
  resourceVersion: "8379313"
  selfLink: /apis/admissionregistration.k8s.io/v1beta1/mutatingwebhookconfigurations/istio-sidecar-injector
  uid: 376c976c-fc57-11e8-9950-005056ad0356
webhooks:
- clientConfig:
    caBundle: XXXXXXXX
    service:
      name: istio-sidecar-injector
      namespace: istio-system
      path: /inject
  failurePolicy: Fail
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
  sideEffects: Unknown
{{< /text >}}

This is where you can see the webhook `namespaceSelector` label that is matched for sidecar injection `(istio-injection: enabled`) and also the operations/resources for which this is done (in this case when pods are created). When an `apiserver` receives a request that matches one of the rules, the `apiserver` sends an Admission Review request to webhook service as specified in the `clientConfig (name: istio-sidecar-injector)`. We should be able to see that this service is running in `istio-system` namespace.

{{< text bash>}}
$ kubectl get svc --namespace=istio-system | grep sidecar-injector
istio-sidecar-injector   ClusterIP   10.102.70.184   <none>        443/TCP             24d
{{< /text >}}

This would ultimately do pretty much the same as we saw in manual injection, just that it is done automatically during pod creation, so you won’t see the change in deployment. You would need to use `kubectl describe` to see the sidecar proxy and init proxy. In case you want to change the default behavior, like the namespaces where istio applies the injection, you can edit the MutatingWebhookConfiguration and restart the sidecar injector pod.

Apart from the webhooks `namespaceSelector`, automatic sidecar injection also depends on the default `policy` and the per-pod override annotation.

If you look at the `istio-sidecar-injector` ConfigMap again, it has the default injection policy defined. In our case, it is enabled by default.

{{< text bash>}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
SNIPPET of the output:

policy: enabled
template: |-
  initContainers:
  - name: istio-init
    image: "gcr.io/istio-release/proxy_init:1.0.2"
    args:
    - "-p"
    - [[ .MeshConfig.ProxyListenPort ]]
{{< /text >}}

You can also use the annotation `sidecar.istio.io/inject` in the pod template to override the default policy. The following is to disable automatic injection of the sidecar.

{{< text plain>}}
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

So it can be seen that there are many variables, based on which automatic sidecar injection is controlled in your pod namespace, and they are:

- webhooks `namespaceSelector` (`istio-injection: enabled`)
- default policy (Configured in the ConfigMap `istio-sidecar-injector`)
- per-pod override annotation (`sidecar.istio.io/inject`)

This [table] (<https://istio.io/help/ops/setup/injection/>) shows a clear picture of the final injection status based on the value of the above variables.

## Traffic Flow from Application Container to Sidecar Proxy

Now that we are clear about how a sidecar container and an init container are injected into an application manifest, how does the sidecar proxy grab the inbound/outbound traffic to/from the container ? We did briefly mention that it is done by setting up the `iptable` rules within the pod namespace, which in turn is done by the `istio-init` container. Now, it is time to verify what actually gets updated within the namespace.

Let’s get into the application pod namespace that we deployed in the previous section and look at the iptables configured. I am going to show an example using `nsenter` (you can also enter the container in a privileged mode to see the same - For folks without access to the nodes, `exec` into the sidecar and running iptables is more practical).

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

From the output above, it is now clear that all the incoming traffic to port 80, which is where our application is listening is now `REDIRECTED` to port `15001`, which is the istio-proxy (envoy) listen port. The same holds true for the outgoing traffic too.

This brings us to the end of this post. I hope it helped to de-mystify how Istio manages to plugin its data-plane components into an existing deployment, mainly injection of the sidecar containers and traffic routing to the proxy.

> Update: In place of istio-init, there now seems to be an option of using the new CNI, which removes the need for the init container and associated privileges. This [`istio-cni`] (<https://github.com/istio/cni>) plugin sets up the pods' networking to fulfill this requirement in place of the current Istio injected pod `istio-init` approach.
