---
title: Cluster-Aware Service Routing
description: Leveraging Istio's Split-horizon EDS to create a multicluster mesh.
weight: 85
keywords: [kubernetes,multicluster]
---

This example shows how to configure a multicluster mesh with a
[single control plane topology](/docs/concepts/multicluster-deployments/#single-control-plane-topology)
and using Istio's _Split-horizon EDS (Endpoints Discovery Service)_ feature (introduced in Istio 1.1) to
route service requests to remote clusters via an ingress gateway.
Split-horizon EDS enables Istio to route requests to different endpoints, depending on the location of the request source.

By following the instructions in this example, you will setup a two cluster mesh as shown in the following diagram:

  {{< image width="80%" ratio="36.01%"
  link="./diagram.svg"
  caption="Single Istio control plane topology spanning multiple Kubernetes clusters with Split-horizon EDS configured" >}}

The `local` cluster will run Istio Pilot and the other Istio control plane components while the `remote` cluster only runs Istio Citadel,
Sidecar Injector, and Ingress gateway.
No VPN connectivity nor direct network access between workloads in different clusters is required.

## Before you begin

In addition to the prerequisites for installing Istio, the following is required for this example:

* Two Kubernetes clusters (referred to as `local` and `remote`).

    {{< warning >}}
    The Kubernetes API server of the `remote` cluster MUST be accessible from the `local` cluster
    in order to run this configuration.
    {{< /warning >}}

* The `kubectl` command is used to access both the `local` and `remote` clusters with the `--context` flag.
  Use the following command to list your contexts:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* Export the following environment variables with the context names of your configuration:

    {{< text bash >}}
    $ export CTX_LOCAL=<KUBECONFIG_LOCAL_CONTEXT_NAME>
    $ export CTX_REMOTE=<KUBECONFIG_REMOTE_CONTEXT_NAME>
    {{< /text >}}

## Example multicluster setup

In this example you will install Istio with mutual TLS enabled for both the control plane and application pods.
For the shared root CA, you create a `cacerts` secret on both the `local` and `remote` clusters using the same Istio
certificate from the Istio samples directory.

The instructions, below, also set up the `remote` cluster with a selector-less service and an endpoint for `istio-pilot.istio-system`
that has the address of the `local` Istio ingress gateway.
This will be used to access the `local` pilot securely using the ingress gateway without mutual TLS termination.

### Setup the local cluster

1. Define the mesh networks:

    By default the `global.meshNetworks` value for Istio is empty but you will need to modify it to declare a new network for endpoints on
    the `remote` cluster. Modify `install/kubernetes/helm/istio/values.yaml` and add a `network2` declaration:

    {{< text yaml >}}
    meshNetworks:
        network2:
            endpoints:
            - fromRegistry: remote_kubecfg
            gateways:
            - address: 0.0.0.0
              port: 15443
    {{< /text >}}

    Note that the gateway address is set to `0.0.0.0`. This is a temporary placeholder value that will
    later be updated to the value of the public IP of the `remote` cluster gateway after it is deployed
    in the following section.

1. Use Helm to create the Istio `local` deployment YAML:

    {{< text bash >}}
    $ helm template --name=istio --namespace=istio-system \
    --set global.mtls.enabled=true \
    --set security.selfSigned=false \
    --set global.controlPlaneSecurityEnabled=true \
    --set global.meshExpansion.enabled=true \
    install/kubernetes/helm/istio > istio-auth.yaml
    {{< /text >}}

1. Deploy Istio to the `local` cluster:

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL ns istio-system
    $ kubectl create --context=$CTX_LOCAL secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply --context=$CTX_LOCAL -f $i; done
    $ kubectl create --context=$CTX_LOCAL -f istio-auth.yaml
    {{< /text >}}

    Wait for Istio `local` pods to come up by checking their status:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_LOCAL -n istio-system
    {{< /text >}}

### Setup the remote cluster

1. Export the `local` gateway address:

    {{< text bash >}}
    $ export LOCAL_GW_ADDR=$(kubectl get --context=$CTX_LOCAL svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
    {{< /text >}}

    This command sets the value to the gateway's public IP, but note that you can set it to
    a DNS name instead, if you have one.

1. Use Helm to create the Istio `remote` deployment YAML:

    {{< text bash >}}
    $ helm template --name istio-remote --namespace=istio-system \
    --values install/kubernetes/helm/istio/values-istio-remote.yaml \
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

1. Deploy Istio to the `remote` cluster:

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE ns istio-system
    $ kubectl create --context=$CTX_REMOTE secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem --from-file=samples/certs/cert-chain.pem
    $ kubectl create --context=$CTX_REMOTE -f istio-remote-auth.yaml
    {{< /text >}}

    Wait for the Istio `remote` pods to come up by checking their status:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_REMOTE -n istio-system
    {{< /text >}}

1. Update the gateway address in the mesh network configuration:

    * Determine the `remote` gateway address:

        {{< text bash >}}
        $ kubectl get --context=$CTX_REMOTE svc --selector=app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"
        169.61.102.93
        {{< /text >}}

    * Edit the istio config map:

        {{< text bash >}}
        $ kubectl edit cm -n istio-system --context=$CTX_LOCAL istio
        {{< /text >}}

    * Change the gateway address of `network2` from `0.0.0.0` to the `remote` gateway address, save, and quit.

      Once saved, Pilot will automatically read the updated network configuration.

1. Prepare environment variables for building the `remote_kubecfg` file for the service account `istio-multi`:

    {{< text bash >}}
    $ CLUSTER_NAME=$(kubectl --context=$CTX_REMOTE config view --minify=true -o "jsonpath={.clusters[].name}")
    $ SERVER=$(kubectl --context=$CTX_REMOTE config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ SECRET_NAME=$(kubectl --context=$CTX_REMOTE get sa istio-multi -n istio-system -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get --context=$CTX_REMOTE secret ${SECRET_NAME} -n istio-system -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get --context=$CTX_REMOTE secret ${SECRET_NAME} -n istio-system -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< idea >}}
    An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.
    {{< /idea >}}

1. Create the `remote_kubecfg` file in the working directory:

    {{< text bash >}}
    $ cat <<EOF > remote_kubecfg
    apiVersion: v1
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
    kind: Config
    preferences: {}
    users:
      - name: ${CLUSTER_NAME}
        user:
          token: ${TOKEN}
    EOF
    {{< /text >}}

### Start watching the remote cluster

Execute the following commands to add and label the secret of the `remote` Kubernetes. After executing these commands the local Istio Pilot
will begin watching the `remote` cluster for services and instances, just as it does for the `local` cluster.

{{< text bash >}}
$ kubectl create --context=$CTX_LOCAL secret generic iks --from-file remote_kubecfg -n istio-system
$ kubectl label --context=$CTX_LOCAL secret iks istio/multiCluster=true -n istio-system
{{< /text >}}

Now that you have your `local` and `remote` clusters set up, you can deploy an example service.

## Example service

In this demo you will see how traffic to a service can be distributed across a local endpoint and a remote gateway.
As shown in the diagram, above, you will deploy two instances of the `helloworld` service, one on the `local` cluster and one on the `remote` cluster.
The difference between the two instances is the version of their `helloworld` image.

### Deploy helloworld v2 in remote

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE ns sample
    $ kubectl label --context=$CTX_REMOTE namespace sample istio-injection=enabled
    {{< /text >}}

1. Create a file `helloworld-v2.yaml` with the following content:

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld
      labels:
        app: helloworld
    spec:
      ports:
      - port: 5000
        name: http
      selector:
        app: helloworld
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v2
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld
            version: v2
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v2
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 5000
    {{< /text >}}

1. Deploy the file:

    {{< text bash >}}
    $ kubectl create --context=$CTX_REMOTE -f helloworld-v2.yaml -n sample
    {{< /text >}}

### Deploy helloworld v1 in local

1. Create a `sample` namespace with a sidecar auto-injection label:

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL ns sample
    $ kubectl label --context=$CTX_LOCAL namespace sample istio-injection=enabled
    {{< /text >}}

1. Create a file `helloworld-v1.yaml` with the following content:

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld
      labels:
        app: helloworld
    spec:
      ports:
      - port: 5000
        name: http
      selector:
        app: helloworld
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld
            version: v1
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v1
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 5000
    {{< /text >}}

1. Create a file `helloworld-gateway.yaml` with the following content:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: helloworld-gateway
      namespace: sample
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 15443
          name: tls
          protocol: TLS
        tls:
          mode: AUTO_PASSTHROUGH
        hosts:
        - "*"
    {{< /text >}}

    Although deployed locally, this Gateway instance will also affect the `remote` cluster by configuring it to passthrough
    incoming traffic to the relevant remote service (SNI-based) but keeping mutual TLS all the way from the source to destination sidecars.

1. Deploy the files:

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL -f helloworld-v1.yaml -n sample
    $ kubectl create --context=$CTX_LOCAL -f helloworld-gateway.yaml -n sample
    {{< /text >}}

### Split-horizon EDS in action

We will call the `helloworld.sample` service from another in-mesh `sleep` service.

1. Deploy the `sleep` service:

    {{< text bash >}}
    $ kubectl create --context=$CTX_LOCAL -f samples/sleep/sleep.yaml -n sample
    {{< /text >}}

1. Call the `helloworld.sample` service several times:

    {{< text bash >}}
    $ kubectl exec --context=$CTX_LOCAL -it -n sample -c sleep $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) -- curl helloworld.sample:5000/hello
    {{< /text >}}

If set up correctly, the traffic to the `helloworld.sample` service will be distributed between the local and the remote instances
resulting in responses with either `v1` or `v2` in the body:

{{< text sh >}}
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
{{< /text >}}

{{< text sh >}}
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
{{< /text >}}

You can also verify the IP addresses used to access the endpoints by printing the log of the sleep's `istio-proxy` container.

{{< text bash >}}
$ kubectl logs --context=$CTX_LOCAL -n sample $(kubectl get pod --context=$CTX_LOCAL -n sample -l app=sleep -o jsonpath={.items[0].metadata.name}) istio-proxy
[2018-11-25T12:37:52.077Z] "GET /hello HTTP/1.1" 200 - 0 60 190 189 "-" "curl/7.60.0" "6e096efe-f550-4dfa-8c8c-ba164baf4679" "helloworld.sample:5000" "192.23.120.32:15443" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59496 -
[2018-11-25T12:38:06.745Z] "GET /hello HTTP/1.1" 200 - 0 60 171 170 "-" "curl/7.60.0" "6f93c9cc-d32a-4878-b56a-086a740045d2" "helloworld.sample:5000" "10.10.0.90:5000" outbound|5000||helloworld.sample.svc.cluster.local - 10.20.194.146:5000 10.10.0.89:59646 -
{{< /text >}}

The remote gateway IP, `192.23.120.32:15443`, is logged when v2 was called and the local instance IP, `10.10.0.90:5000`, is logged when v1 was called.

## Cleanup

Execute the following commands to clean up the demo services __and__ the Istio components.

Cleanup the `remote` cluster:

{{< text bash >}}
$ kubectl delete --context=$CTX_REMOTE -f istio-remote-auth.yaml
$ kubectl delete --context=$CTX_REMOTE ns istio-system
$ kubectl delete --context=$CTX_REMOTE -f helloworld-v2.yaml -n sample
$ kubectl delete --context=$CTX_REMOTE ns sample
{{< /text >}}

Cleanup the `local` cluster:

{{< text bash >}}
$ kubectl delete --context=$CTX_LOCAL -f istio-auth.yaml
$ kubectl delete --context=$CTX_LOCAL ns istio-system
$ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete --context=$CTX_LOCAL -f $i; done
$ kubectl delete --context=$CTX_LOCAL -f helloworld-v1.yaml -n sample
$ kubectl delete --context=$CTX_LOCAL -f samples/sleep/sleep.yaml -n sample
$ kubectl delete --context=$CTX_LOCAL ns sample
{{< /text >}}