---
title: Install Multiple Istio Control Planes in a Single Cluster
description: Install multiple Istio control planes in a single cluster using revisions and discoverySelectors.
weight: 55
keywords: [multiple,control,istiod,local]
owner: istio/wg-environments-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

This guide walks you through the process of installing multiple Istio control planes within a single cluster and then a way to scope workloads to specific control planes. This deployment model has a single Kubernetes control plane with multiple Istio control planes and meshes. The separation between the meshes is provided by Kubernetes namespaces and RBAC.

{{< image width="90%"
    link="single-cluster-multiple-istiods.svg"
    caption="Multiple meshes in a single cluster"
    >}}

Using `discoverySelectors`, you can scope Kubernetes resources in a cluster to specific namespaces managed by an Istio control plane. This includes the Istio custom resources (e.g., Gateway, VirtualService, DestinationRule, etc.) used to configure the mesh. Furthermore, `discoverySelectors` can be used to configure which namespaces should include the `istio-ca-root-cert` config map for a particular Istio control plane. Together, these functions allow mesh operators to specify the namespaces for a given control plane, enabling soft multi-tenancy for multiple meshes based on the boundary of one or more namespaces. This guide uses `discoverySelectors`, along with the revisions capability of Istio, to demonstrate how two meshes can be deployed on a single cluster, each working with a properly scoped subset of the cluster's resources.

## Before you begin

This guide requires that you have a Kubernetes cluster with any of the
[supported Kubernetes versions:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

This cluster will host two control planes installed in two different system namespaces. The mesh application workloads will run in multiple application-specific namespaces, each namespace associated with one or the other control plane based on revision and discovery selector configurations.

## Cluster configuration

### Deploying multiple control planes

Deploying multiple Istio control planes on a single cluster can be achieved by using different system namespaces for each control plane.
Istio revisions and `discoverySelectors` are then used to scope the resources and workloads that are managed by each control plane.
{{< warning >}}
By default, Istio only uses `discoverySelectors` to scope workload endpoints. To enable full resource scoping, including configuration resources, the feature flag `ENABLE_ENHANCED_RESOURCE_SCOPING` must be set to true.
{{< /warning >}}

1. Create the first system namespace, `usergroup-1`, and deploy istiod in it:

    {{< text bash >}}
    $ kubectl create ns usergroup-1
    $ kubectl label ns usergroup-1 usergroup=usergroup-1
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-1
    spec:
      profile: minimal
      revision: usergroup-1
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-1
      values:
        global:
          istioNamespace: usergroup-1
        pilot:
          env:
            ENABLE_ENHANCED_RESOURCE_SCOPING: true
    EOF
    {{< /text >}}

1. Create the second system namespace, `usergroup-2`, and deploy istiod in it:

    {{< text bash >}}
    $ kubectl create ns usergroup-2
    $ kubectl label ns usergroup-2 usergroup=usergroup-2
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-2
    spec:
      profile: minimal
      revision: usergroup-2
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-2
      values:
        global:
          istioNamespace: usergroup-2
        pilot:
          env:
            ENABLE_ENHANCED_RESOURCE_SCOPING: true
    EOF
    {{< /text >}}

1. Deploy a policy for workloads in the `usergroup-1` namespace to only accept mutual TLS traffic:

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

1. Deploy a policy for workloads in the `usergroup-2` namespace to only accept mutual TLS traffic:

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

### Verify the multiple control plane creation

1. Check the labels on the system namespaces for each control plane:

    {{< text bash >}}
    $ kubectl get ns usergroup-1 usergroup2 --show-labels
    NAME              STATUS   AGE     LABELS
    usergroup-1       Active   13m     kubernetes.io/metadata.name=usergroup-1,usergroup=usergroup-1
    usergroup-2       Active   12m     kubernetes.io/metadata.name=usergroup-2,usergroup=usergroup-2
    {{< /text >}}

1. Verify the control planes are deployed and running:

    {{< text bash >}}
    $ kubectl get pods -n usergroup-1
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-1   istiod-usergroup-1-5ccc849b5f-wnqd6      1/1     Running   0                12m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n usergroup-2
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-2   istiod-usergroup-2-658d6458f7-slpd9      1/1     Running   0                12m
    {{< /text >}}

    You will notice that one istiod deployment per usergroup is created in the specified namespaces.

1. Run the following commands to list the installed webhooks:

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

    Note that the output includes `istiod-default-validator` and `istio-revision-tag-default-usergroup-1`, which are the default webhook configurations used for handling requests coming from resources which are not associated with any revision. In a fully scoped environment where every control plane is associated with its resources through proper namespace labeling, there is no need for these default webhook configurations. They should never be invoked.

### Deploy application workloads per usergroup

1.  Create three application namespaces:

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl create ns app-ns-2
    $ kubectl create ns app-ns-3
    {{< /text >}}

1.  Label each namespace to associate them with their respective control planes:

    {{< text bash >}}
    $ kubectl label ns app-ns-1 usergroup=usergroup-1 istio.io/rev=usergroup-1
    $ kubectl label ns app-ns-2 usergroup=usergroup-2 istio.io/rev=usergroup-2
    $ kubectl label ns app-ns-3 usergroup=usergroup-2 istio.io/rev=usergroup-2
    {{< /text >}}

1.  Deploy one `sleep` and `httpbin` application per namespace:

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

Now that the applications are deployed, you can use the `istioctl ps` command to confirm that the application workloads are managed by their respective control plane, i.e., `app-ns-1` is managed by `usergroup-1`, `app-ns-2` and `app-ns-3` are managed by `usergroup-2`:

{{< text bash >}}
$ istioctl ps -i usergroup-1
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-hccpf.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-9zb77.app-ns-1      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

{{< text bash >}}
$ istioctl ps -i usergroup-2
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-vvcqj.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
httpbin-9dbd644c7-xzgfm.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-fthmt.app-ns-2      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-nxtth.app-ns-3      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

### Verify the application connectivity is ONLY within the respective usergroup

1.  Send a request from the `sleep` pod in `app-ns-1` in `usergroup-1` to the `httpbin` service in `app-ns-2` in `usergroup-2`. The communication should fail:

    {{< text bash >}}
    $ kubectl -n app-ns-1 exec "$(kubectl -n app-ns-1 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-2.svc.cluster.local:8000
    HTTP/1.1 503 Service Unavailable
    content-length: 95
    content-type: text/plain
    date: Sat, 24 Dec 2022 06:54:54 GMT
    server: envoy
    {{< /text >}}

1.  Send a request from the `sleep` pod in `app-ns-2` in `usergroup-2` to the `httpbin` service in `app-ns-3` in `usergroup-2`. The communication should work:

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
A Cluster Administrator must make sure that Mesh Administrators DO NOT have permission to invoke the global `istioctl uninstall --purge` command,
because that would uninstall all control planes in the cluster.
{{< /warning >}}
