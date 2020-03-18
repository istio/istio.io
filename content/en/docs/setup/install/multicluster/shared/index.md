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
---

Setup a [multicluster Istio service mesh](/docs/ops/deployment/deployment-models/#multiple-clusters)
across multiple clusters with a shared control plane. In this configuration, multiple Kubernetes clusters running
a remote configuration connect to a shared Istio [control plane](/docs/ops/deployment/deployment-models/#control-plane-models)
running in a main cluster. Clusters may be on the same network or different networks than other
clusters in the mesh. Once one or more remote Kubernetes clusters are connected to the Istio control plane,
Envoy can then form a mesh.

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
use the certificates from the Istio samples directory for both cluster. Run the
following commands on each cluster in the mesh to install the certificates.
See [Certificate Authority (CA) certificates](/docs/tasks/security/plugin-ca-cert/)
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

Decide how to expose the main cluster's Istiod discovery service to
the remote clusters. Choose between **one** of the two options below:

* Option (1) - Use the `istio-ingressgateway` gateway shared with data traffic.
* Option (2) - Use a cloud provider’s internal load balancer on the Istiod service.

### Cluster and network naming

Determine the name of the clusters and networks in the mesh. These names will be used
in the mesh network configuration and when configuring the mesh's service registries.
Assign a unique name to each cluster. The name must be a
[DNS label name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names).
In the example below the main cluster is called `main0` and the remote cluster is `remote0`.

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

### Main cluster

Create the main cluster's configuration. Replace the variables below with the cluster
and network names chosen earlier. Pick **one** of the two options for cross-cluster
control plane access and delete the configuration for the other two options.

{{< text yaml >}}
cat <<EOF> istio-main-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    # required if istiod is disabled
    security:
      selfSigned: false
    global:
      multiCluster:
        clusterName: ${MAIN_CLUSTER_NAME}
      network: ${MAIN_CLUSTER_NETWORK}

# Mesh network configuration. This is optional and may be omitted if all clusters are on the same network.
      meshNetworks:
        ${MAIN_CLUSTER_NETWORK}:
          endpoints:
          # Always use Kubernetes as the registry name for the main cluster in the mesh network configuration
          - fromRegistry: Kubernetes
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

        ${REMOTE_CLUSTER_NETWORK}:
          endpoints:
          - fromRegistry: ${REMOTE_CLUSTER_NAME}
          gateways:
          - registry_service_name: istio-ingressgateway.istio-system.svc.cluster.local
            port: 443

  # Configure cross-cluster control plane access. Choose one of the three
  # options below and delete the other two option's configuration.

  # Option(1) - Use the existing istio-ingressgateway.
      meshExpansion:
        enabled: true

  # Option(2) - Use a cloud provider’s internal load balancer.
  # Change the Istio service `type=LoadBalancer` and add the cloud provider specific annotations. See
  # https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer for more
  # information. The example below shows the configuration for GCP/GKE.
  components:
    pilot:
      k8s:
        service:
          type: LoadBalancer
        service_annotations:
          cloud.google.com/load-balancer-type: Internal
EOF
{{< /text >}}

Apply the main cluster's configuration.

{{< text bash >}}
$ istioctl --context=${MAIN_CLUSTER_CTX} manifest apply -f istio-main-cluster.yaml
{{< /text >}}

Wait for the control plane to be ready before proceeding. Set the `ISTIOD_REMOTE_EP` environment
variable based on which remote control plane configuration option was selected earlier:

* Option (1) - `istio-ingressgateway` gateway shared with data traffic

{{< text bash >}}
$ export ISTIOD_REMOTE_EP=$(kubectl --context=${MAIN_CLUSTER_CTX} -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

* Option (2) - Use a cloud provider’s internal load balancer on the Istiod service.

{{< text bash >}}
$ export ISTIOD_REMOTE_EP=$(kubectl --context=${MAIN_CLUSTER_CTX}  -n istio-system get svc istiod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

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
      # mesh network configuration of the main cluster.
      multiCluster:
        clusterName: ${REMOTE_CLUSTER_NAME}
      network: ${REMOTE_CLUSTER_NETWORK}

      # Replace ISTIOD_REMOTE_EP with the the value of ISTIOD_REMOTE_EP set earlier.
      remotePilotAddress: ${ISTIOD_REMOTE_EP}
EOF
{{< /text >}}

Apply the remote cluster configuration.

{{< text bash >}}
$ istioctl --context ${REMOTE_CLUSTER_CTX} manifest apply -f istio-remote0-cluster.yaml
{{< /text >}}

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
$ kubectl --context=${MAIN_CLUSTER_CTX} apply -f cluster-aware-gateway.yaml
$ kubectl --context=${REMOTE_CLUSTER_CTX} apply -f cluster-aware-gateway.yaml
{{< /text >}}

### Configure cross-cluster service registries

To enable cross-cluster load balancing, the Istio control plane requires
access to all clusters in the mesh to discover services, endpoints, and
pod attributes. To configure access, create a secret for each remote
cluster with credentials to access the remote cluster's `kube-apiserver` and
install it in the main cluster. This secret uses the credentials of the
`istio-reader-service-account` in the remote cluster. `--name` specifies the
remote cluster's name. It must match the cluster name in main cluster's IstioOperator
configuration.

{{< text bash >}}
$ istioctl x create-remote-secret --context=${REMOTE_CLUSTER_CTX} --name ${REMOTE_CLUSTER_NAME} | \
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
    $ kubectl create --context=${REMOTE_CLUSTER_CTX} namespace sample
    $ kubectl label --context=${REMOTE_CLUSTER_CTX} namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy `helloworld v2`:

    {{< text bash >}}
    $ kubectl create --context=${REMOTE_CLUSTER_CTX} -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=${REMOTE_CLUSTER_CTX} -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample
    {{< /text >}}

1. Confirm `helloworld v2` is running:

    {{< text bash >}}
    $ kubectl get pod --context=${REMOTE_CLUSTER_CTX} -n sample
    NAME                             READY     STATUS    RESTARTS   AGE
    helloworld-v2-7dd57c44c4-f56gq   2/2       Running   0          35s
    {{< /text >}}

### Deploy helloworld v1 in the main cluster

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create --context=${MAIN_CLUSTER_CTX} namespace sample
    $ kubectl label --context=${MAIN_CLUSTER_CTX} namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy `helloworld v1`:

    {{< text bash >}}
    $ kubectl create --context=${MAIN_CLUSTER_CTX} -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=${MAIN_CLUSTER_CTX} -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample
    {{< /text >}}

1. Confirm `helloworld v1` is running:

    {{< text bash >}}
    $ kubectl get pod --context=${MAIN_CLUSTER_CTX} -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-d4557d97b-pv2hr   2/2       Running   0          40s
    {{< /text >}}

### Cross-cluster routing in action

To demonstrate how traffic to the `helloworld` service is distributed across the two clusters,
call the `helloworld` service from another in-mesh `sleep` service.

1. Deploy the `sleep` service in both clusters:

    {{< text bash >}}
    $ kubectl apply --context=${MAIN_CLUSTER_CTX} -f @samples/sleep/sleep.yaml@ -n sample
    $ kubectl apply --context=${REMOTE_CLUSTER_CTX} -f @samples/sleep/sleep.yaml@ -n sample
    {{< /text >}}

1. Wait for the `sleep` service to start in each cluster:

    {{< text bash >}}
    $ kubectl get pod --context=${MAIN_CLUSTER_CTX} -n sample -l app=sleep
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pod --context=${REMOTE_CLUSTER_CTX} -n sample -l app=sleep
    sleep-754684654f-dzl9j           2/2     Running   0          5s
    {{< /text >}}

1. Call the `helloworld.sample` service several times from the main cluster:

    {{< text bash >}}
    $ kubectl exec --context=${MAIN_CLUSTER_CTX} -it -n sample -c sleep $(kubectl get pod --context=${MAIN_CLUSTER_CTX} -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

1. Call the `helloworld.sample` service several times from the remote cluster:

    {{< text bash >}}
    $ kubectl exec --context=${REMOTE_CLUSTER_CTX} -it -n sample -c sleep $(kubectl get pod --context=${REMOTE_CLUSTER_CTX} -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

If set up correctly, the traffic to the `helloworld.sample` service will be distributed between instances
on the main and remote clusters resulting in responses with either `v1` or `v2` in the body:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

You can also verify the IP addresses used to access the endpoints by printing the log of the sleep's `istio-proxy` container.

{{< text bash >}}
$ kubectl logs --context=${MAIN_CLUSTER_CTX} -n sample $(kubectl get pod --context=${MAIN_CLUSTER_CTX} -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

In the main cluster, the gateway IP of the remote cluster (`192.23.120.32:15443`) is logged when v2 was called and
the instance IP in the main cluster (`10.10.0.90:5000`) is logged when v1 was called.

{{< text bash >}}
$ kubectl logs --context=${REMOTE_CLUSTER_CTX} -n sample $(kubectl get pod --context=${REMOTE_CLUSTER_CTX} -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2019-05-25T08:06:11.468Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 177 176 "-" "curl/7.60.0" "58cfb92b-b217-4602-af67-7de8f63543d8" "helloworld.sample:5000" "192.168.1.246:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36840 -
[2019-05-25T08:06:12.834Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 181 180 "-" "curl/7.60.0" "ce480b56-fafd-468b-9996-9fea5257cb1e" "helloworld.sample:5000" "10.32.0.9:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36886 -
{{< /text >}}

In the remote cluster, the gateway IP of the main cluster (`192.168.1.246:15443`) is logged when v1 was called and
the instance IP in remote cluster (`10.32.0.9:5000`) is logged when v2 was called.

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

To uninstall the remote cluster run the following command:

{{< text bash >}}
$ istioctl --context=${REMOTE_CLUSTER_CTX} manifest generate <your original remote configuration> | \
    kubectl delete -f -

$ istioctl x create-remote-secret --context=${REMOTE_CLUSTER_CTX} --name ${REMOTE_CLUSTER_NAME} | \
    kubectl delete -f - --context=${MAIN_CLUSTER_CTX}
{{< /text >}}
