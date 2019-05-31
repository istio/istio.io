---
title: Cluster-Aware Service Routing
description: Leveraging Istio's Split-horizon EDS to create a multicluster mesh.
weight: 85
keywords: [kubernetes,multicluster]
aliases:
    - /docs/examples/multicluster/split-horizon-eds/
---

This example shows how to configure a multicluster mesh with a
[single control plane topology](/docs/concepts/multicluster-deployments/#single-control-plane-topology)
and using Istio's _Split-horizon EDS (Endpoints Discovery Service)_ feature (introduced in Istio 1.1) to
route service requests to other clusters via their ingress gateway.
Split-horizon EDS enables Istio to route requests to different endpoints, depending on the location of the request source.

By following the instructions in this example, you will setup a two cluster mesh as shown in the following diagram:

  {{< image width="80%"
  link="./diagram.svg"
  caption="Single Istio control plane topology spanning multiple Kubernetes clusters with Split-horizon EDS configured" >}}

The primary cluster, `cluster1`, runs the full set of Istio control plane components while `cluster2` only runs Istio Citadel,
Sidecar Injector, and Ingress gateway.
No VPN connectivity nor direct network access between workloads in different clusters is required.

## Before you begin

In addition to the prerequisites for installing Istio, the following is required for this example:

* Two Kubernetes clusters (referred to as `cluster1` and `cluster2`).

    {{< warning >}}
    The Kubernetes API server of `cluster2` MUST be accessible from `cluster1` in order to run this configuration.
    {{< /warning >}}

{{< boilerplate kubectl-multicluster-contexts >}}

## Example multicluster setup

In this example you will install Istio with mutual TLS enabled for both the control plane and application pods.
For the shared root CA, you create a `cacerts` secret on both `cluster1` and `cluster2` clusters using the same Istio
certificate from the Istio samples directory.

The instructions, below, also set up `cluster2` with a selector-less service and an endpoint for `istio-pilot.istio-system`
that has the address of `cluster1` Istio ingress gateway.
This will be used to access pilot on `cluster1` securely using the ingress gateway without mutual TLS termination.

### Setup cluster 1 (primary)

1. Use Helm to create the Istio deployment YAML for `cluster1`:

    {{< warning >}}
    If you're not sure if your `helm` dependencies are up to date, update them using the
    command shown in [Helm installation steps](/docs/setup/kubernetes/install/helm/#installation-steps)
    before running the following command.
    {{< /warning >}}

    {{< text bash >}}
    $ helm template --name=istio --namespace=istio-system \
      --set global.mtls.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.proxy.accessLogFile="/dev/stdout" \
      --set global.meshExpansion.enabled=true \
      --set 'global.meshNetworks.network1.endpoints[0].fromRegistry'=Kubernetes \
      --set 'global.meshNetworks.network1.gateways[0].address'=0.0.0.0 \
      --set 'global.meshNetworks.network1.gateways[0].port'=443 \
      --set gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network1" \
      --set global.network="network1" \
      --set 'global.meshNetworks.network2.endpoints[0].fromRegistry'=n2-k8s-config \
      --set 'global.meshNetworks.network2.gateways[0].address'=0.0.0.0 \
      --set 'global.meshNetworks.network2.gateways[0].port'=443 \
      install/kubernetes/helm/istio > istio-auth.yaml
    {{< /text >}}

    {{< warning >}}
    Note that the gateway addresses are set to `0.0.0.0`. These are temporary placeholder values that will
    later be updated with the public IPs of the `cluster1` and `cluster2` gateways after they are deployed
    in the following section.
    {{< /warning >}}

1. Deploy Istio to `cluster1`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER1 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply --context=$CTX_CLUSTER1 -f $i; done
    $ kubectl create --context=$CTX_CLUSTER1 -f istio-auth.yaml
    {{< /text >}}

    Wait for the Istio pods on `cluster1` to become ready:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1 -n istio-system
    NAME                                      READY   STATUS      RESTARTS   AGE
    istio-citadel-9bbf9b4c8-nnmbt             1/1     Running     0          2m8s
    istio-cleanup-secrets-1.1.0-x9crw         0/1     Completed   0          2m12s
    istio-galley-868c5fff5d-9ph6l             1/1     Running     0          2m9s
    istio-ingressgateway-6c756547b-dwc78      1/1     Running     0          2m8s
    istio-pilot-54fcf8db8-sn9cn               2/2     Running     0          2m8s
    istio-policy-5fcbd55d8b-xhbpz             2/2     Running     2          2m8s
    istio-security-post-install-1.1.0-ww5zz   0/1     Completed   0          2m12s
    istio-sidecar-injector-6dcc9d5c64-7hnnl   1/1     Running     0          2m8s
    istio-telemetry-57875ffb6d-n2vmf          2/2     Running     3          2m8s
    prometheus-66c9f5694-8pccr                1/1     Running     0          2m8s
    {{< /text >}}

1. Create an ingress gateway to access service(s) in `cluster2`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f - <<EOF
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

    This `Gateway` configures 443 port to pass incoming traffic through to the target service specified in a
    request's SNI header, for SNI values of the _local_ top-level domain
    (i.e., the [Kubernetes DNS domain](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)).
    Mutual TLS connections will be used all the way from the source to the destination sidecar.

    Although applied to `cluster1`, this Gateway instance will also affect `cluster2` because both clusters communicate with the
    same Pilot.
1.  Determine the ingress IP and port for `cluster1`.

    1.   Set the current context of `kubectl` to `CTX_CLUSTER1`

        {{< text bash >}}
        $ export ORIGINAL_CONTEXT=$(kubectl config current-context)
        $ kubectl config use-context $CTX_CLUSTER1
        {{< /text >}}

    1.   Follow the instructions in
        [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports),
        to set the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment variables.

    1.  Restore the previous `kubectl` context:

        {{< text bash >}}
        $ kubectl config use-context $ORIGINAL_CONTEXT
        $ unset ORIGINAL_CONTEXT
        {{< /text >}}

    1.  Print the values of `INGRESS_HOST` and `SECURE_INGRESS_PORT`:

        {{< text bash >}}
        $ echo The ingress gateway of cluster1: address=$INGRESS_HOST, port=$SECURE_INGRESS_PORT
        {{< /text >}}

1.  Update the gateway address in the mesh network configuration. Edit the `istio` `ConfigMap`:

    {{< text bash >}}
    $ kubectl edit cm -n istio-system --context=$CTX_CLUSTER1 istio
    {{< /text >}}

    Update the gateway's address and port of `network1` to reflect the `cluster1` ingress host and port,
    respectively, then save and quit.

    Once saved, Pilot will automatically read the updated network configuration.

### Setup cluster 2

1. Export the `cluster1` gateway address:

    {{< text bash >}}
    $ export LOCAL_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}') && echo ${LOCAL_GW_ADDR}
    {{< /text >}}

    This command sets the value to the gateway's public IP and displays it.

    {{< warning >}}
    The command fails if the load balancer configuration doesn't include an IP address. The implementation of DNS name support is pending.
    {{< /warning >}}

1. Use Helm to create the Istio deployment YAML for `cluster2`:

    {{< text bash >}}
    $ helm template --name istio-remote --namespace=istio-system \
      --values @install/kubernetes/helm/istio/values-istio-remote.yaml@ \
      --set global.mtls.enabled=true \
      --set gateways.enabled=true \
      --set security.selfSigned=false \
      --set global.controlPlaneSecurityEnabled=true \
      --set global.createRemoteSvcEndpoints=true \
      --set global.remotePilotCreateSvcEndpoint=true \
      --set global.remotePilotAddress=${LOCAL_GW_ADDR} \
      --set global.remotePolicyAddress=${LOCAL_GW_ADDR} \
      --set global.remoteTelemetryAddress=${LOCAL_GW_ADDR} \
      --set gateways.istio-ingressgateway.env.ISTIO_META_NETWORK="network2" \
      --set global.network="network2" \
      install/kubernetes/helm/istio > istio-remote-auth.yaml
    {{< /text >}}

1. Deploy Istio to `cluster2`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns istio-system
    $ kubectl create --context=$CTX_CLUSTER2 secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ kubectl create --context=$CTX_CLUSTER2 -f istio-remote-auth.yaml
    {{< /text >}}

    Wait for the Istio pods on `cluster2`, except for `istio-ingressgateway`, to become ready:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio!=ingressgateway
    NAME                                     READY   STATUS      RESTARTS   AGE
    istio-citadel-75c8fcbfcf-9njn6           1/1     Running     0          12s
    istio-cleanup-secrets-1.1.0-vtp62        0/1     Completed   0          14s
    istio-sidecar-injector-cdb5d4dd5-rhks9   1/1     Running     0          12s
    {{< /text >}}

    {{< warning >}}
    `istio-ingressgateway` will not be ready until you configure the Istio control plane in `cluster1` to watch
    `cluster2`. You do it in the next section.
    {{< /warning >}}

1.  Determine the ingress IP and port for `cluster2`.

    1.   Set the current context of `kubectl` to `CTX_CLUSTER2`

        {{< text bash >}}
        $ export ORIGINAL_CONTEXT=$(kubectl config current-context)
        $ kubectl config use-context $CTX_CLUSTER2
        {{< /text >}}

    1.   Follow the instructions in
        [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports),
        to set the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment variables.

    1.  Restore the previous `kubectl` context:

        {{< text bash >}}
        $ kubectl config use-context $ORIGINAL_CONTEXT
        $ unset ORIGINAL_CONTEXT
        {{< /text >}}

    1.  Print the values of `INGRESS_HOST` and `SECURE_INGRESS_PORT`:

        {{< text bash >}}
        $ echo The ingress gateway of cluster2: address=$INGRESS_HOST, port=$SECURE_INGRESS_PORT
        {{< /text >}}

1.  Update the gateway address in the mesh network configuration. Edit the `istio` `ConfigMap`:

    {{< text bash >}}
    $ kubectl edit cm -n istio-system --context=$CTX_CLUSTER1 istio
    {{< /text >}}

    Update the gateway's address and port of `network2` to reflect the `cluster2` ingress host and port,
    respectively, then save and quit.

    Once saved, Pilot will automatically read the updated network configuration.

1. Prepare environment variables for building the `n2-k8s-config` file for the service account `istio-multi`:

    {{< text bash >}}
    $ CLUSTER_NAME=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].name}')
    $ SERVER=$(kubectl --context=$CTX_CLUSTER2 config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
    $ SECRET_NAME=$(kubectl --context=$CTX_CLUSTER2 get sa istio-multi -n istio-system -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['ca\.crt']}")
    $ TOKEN=$(kubectl get --context=$CTX_CLUSTER2 secret ${SECRET_NAME} -n istio-system -o jsonpath="{.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< idea >}}
    An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.
    {{< /idea >}}

1. Create the `n2-k8s-config` file in the working directory:

    {{< text bash >}}
    $ cat <<EOF > n2-k8s-config
    apiVersion: v1
    kind: Config
    clusters:
      - cluster:
          certificate-authority-data: ${CA_DATA}
          server: ${SERVER}
        name: ${CLUSTER_NAME}
    contexts:
      - context:
          cluster: ${CLUSTER_NAME}
          user: ${CLUSTER_NAME}
        name: ${CLUSTER_NAME}
    current-context: ${CLUSTER_NAME}
    users:
      - name: ${CLUSTER_NAME}
        user:
          token: ${TOKEN}
    EOF
    {{< /text >}}

### Start watching cluster 2

1.  Execute the following commands to add and label the secret of the `cluster2` Kubernetes.
    After executing these commands Istio Pilot on `cluster1` will begin watching `cluster2` for services and instances,
    just as it does for `cluster1`.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 secret generic n2-k8s-secret --from-file n2-k8s-config -n istio-system
    $ kubectl label --context=$CTX_CLUSTER1 secret n2-k8s-secret istio/multiCluster=true -n istio-system
    {{< /text >}}

1.  Wait for `istio-ingressgateway` to become ready:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER2 -n istio-system -l istio=ingressgateway
    NAME                                    READY     STATUS    RESTARTS   AGE
    istio-ingressgateway-5c667f4f84-bscff   1/1       Running   0          16m
    {{< /text >}}

Now that you have your `cluster1` and `cluster2` clusters set up, you can deploy an example service.

## Example service

In this demo you will see how traffic to a service can be distributed across the two clusters.
As shown in the diagram, above, you will deploy two instances of the `helloworld` service, one on `cluster1` and one on `cluster2`.
The difference between the two instances is the version of their `helloworld` image.

### Deploy helloworld v2 in cluster 2

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 ns sample
    $ kubectl label --context=$CTX_CLUSTER2 namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy `helloworld v2`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample
    {{< /text >}}

1. Confirm `helloworld v2` is running:

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER2 -n sample
    NAME                             READY     STATUS    RESTARTS   AGE
    helloworld-v2-7dd57c44c4-f56gq   2/2       Running   0          35s
    {{< /text >}}

### Deploy helloworld v1 in cluster 1

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 ns sample
    $ kubectl label --context=$CTX_CLUSTER1 namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy `helloworld v1`:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l app=helloworld -n sample
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample
    {{< /text >}}

1. Confirm `helloworld v1` is running:

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-d4557d97b-pv2hr   2/2       Running   0          40s
    {{< /text >}}

### Split-horizon EDS in action

We will call the `helloworld.sample` service from another in-mesh `sleep` service.

1. Deploy the `sleep` service in both clusters:

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -f @samples/sleep/sleep.yaml@ -n sample
    $ kubectl create --context=$CTX_CLUSTER2 -f @samples/sleep/sleep.yaml@ -n sample
    {{< /text >}}

1. Wait for the `sleep` service to start:

    {{< text bash >}}
    $ kubectl get po --context=$CTX_CLUSTER1 -n sample -l app=sleep
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    $ kubectl get po --context=$CTX_CLUSTER2 -n sample -l app=sleep
    sleep-754684654f-dzl9j           2/2     Running   0          5s
    {{< /text >}}

1. Call the `helloworld.sample` service several times from `cluster1` :

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 -it -n sample -c sleep $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

1. Call the `helloworld.sample` service several times from `cluster2` :

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 -it -n sample -c sleep $(kubectl get pod --context=$CTX_CLUSTER2 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl helloworld.sample:5000/hello
    {{< /text >}}

If set up correctly, the traffic to the `helloworld.sample` service will be distributed between instances on `cluster1` and `cluster2`
resulting in responses with either `v1` or `v2` in the body:

{{< text sh >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
{{< /text >}}

{{< text sh >}}
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

You can also verify the IP addresses used to access the endpoints by printing the log of the sleep's `istio-proxy` container.

{{< text bash >}}
$ kubectl logs --context=$CTX_CLUSTER1 -n sample $(kubectl get pod --context=$CTX_CLUSTER1 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

The gateway IP, `192.23.120.32:15443`, of `cluster2` is logged when v2 was called and the instance IP, `10.10.0.90:5000`, of `cluster1` is logged when v1 was called.

{{< text bash >}}
$ kubectl logs --context=$CTX_CLUSTER2 -n sample $(kubectl get pod --context=$CTX_CLUSTER2 -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') istio-proxy
[2019-05-25T08:06:11.468Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 177 176 "-" "curl/7.60.0" "58cfb92b-b217-4602-af67-7de8f63543d8" "helloworld.sample:5000" "192.168.1.246:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36840 -
[2019-05-25T08:06:12.834Z] "GET /hello HTTP/1.1" 200 - "-" 0 60 181 180 "-" "curl/7.60.0" "ce480b56-fafd-468b-9996-9fea5257cb1e" "helloworld.sample:5000" "10.32.0.9:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.107.117.235:5000 10.32.0.10:36886 -
{{< /text >}}

The gateway IP, `192.168.1.246:15443`, of `cluster1` is logged when v1 was called and the gateway IP, `10.32.0.9:5000`, of `cluster2` is logged when v2 was called.

## Cleanup

Execute the following commands to clean up the demo services __and__ the Istio components.

Cleanup the `cluster2` cluster:

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER2 -f istio-remote-auth.yaml
$ kubectl delete --context=$CTX_CLUSTER2 ns istio-system
$ kubectl delete --context=$CTX_CLUSTER2 ns sample
$ unset CTX_CLUSTER2 CLUSTER_NAME SERVER SECRET_NAME CA_DATA TOKEN INGRESS_HOST SECURE_INGRESS_PORT INGRESS_PORT
$ rm istio-remote-auth.yaml
{{< /text >}}

Cleanup the `cluster1` cluster:

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER1 -f istio-auth.yaml
$ kubectl delete --context=$CTX_CLUSTER1 ns istio-system
$ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete --context=$CTX_CLUSTER1 -f $i; done
$ kubectl delete --context=$CTX_CLUSTER1 ns sample
$ unset CTX_CLUSTER1
$ rm istio-auth.yaml n2-k8s-config
{{< /text >}}
