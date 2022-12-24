---
title: Install Multiple Istio Control Planes in a Single Cluster
description: Install multiple Istio control planes in a single cluster using revisions and discoverySelectors.
weight: 55
keywords: [multiple,control,istiod,local]
owner: istio/wg-environments-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

This guide walks you through the process of installing multiple Istio control planes within a single cluster and
then a way to scope workloads to specific control planes. For this guide, [the deployment model](/docs/ops/deployment/deployment-models/#control-plane-models)
will have a single Kubernetes control plane with multiple Istio control planes and multiple meshes.
The separation between the meshes is provided by Kubernetes namespaces and RBAC.

{{< image width="80%"
    link="single-cluster-multiple-istiods.svg"
    caption="Multiple control planes in Single Cluster"
    >}}

With `discoverySelectors` you can not only scope the Kubernetes resources to specific namespaces managed by Istio control plane, but also scope the Istio custom resources such as Gateway, VirtualService, DestinationRule, etc. Furthermore, you can leverage `discoverySelectors` to configure the Istio control plane on which namespaces you want the `istio-ca-root-cert` config map. These enhancements are very useful if you want to specify the allowed mesh namespaces for a given control plane as mesh operators, or enable soft multi-tenancy for your mesh based on the boundary of one or more namespaces. This guide uses `discoverySelectors` along with the revisions capability of Istio to demonstrate how multiple control planes can be deployed to work with properly scoped resources per control plane.

## Before you begin

This guide requires that you have a Kubernetes cluster with any of the
[supported Kubernetes versions:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

This cluster will host two control planes installed in two different system namespaces.
The mesh application workloads will run in application specific namespaces and can be associated to their control planes by
proper configuration using revisions and discovery selectors.

## Cluster configuration

### Deploying multiple control planes

Deploying multiple Istio control planes can be achieved by specifying a distinct system namespace for each control plane.
Istio revisions and `discoverySelectors` features can be used together with this, to provide proper resource scoping for workloads
in this deployment model. For making use of the complete resource scoping, the feature flag `ENABLE_ENHANCED_RESOURCE_SCOPING` has to be set to true.

1. Create the first system namespace and deploy istiod in the custom system namespace.

    {{< text bash >}}
    $ kubectl create ns usergroup-1
    $ kubectl label ns usergroup-1 usergroup=usergroup-1
    $ istioctl install --set namespace=usergroup-1 --set values.global.istioNamespace=usergroup-1 --set revision=usergroup-1 --set values.pilot.env.ENABLE_ENHANCED_RESOURCE_SCOPING=true --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY --skip-confirmation -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-1
    spec:
    # You may override parts of meshconfig by uncommenting the following lines.
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-1
    EOF
    {{< /text >}}

1. Create the second system namespace and deploy istiod in the custom system namespace.

    {{< text bash >}}
    $ kubectl create ns usergroup-2
    $ kubectl label ns usergroup-2 usergroup=usergroup-2
    $ istioctl install --set namespace=usergroup-2 --set values.global.istioNamespace=usergroup-2 --set revision=usergroup-2 --set values.pilot.env.ENABLE_ENHANCED_RESOURCE_SCOPING=true --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY --skip-confirmation -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-2
    spec:
    # You may override parts of meshconfig by uncommenting the following lines.
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-2
    EOF
    {{< /text >}}

1. Deploy a policy for workloads in the `usergroup-1` namespace to only accept mutual TLS traffic.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-1-peerauth"
      namespace: "usergroup-1"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

1. Deploy a policy for workloads in the `usergroup-2` namespace to only accept mutual TLS traffic.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-2-peerauth"
      namespace: "usergroup-2"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

{{< warning >}}
In a fully scoped environment where each control plane is associated with its resources through proper namespace labeling, there is no need for the default webhook
configurations provided by Istio. However it is the responsibility of the Mesh Administrator to make sure no requests bypass the validation step.
{{< /warning >}}

The below output shows `istiod-default-validator` and `istio-revision-tag-default-usergroup-1`, which are the default webhook configuration available in Istio deployment used for handling requests coming from resources which are not labeled with any revision. It would be ideal to remove them from the charts for the current use case, as they are primarily used to handle revision based upgrade. `istio-revision-tag-default-tenant-1` handles the sidecar injection for pods that are labeled with `istio-injection=enabled`, which is not needed for cases where we are adding usergroup specific labels.

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration
    NAME                                      WEBHOOKS   AGE
    istio-validator-usergroup-1-usergroup-1   1          18m
    istio-validator-usergroup-2-usergroup-2   1          18m
    istiod-default-validator                  1          18m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration
    NAME                                             WEBHOOKS   AGE
    istio-revision-tag-default-usergroup-1           4          18m
    istio-sidecar-injector-usergroup-1-usergroup-1   2          19m
    istio-sidecar-injector-usergroup-2-usergroup-2   2          18m
    {{< /text >}}

### Verify Multiple Control Plane Creation

1. Check the labels on the system namespaces per user group

    {{< text bash >}}
    $ kubectl get ns --show-labels
    NAME              STATUS   AGE     LABELS
    usergroup-1       Active   13m     kubernetes.io/metadata.name=usergroup-1,usergroup=usergroup-1
    usergroup-2       Active   12m     kubernetes.io/metadata.name=usergroup-2,usergroup=usergroup-2
    {{< /text >}}

1. Verify the namespaces in which the control planes are deployed

    {{< text bash >}}
    $ kubectl get pods --all-namespaces
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-1   istio-ingressgateway-8df594958-6t7x6     1/1     Running   0                12m
    usergroup-1   istiod-usergroup-1-5ccc849b5f-wnqd6      1/1     Running   0                12m
    usergroup-2   istio-ingressgateway-7bc5b4c97d-bvsvg    1/1     Running   0                11m
    usergroup-2   istiod-usergroup-2-658d6458f7-slpd9      1/1     Running   0                12m
    {{< /text >}}

    You will notice that one istiod deployment per usergroup is created in the specified namespaces.

### Deploy application workloads per usergroup

1.  Create three application namespaces

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl create ns app-ns-2
    $ kubectl create ns app-ns-3
    {{< /text >}}

1.  Associate the namespaces with their respective control planes through proper namespace labeling. Here the labeling is done
    according to the diagram shown in the beginning of the page.

    {{< text bash >}}
    $ kubectl label ns app-ns-1 usergroup=usergroup-1 istio.io/rev=usergroup-1
    $ kubectl label ns app-ns-2 usergroup=usergroup-2 istio.io/rev=usergroup-2
    $ kubectl label ns app-ns-3 usergroup=usergroup-2 istio.io/rev=usergroup-2
    {{< /text >}}

1.  Deploy one `sleep` and `httpbin` application per namespace

    {{< text bash >}}
    $ kubectl -n app-ns-1 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-1 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-2 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-2 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-3 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-3 apply -f samples/httpbin/httpbin.yaml
    {{< /text >}}

1.  Wait a few seconds for the `httpbin` and `sleep` pods to be running with sidecars injected:

    {{< text bash >}}
    $ kubectl get pods -n app-ns-1
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-zc2v4   2/2     Running   0          115m
    sleep-78ff5975c6-fml7c    2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-2
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-sd9ln   2/2     Running   0          115m
    sleep-78ff5975c6-sz728    2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-3
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-8ll27   2/2     Running   0          115m
    sleep-78ff5975c6-sg4tq    2/2     Running   0          115m
    {{< /text >}}

### Verify the application to control plane mapping

Now that the applications are deployed, let us confirm if the application workloads are managed by the respective control plane using `istioctl ps` command.

    {{< text bash >}}
    $ istioctl ps -i usergroup-1
    NAME                                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
    httpbin-9dbd644c7-hccpf.app-ns-1                     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    istio-ingressgateway-8df594958-6t7x6.usergroup-1     Kubernetes     SYNCED     SYNCED     SYNCED     NOT SENT     NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    sleep-78ff5975c6-9zb77.app-ns-1                      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    {{< /text >}}

    {{< text bash >}}
    $ istioctl ps -i usergroup-2
    NAME                                                  CLUSTER        CDS        LDS        EDS        RDS          ECDS        ISTIOD                                  VERSION
    httpbin-9dbd644c7-vvcqj.app-ns-3                      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT    istiod-usergroup-2-658d6458f7-slpd9
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    httpbin-9dbd644c7-xzgfm.app-ns-2                      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT    istiod-usergroup-2-658d6458f7-slpd9
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    istio-ingressgateway-7bc5b4c97d-bvsvg.usergroup-2     Kubernetes     SYNCED     SYNCED     SYNCED     NOT SENT     NOT SENT    istiod-usergroup-2-658d6458f7-slpd9
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    sleep-78ff5975c6-fthmt.app-ns-2                       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT    istiod-usergroup-2-658d6458f7-slpd9
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    sleep-78ff5975c6-nxtth.app-ns-3                       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT    istiod-usergroup-2-658d6458f7-slpd9
    1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
    {{< /text >}}

### Verify the application connectivity is ONLY within the respective usergroup

1.  Send a request from the `sleep` pod in `app-ns-1` in `usergroup-1` to the `httpbin` service in `app-ns-2` in `usergroup-2`, the communication should fail:

    {{< text bash >}}
    $ kubectl -n app-ns-1 exec "$(kubectl -n app-ns-1 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-2.svc.cluster.local:8000
    HTTP/1.1 503 Service Unavailable
    content-length: 95
    content-type: text/plain
    date: Sat, 24 Dec 2022 06:54:54 GMT
    server: envoy
    {{< /text >}}

1.  Send a request from the `sleep` pod in `app-ns-2` in `usergroup-2` to the `httpbin` service in `app-ns-3` in `usergroup-2`, the communication should work:

    {{< text bash >}}
    $ kubectl -n app-ns-2 exec "$(kubectl -n app-ns-2 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-3.svc.cluster.local:8000
    HTTP/1.1 200 OK
    server: envoy
    date: Thu, 22 Dec 2022 15:01:36 GMT
    content-type: text/html; charset=utf-8
    content-length: 9593
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3
    {{< /text >}}

## Cleanup

1.  Clean up the first usergroup:

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-1
    $ kubectl delete ns app-ns-1 usergroup-1
    {{< /text >}}

1.  Clean up the second usergroup:

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-2
    $ kubectl delete ns app-ns-2 app-ns-3 usergroup-2
    {{< /text >}}

{{< warning >}}
Cluster Administrator has to make sure that the Mesh Administrator DO NOT have the permission to invoke global `istioctl uninstall --purge`
as that will uninstall all the control planes in the cluster.
{{< /warning >}}
