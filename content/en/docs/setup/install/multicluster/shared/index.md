---
title: Shared control plane (single and multiple networks)
description: Install an Istio mesh across multiple Kubernetes clusters with a shared control plane.
weight: 5
keywords: [kubernetes,multicluster,federation,vpn,gateway]
aliases:
    - /docs/setup/kubernetes/multicluster-install/vpn/
    - /docs/setup/kubernetes/install/multicluster/vpn/
    - /docs/setup/kubernetes/install/multicluster/shared-vpn/
    - /docs/examples/multicluster/split-horizon-eds/
    - /docs/tasks/multicluster/split-horizon-eds/
    - /docs/setup/kubernetes/install/multicluster/shared-gateways/
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to
set up a [multicluster Istio service mesh](/docs/ops/deployment/deployment-models/#multiple-clusters)
across multiple clusters with a shared control plane.

In this configuration, multiple Kubernetes {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}}
connect to a shared Istio [control plane](/docs/ops/deployment/deployment-models/#control-plane-models)
running in a {{< gloss >}}primary cluster{{< /gloss >}}.
Remote clusters can be in the same network as the primary cluster or in different networks.
After one or more remote clusters are connected, the control plane of the primary cluster will
manage the service mesh across all {{< gloss "service endpoint" >}}service endpoints{{< /gloss >}}.

{{< image width="80%" link="./multicluster-with-vpn.svg" caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN" >}}

## Prerequisites

* Two or more clusters running a supported Kubernetes version ({{< supported_kubernetes_versions >}}).

* All Kubernetes control plane API servers must be routable to each other.

* Clusters on the same network must be an RFC1918 network, VPN, or an alternative more advanced network technique
  meeting the following requirements:
    * Individual cluster Pod CIDR ranges and service CIDR ranges must be unique across the network and may not overlap.
    * All pod CIDRs in the same network must be routable to each other.

* Clusters on different networks must have `istio-ingressgateway` services which are accessible from every other
  cluster, ideally using L4 network load balancers (NLB). Not all cloud providers support NLBs and some require
  special annotations to use them, so please consult your cloud provider’s documentation for enabling NLBs for
  service object type load balancers. When deploying on platforms without NLB support, it may be necessary to
  modify the health checks for the load balancer to register the ingress gateway.

## Preparation

### Certificate Authority

Generate intermediate CA certificates for each cluster's CA from your
organization's root CA. The shared root CA enables mutual TLS communication
across different clusters. For illustration purposes, the following instructions
use the certificates from the Istio samples directory for both clusters.

Run the following commands on each cluster in the mesh to install the certificates.
See [Certificate Authority (CA) certificates](/docs/tasks/security/cert-management/plugin-ca-cert/)
for more details on configuring an external CA.

{{< text bash >}}
$ kubectl create namespace istio-system
$ kubectl create secret generic cacerts -n istio-system \
    --from-file=@samples/certs/ca-cert.pem@ \
    --from-file=@samples/certs/ca-key.pem@ \
    --from-file=@samples/certs/root-cert.pem@ \
    --from-file=@samples/certs/cert-chain.pem@
{{< /text >}}

{{< warning >}}
The root and intermediate certificate from the samples directory are widely
distributed and known.  Do **not** use these certificates in production as
your clusters would then be open to security vulnerabilities and compromise.
{{< /warning >}}

### Cross-cluster control plane access

Decide how to expose the primary cluster's Istiod discovery service to
the remote clusters. Pick one of the two options:

* Option (1) - Use the `istio-ingressgateway` gateway shared with data traffic.

* Option (2) - Use a cloud provider’s internal load balancer on the Istiod
  service. For additional requirements and restrictions that may apply when using
  an internal load balancer between clusters, see
  [Kubernetes internal load balancer documentation](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer)
  and your cloud provider's documentation.

### Cluster and network naming

Determine the name of the clusters and networks in the mesh. These names will be used
in the mesh network configuration and when configuring the mesh's service registries.
Assign a unique name to each cluster. The name must be a
[DNS label name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names).
In the example below the primary cluster is called `main0` and the remote cluster is `remote0`.

{{< text bash >}}
$ export MAIN_CLUSTER_CTX=<...>
$ export REMOTE_CLUSTER_CTX=<...>
{{< /text >}}

{{< text bash >}}
$ export MAIN_CLUSTER_NAME=main0
$ export REMOTE_CLUSTER_NAME=remote0
{{< /text >}}

If the clusters are on different networks, assign a unique network name for each network.

{{< text bash >}}
$ export MAIN_CLUSTER_NETWORK=network1
$ export REMOTE_CLUSTER_NETWORK=network2
{{< /text >}}

If clusters are on the same network, the same network name is used for those clusters.

{{< text bash >}}
$ export MAIN_CLUSTER_NETWORK=network1
$ export REMOTE_CLUSTER_NETWORK=network1
{{< /text >}}

## Deployment

### Primary cluster

Create the primary cluster's configuration. Pick one of the two options for cross-cluster
control plane access.

{{< tabset category-name="platform" >}}
{{< tab name="istio-ingressgateway" category-value="istio-ingressgateway" >}}

{{< text yaml >}}
cat <<EOF> istio-main-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      multiCluster:
        clusterName: ${MAIN_CLUSTER_NAME}
      network: ${MAIN_CLUSTER_NETWORK}

      # Mesh network configuration. This is optional and may be omitted if
      # all clusters are on the same network.
      meshNetworks:
        ${MAIN_CLUSTER_NETWORK}:
          endpoints:
          - fromRegistry: ${MAIN_CLUSTER_NAME}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

        ${REMOTE_CLUSTER_NETWORK}:
          endpoints:
          - fromRegistry: ${REMOTE_CLUSTER_NAME}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

      # Use the existing istio-ingressgateway.
      meshExpansion:
        enabled: true
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Internal Load Balancer" category-value="internal-load-balancer" >}}

{{< text yaml >}}
cat <<EOF> istio-main-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      multiCluster:
        clusterName: ${MAIN_CLUSTER_NAME}
      network: ${MAIN_CLUSTER_NETWORK}

      # Mesh network configuration. This is optional and may be omitted if
      # all clusters are on the same network.
      meshNetworks:
        ${MAIN_CLUSTER_NETWORK}:
          endpoints:
          - fromRegistry: ${MAIN_CLUSTER_NAME}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

        ${REMOTE_CLUSTER_NETWORK}:
          endpoints:
          - fromRegistry: ${REMOTE_CLUSTER_NAME}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

  # Change the Istio service `type=LoadBalancer` and add the cloud provider specific annotations. See
  # https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer for more
  # information. The example below shows the configuration for GCP/GKE.
  # If the GCP/GKE version is less than 1.16, add `network.gke.io/internal-load-balancer-allow-global-access: "true"` to the `service_annotations`.
  # See https://stackoverflow.com/questions/59680679/gcp-internal-load-balancer-global-access-beta-annotation-does-not-work?answertab=active#tab-top.
  components:
    pilot:
      k8s:
        service:
          type: LoadBalancer
        service_annotations:
          cloud.google.com/load-balancer-type: Internal
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Apply the primary cluster's configuration.

{{< text bash >}}
$ istioctl install -f istio-main-cluster.yaml --context=${MAIN_CLUSTER_CTX}
{{< /text >}}

Wait for the control plane to be ready before proceeding.

{{< text bash >}}
$ kubectl get pod -n istio-system --context=${MAIN_CLUSTER_CTX}
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-7c8dd65766-lv9ck   1/1     Running   0          136m
istiod-f756bbfc4-thkmk                  1/1     Running   0          136m
{{< /text >}}

Set the `ISTIOD_REMOTE_EP` environment variable based on which remote control
plane configuration option was selected earlier.

{{< tabset category-name="platform" >}}

{{< tab name="istio-ingressgateway" category-value="istio-ingressgateway" >}}

{{< text bash >}}
$ export ISTIOD_REMOTE_EP=$(kubectl get svc -n istio-system --context=${MAIN_CLUSTER_CTX} istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ echo "ISTIOD_REMOTE_EP is ${ISTIOD_REMOTE_EP}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Internal Load Balancer" category-value="internal-load-balancer" >}}

{{< text bash >}}
$ export ISTIOD_REMOTE_EP=$(kubectl get svc -n istio-system --context=${MAIN_CLUSTER_CTX} istiod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ echo "ISTIOD_REMOTE_EP is ${ISTIOD_REMOTE_EP}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Remote cluster

Create the remote cluster's configuration.

{{< text yaml >}}
cat <<EOF> istio-remote0-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      # The remote cluster's name and network name must match the values specified in the
      # mesh network configuration of the primary cluster.
      multiCluster:
        clusterName: ${REMOTE_CLUSTER_NAME}
      network: ${REMOTE_CLUSTER_NETWORK}

      # Replace ISTIOD_REMOTE_EP with the the value of ISTIOD_REMOTE_EP set earlier.
      remotePilotAddress: ${ISTIOD_REMOTE_EP}

  ## The istio-ingressgateway is not required in the remote cluster if both clusters are on
  ## the same network. To disable the istio-ingressgateway component, uncomment the lines below.
  #
  # components:
  #  ingressGateways:
  #  - name: istio-ingressgateway
  #    enabled: false
EOF
{{< /text >}}

Apply the remote cluster configuration.

{{< text bash >}}
$ istioctl install -f istio-remote0-cluster.yaml --context ${REMOTE_CLUSTER_CTX}
{{< /text >}}

Wait for the remote cluster to be ready.

{{< text bash >}}
$ kubectl get pod -n istio-system --context=${REMOTE_CLUSTER_CTX}
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-55f784779d-s5hwl   1/1     Running   0          91m
istiod-7b4bfd7b4f-fwmks                 1/1     Running   0          91m
{{< /text >}}

{{< tip >}}
The istiod deployment running in the remote cluster is providing automatic sidecar injection and CA
services to the remote cluster's pods. These services were previously provided by the sidecar injector
and Citadel deployments, which no longer exist with Istiod. The remote cluster's pods are
getting configuration from the primary cluster's Istiod for service discovery.
{{< /tip >}}

## Cross-cluster load balancing

### Configure ingress gateways

{{< tip >}}
Skip this next step and move onto configuring the service registries if both cluster are on the same network.
{{< /tip >}}

Cross-network traffic is securely routed through each destination cluster's ingress gateway. When clusters in a mesh are
on different networks you need to configure port 443 on the ingress gateway to pass incoming traffic through to the
target service specified in a request's SNI header, for SNI values of the _local_
top-level domain (i.e., the [Kubernetes DNS domain](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)).
Mutual TLS connections will be used all the way from the source to the destination sidecar.

Apply the following configuration to each cluster.

{{< text yaml >}}
cat <<EOF> cluster-aware-gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: cluster-aware-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: tls
      protocol: TLS
    tls:
      mode: AUTO_PASSTHROUGH
    hosts:
    - "*.local"
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f cluster-aware-gateway.yaml --context=${MAIN_CLUSTER_CTX}
$ kubectl apply -f cluster-aware-gateway.yaml --context=${REMOTE_CLUSTER_CTX}
{{< /text >}}

### Configure cross-cluster service registries

To enable cross-cluster load balancing, the Istio control plane requires
access to all clusters in the mesh to discover services, endpoints, and
pod attributes. To configure access, create a secret for each remote
cluster with credentials to access the remote cluster's `kube-apiserver` and
install it in the primary cluster. This secret uses the credentials of the
`istio-reader-service-account` in the remote cluster. `--name` specifies the
remote cluster's name. It must match the cluster name in primary cluster's IstioOperator
configuration.

{{< text bash >}}
$ istioctl x create-remote-secret --name ${REMOTE_CLUSTER_NAME} --context=${REMOTE_CLUSTER_CTX} | \
    kubectl apply -f - --context=${MAIN_CLUSTER_CTX}
{{< /text >}}

{{< warning >}}
Do not create a remote secret for the local cluster running the Istio control plane. Istio is always
aware of the local cluster's Kubernetes credentials.
{{< /warning >}}

## Deploy an example service

Deploy two instances of the `helloworld` service, one in each cluster. The difference
between the two instances is the version of their `helloworld` image.

### Deploy helloworld v2 in the remote cluster

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create namespace sample --context=${REMOTE_CLUSTER_CTX}
    $ kubectl label namespace sample istio-injection=enabled --context=${REMOTE_CLUSTER_CTX}
    {{< /text >}}

1. Deploy `helloworld v2`:

    {{< text bash >}}
    $ kubectl create -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample --context=${REMOTE_CLUSTER_CTX}
    $ kubectl create -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample --context=${REMOTE_CLUSTER_CTX}
    {{< /text >}}

1. Confirm `helloworld v2` is running:

    {{< text bash >}}
    $ kubectl get pod -n sample --context=${REMOTE_CLUSTER_CTX}
    NAME                             READY     STATUS    RESTARTS   AGE
    helloworld-v2-7dd57c44c4-f56gq   2/2       Running   0          35s
    {{< /text >}}

### Deploy helloworld v1 in the primary cluster

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create namespace sample --context=${MAIN_CLUSTER_CTX}
    $ kubectl label namespace sample istio-injection=enabled --context=${MAIN_CLUSTER_CTX}
    {{< /text >}}

1. Deploy `helloworld v1`:

    {{< text bash >}}
    $ kubectl create -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample --context=${MAIN_CLUSTER_CTX}
    $ kubectl create -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample --context=${MAIN_CLUSTER_CTX}
    {{< /text >}}

1. Confirm `helloworld v1` is running:

    {{< text bash >}}
    $ kubectl get pod -n sample --context=${MAIN_CLUSTER_CTX}
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-d4557d97b-pv2hr   2/2       Running   0          40s
    {{< /text >}}

### Cross-cluster routing in action

To demonstrate how traffic to the `helloworld` service is distributed across the two clusters,
call the `helloworld` service from another in-mesh `sleep` service.

1. Deploy the `sleep` service in both clusters:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context=${MAIN_CLUSTER_CTX}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context=${REMOTE_CLUSTER_CTX}
    {{< /text >}}

1. Wait for the `sleep` service to start in each cluster:

    {{< text bash >}}
    $ kubectl get pod -n sample -l app=sleep --context=${MAIN_CLUSTER_CTX}
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pod -n sample -l app=sleep --context=${REMOTE_CLUSTER_CTX}
    sleep-754684654f-dzl9j           2/2     Running   0          5s
    {{< /text >}}

1. Call the `helloworld.sample` service several times from the primary cluster:

    {{< text bash >}}
    $ kubectl exec -it -n sample -c sleep --context=${MAIN_CLUSTER_CTX} $(kubectl get pod -n sample -l app=sleep --context=${MAIN_CLUSTER_CTX} -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

1. Call the `helloworld.sample` service several times from the remote cluster:

    {{< text bash >}}
    $ kubectl exec -it -n sample -c sleep --context=${REMOTE_CLUSTER_CTX} $(kubectl get pod -n sample -l app=sleep --context=${REMOTE_CLUSTER_CTX} -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

If set up correctly, the traffic to the `helloworld.sample` service will be distributed between instances
on the main and remote clusters resulting in responses with either `v1` or `v2` in the body:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

You can also verify the IP addresses used to access the endpoints with `istioctl proxy-config`.

{{< text bash >}}
$ kubectl get pod -n sample -l app=sleep --context=${MAIN_CLUSTER_CTX} -o name | cut -f2 -d'/' | \
    xargs -I{} istioctl -n sample --context=${MAIN_CLUSTER_CTX} proxy-config endpoints {} --cluster "outbound|5000||helloworld.sample.svc.cluster.local"
ENDPOINT             STATUS      OUTLIER CHECK     CLUSTER
10.10.0.90:5000      HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
192.23.120.32:443    HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

In the primary cluster, the endpoints are the gateway IP of the remote cluster (`192.23.120.32:443`) and
the helloworld pod IP in the primary cluster (`10.10.0.90:5000`).

{{< text bash >}}
$ kubectl get pod -n sample -l app=sleep --context=${REMOTE_CLUSTER_CTX} -o name | cut -f2 -d'/' | \
    xargs -I{} istioctl -n sample --context=${REMOTE_CLUSTER_CTX} proxy-config endpoints {} --cluster "outbound|5000||helloworld.sample.svc.cluster.local"
ENDPOINT             STATUS      OUTLIER CHECK     CLUSTER
10.32.0.9:5000       HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
192.168.1.246:443    HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

In the remote cluster, the endpoints are the gateway IP of the primary cluster (`192.168.1.246:443`) and
the pod IP in the remote cluster (`10.32.0.9:5000`).

**Congratulations!**

You have configured a multi-cluster Istio mesh, installed samples and verified cross cluster traffic routing.

## Additional considerations

### Automatic injection

The Istiod service in each cluster provides automatic sidecar injection for proxies in its own cluster.
Namespaces must be labeled in each cluster following the
[automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) guide

### Access services from different clusters

Kubernetes resolves DNS on a cluster basis. Because the DNS resolution is tied
to the cluster, you must define the service object in every cluster where a
client runs, regardless of the location of the service's endpoints. To ensure
this is the case, duplicate the service object to every cluster using
`kubectl`. Duplication ensures Kubernetes can resolve the service name in any
cluster. Since the service objects are defined in a namespace, you must define
the namespace if it doesn't exist, and include it in the service definitions in
all clusters.

### Security

The Istiod service in each cluster provides CA functionality to proxies in its own
cluster. The CA setup earlier ensures proxies across clusters in the mesh have the
same root of trust.

## Uninstalling the remote cluster

To uninstall the remote cluster, run the following command:

{{< text bash >}}
$ istioctl x create-remote-secret --name ${REMOTE_CLUSTER_NAME} --context=${REMOTE_CLUSTER_CTX} | \
    kubectl delete -f - --context=${MAIN_CLUSTER_CTX}
$ istioctl manifest generate -f istio-remote0-cluster.yaml --context=${REMOTE_CLUSTER_CTX} | \
    kubectl delete -f - --context=${REMOTE_CLUSTER_CTX}
$ kubectl delete namespace sample --context=${REMOTE_CLUSTER_CTX}
$ unset REMOTE_CLUSTER_CTX REMOTE_CLUSTER_NAME REMOTE_CLUSTER_NETWORK
$ rm istio-remote0-cluster.yaml
{{< /text >}}

To uninstall the primary cluster, run the following command:

{{< text bash >}}
$ istioctl manifest generate -f istio-main-cluster.yaml --context=${MAIN_CLUSTER_CTX} | \
    kubectl delete -f - --context=${MAIN_CLUSTER_CTX}
$ kubectl delete namespace sample --context=${MAIN_CLUSTER_CTX}
$ unset MAIN_CLUSTER_CTX MAIN_CLUSTER_NAME MAIN_CLUSTER_NETWORK ISTIOD_REMOTE_EP
$ rm istio-main-cluster.yaml cluster-aware-gateway.yaml
{{< /text >}}
