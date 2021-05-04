---
title: Install Istio with an External Control Plane
description: Install an external control plane and remote cluster.
weight: 80
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: yes
---

This guide walks you through the process of installing an {{< gloss >}}external control plane{{< /gloss >}}
and then connecting one or more {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}} to it.
The external control plane [deployment model](/docs/ops/deployment/deployment-models/#control-plane-models)
allows a mesh operator  to install and manage a control plane on an external cluster, separate from the data
plane cluster (or multiple clusters) comprising the mesh. This deployment model allows a clear separation
between mesh operators and mesh administrators. Mesh operators install and manage Istio control planes while mesh
admins only need to configure the mesh.

{{< image width="75%"
    link="external-controlplane.svg"
    caption="External control plane cluster and remote cluster"
    >}}

Envoy proxies (sidecars and gateways) running in the remote cluster access the external istiod via an ingress gateway
which exposes the endpoints needed for discovery, CA, injection, and validation.

While configuration and management of the external control plane is done by the mesh operator in the external cluster,
the first remote cluster connected to an external control plane serves as the config cluster for the mesh itself.
The mesh administrator will use the config cluster to configure the mesh resources (gateways, virtual services, etc.)
in addition to the mesh services themselves. The external control plane will remotely access this configuration from
the Kubernetes API server, as shown in the above diagram.

## Before you begin

### Clusters

This guide requires that you have two Kubernetes clusters with any of the
supported Kubernetes versions: {{< supported_kubernetes_versions >}}.

The first cluster will host the {{< gloss >}}external control plane{{< /gloss >}} installed in the
`external-istiod` namespace. An ingress gateway is also installed in the `istio-system` namespace to provide
cross-cluster access to the external control plane.

The second cluster is a {{< gloss >}}remote cluster{{< /gloss >}} that will run the mesh application workloads.
Its Kubernetes API server also provides the mesh configuration used by the external control plane (istiod)
to configure the workload proxies.

### API server access

The Kubernetes API server in the remote cluster must be accessible to the external
control plane cluster. Many cloud providers make API servers publicly accessible
via network load balancers (NLBs). If the API server is not directly accessible, you will
need to modify the installation procedure to enable access. For example, the
[east-west](https://en.wikipedia.org/wiki/East-west_traffic) gateway used in a
[multicluster configuration](#adding-clusters) could also be used to enable access
to the API server.

### Environment Variables

The following environment variables will be used throughout to simplify the instructions:

Variable | Description
-------- | -----------
`CTX_EXTERNAL_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the external control plane cluster.
`CTX_REMOTE_CLUSTER` | The context name in the default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) used for accessing the remote cluster.
`REMOTE_CLUSTER_NAME` | The name of the remote cluster.
`EXTERNAL_ISTIOD_ADDR` | The hostname for the ingress gateway on the external control plane cluster. This is used by the remote cluster to access the external control plane.
`SSL_SECRET_NAME` | The name of the secret that holds the TLS certs for the ingress gateway on the external control plane cluster.

Set the `CTX_EXTERNAL_CLUSTER`, `CTX_REMOTE_CLUSTER`, and `REMOTE_CLUSTER_NAME` now. You will set the others later.

{{< text syntax=bash snip_id=none >}}
$ export CTX_EXTERNAL_CLUSTER=<your external cluster context>
$ export CTX_REMOTE_CLUSTER=<your remote cluster context>
$ export REMOTE_CLUSTER_NAME=<your remote cluster name>
{{< /text >}}

## Cluster configuration

### Mesh operator steps

A mesh operator is responsible for installing and managing the external Istio control plane on the external cluster.
This includes configuring an ingress gateway on the external cluster, which allows the remote cluster to access the control plane,
and installing the sidecar injector webhook configuration on the remote cluster so that it will use the external control plane.

#### Set up a gateway in the external cluster

1. Create the Istio install configuration for the ingress gateway that will expose the external control plane ports to other clusters:

    {{< text bash >}}
    $ cat <<EOF > controlplane-gateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            k8s:
              service:
                ports:
                  - port: 15021
                    targetPort: 15021
                    name: status-port
                  - port: 15012
                    targetPort: 15012
                    name: tls-xds
                  - port: 15017
                    targetPort: 15017
                    name: tls-webhook
    EOF
    {{< /text >}}

    Then, install the gateway in the `istio-system` namespace of the external cluster:

    {{< text bash >}}
    $ istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. Run the following command to confirm that the ingress gateway is up and running:

    {{< text bash >}}
    $ kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                                   READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-9d4c7f5c7-7qpzz   1/1     Running   0          29s
    istiod-68488cd797-mq8dn                1/1     Running   0          38s
    {{< /text >}}

    You will notice an istiod deployment is also created in the `istio-system` namespace. This is used to configure the ingress gateway
    and is NOT the control plane used by remote clusters.

    {{< tip >}}
    This ingress gateway could be configured to host multiple external control planes, in different namespaces on the external cluster,
    although in this example you will only deploy a single external istiod in the `external-istiod` namespace.
    {{< /tip >}}

1. Configure your environment to expose the Istio ingress gateway service using a public hostname with TLS. Set the `EXTERNAL_ISTIOD_ADDR` environment variable to the hostname and `SSL_SECRET_NAME` environment variable to the secret that holds the TLS certs:

    {{< text syntax=bash snip_id=none >}}
    $ export EXTERNAL_ISTIOD_ADDR=<your external istiod host>
    $ export SSL_SECRET_NAME=<your external istiod secret>
    {{< /text >}}

#### Set up the control plane in the external cluster

1. Create the `external-istiod` namespace, which will be used to host the external control plane:

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. The control plane in the external cluster needs access to the remote cluster to discover services, endpoints,
    and pod attributes. Create a secret with credentials to access the remote cluster’s `kube-apiserver` and install
    it in the external cluster:

    {{< text bash >}}
    $ kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    $ istioctl x create-remote-secret \
      --context="${CTX_REMOTE_CLUSTER}" \
      --type=config \
      --namespace=external-istiod | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. Create the Istio configuration to install the control plane in the `external-istiod` namespace of the external cluster:

    {{< text syntax=bash snip_id=get_external_istiod_iop >}}
    $ cat <<EOF > external-istiod.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: empty
      meshConfig:
        rootNamespace: external-istiod
        defaultConfig:
          discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
          proxyMetadata:
            XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
            CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
      components:
        pilot:
          enabled: true
          k8s:
            overlays:
            - kind: Deployment
              name: istiod
              patches:
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: config-volume
                  configMap:
                    name: istio
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: inject-volume
                  configMap:
                    name: istio-sidecar-injector
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: config-volume
                  mountPath: /etc/istio/config
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: inject-volume
                  mountPath: /var/lib/istio/inject
            env:
            - name: INJECTION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: VALIDATION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: EXTERNAL_ISTIOD
              value: "true"
            - name: CLUSTER_ID
              value: ${REMOTE_CLUSTER_NAME}
      values:
        global:
          caAddress: $EXTERNAL_ISTIOD_ADDR:15012
          istioNamespace: external-istiod
          operatorManageWebhooks: true
          meshID: mesh1
    EOF
    {{< /text >}}

    Then, apply the Istio configuration on the external cluster:

    {{< text bash >}}
    $ istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

1. Confirm that the external istiod has been successfully deployed:

    {{< text bash >}}
    $ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                      READY   STATUS    RESTARTS   AGE
    istiod-779bd6fdcf-bd6rg   1/1     Running   0          70s
    {{< /text >}}

1. Create the Istio `Gateway`, `VirtualService`, and `DestinationRule` configuration to route traffic from the ingress
    gateway to the external control plane:

    {{< text syntax=bash snip_id=get_external_istiod_gateway_config >}}
    $ cat <<EOF > external-istiod-gw.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    metadata:
      name: external-istiod-gw
      namespace: external-istiod
    spec:
      selector:
        istio: ingressgateway
      servers:
        - port:
            number: 15012
            protocol: https
            name: https-XDS
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
        - port:
            number: 15017
            protocol: https
            name: https-WEBHOOK
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
    ---
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
       name: external-istiod-vs
       namespace: external-istiod
    spec:
        hosts:
        - $EXTERNAL_ISTIOD_ADDR
        gateways:
        - external-istiod-gw
        http:
        - match:
          - port: 15012
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 15012
        - match:
          - port: 15017
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 443
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: external-istiod-dr
      namespace: external-istiod
    spec:
      host: istiod.external-istiod.svc.cluster.local
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 15012
          tls:
            mode: SIMPLE
          connectionPool:
            http:
              h2UpgradePolicy: UPGRADE
        - port:
            number: 443
          tls:
            mode: SIMPLE
    EOF
    {{< /text >}}

    Then, apply the configuration on the external cluster:

    {{< text bash >}}
    $ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

#### Set up the remote cluster

1. Create the remote Istio install configuration, which installs the injection webhook that uses the
    external control plane's injector, instead of a locally deployed one. Because this cluster
    also serves as the config cluster, the Istio CRDs are also installed by setting `base.enabled`
    to `true`:

    {{< text syntax=bash snip_id=get_remote_config_cluster_iop >}}
    $ cat <<EOF > remote-config-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: external
      components:
        base:
          enabled: true
      values:
        global:
          istioNamespace: external-istiod
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/:ENV:cluster=${REMOTE_CLUSTER_NAME}:ENV:net=network1
    EOF
    {{< /text >}}

    Then, install the configuration on the remote cluster:

    {{< text bash >}}
    $ istioctl manifest generate -f remote-config-cluster.yaml | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

1. Confirm that the remote cluster's webhook configuration has been installed:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          6m24s
    {{< /text >}}

### Mesh admin steps

Now that Istio is up and running, a mesh administrator only needs to deploy and configure services in the mesh,
including gateways, if needed.

#### Deploy a sample application

1. Create, and label for injection, the `sample` namespace on the remote cluster:

    {{< text bash >}}
    $ kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy the `helloworld` (`v1`) and `sleep` samples:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. Wait a few seconds for the `helloworld` and `sleep` pods to be running with sidecars injected:

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
    NAME                             READY   STATUS    RESTARTS   AGE
    helloworld-v1-776f57d5f6-s7zfc   2/2     Running   0          10s
    sleep-64d7d56698-wqjnm           2/2     Running   0          9s
    {{< /text >}}

1. Send a request from the `sleep` pod to the `helloworld` service:

    {{< text bash >}}
    $ kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
        "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

#### Enable gateways

1. Enable an ingress gateway on the remote cluster:

    {{< text bash >}}
    $ cat <<EOF > istio-ingressgateway.yaml
    apiVersion: operator.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      profile: empty
      components:
        ingressGateways:
        - namespace: external-istiod
          name: istio-ingressgateway
          enabled: true
      values:
        gateways:
          istio-ingressgateway:
            injectionTemplate: gateway
    EOF
    $ istioctl install -f istio-ingressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. Enable an egress gateway, or other gateways, on the remote cluster (optional):

    {{< text bash >}}
    $ cat <<EOF > istio-egressgateway.yaml
    apiVersion: operator.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      profile: empty
      components:
        egressGateways:
        - namespace: external-istiod
          name: istio-egressgateway
          enabled: true
      values:
        gateways:
          istio-egressgateway:
            injectionTemplate: gateway
    EOF
    $ istioctl install -f istio-egressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. Confirm that the Istio ingress gateway is running:

    {{< text bash >}}
    $ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-7bcd5c6bbd-kmtl4   1/1     Running   0          8m4s
    {{< /text >}}

1. Expose the `helloworld` application on the ingress gateway:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld-gateway.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

1. Set the `GATEWAY_URL` environment variable
    (see [determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-  and-ports) for details):

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export INGRESS_PORT=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1. Confirm you can access the `helloworld` application through the ingress gateway:

    {{< text bash >}}
    $ curl -s "http://${GATEWAY_URL}/hello"
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

## Adding clusters to the mesh (optional) {#adding-clusters}

{{< boilerplate experimental >}}

This section shows you how to expand an existing external control plane mesh to multicluster by adding another remote cluster.
This allows you to easily distribute services and use [location-aware routing and fail over](/docs/tasks/traffic-management/locality-load-balancing/) to support high availability of your application.

{{< image width="75%"
    link="external-multicluster.svg"
    caption="External control plane with multiple remote clusters"
    >}}

Unlike the first remote cluster, the second and subsequent clusters added to the same external control plane do not
provide mesh config, but instead are only sources of endpoint configuration, just like remote clusters in a
[primary-remote](/docs/setup/install/multicluster/primary-remote_multi-network/) Istio multicluster configuration.

To proceed, you'll need another Kubernetes cluster for the second remote cluster of the mesh. Set the following
environment variables to the context name and cluster name of the cluster:

{{< text syntax=bash snip_id=none >}}
$ export CTX_SECOND_CLUSTER=<your second remote cluster context>
$ export SECOND_CLUSTER_NAME=<your second remote cluster name>
{{< /text >}}

### Register the new cluster

1. Create a secret with credentials to allow the control plane to access the endpoints on the second remote cluster
    and install it:

    {{< text bash >}}
    $ istioctl x create-remote-secret \
      --context="${CTX_SECOND_CLUSTER}" \
      --name="${SECOND_CLUSTER_NAME}" \
      --type=remote \
      --namespace=external-istiod | \
      kubectl apply -f - --context="${CTX_REMOTE_CLUSTER}" #TODO use --context="{CTX_EXTERNAL_CLUSTER}" when #31946 is fixed.
    {{< /text >}}

    Note that unlike the first remote cluster of the mesh, which also serves as the config cluster, the `--type` argument
    is set to `remote` this time, instead of `config`.

    {{< tip >}}
    Note that the secret can alternatively be applied in the remote (config) cluster, instead of the external cluster,
    because the external istiod is watching for additions in both clusters.
    {{< /tip >}}

1. Create the remote Istio install configuration, which installs the injection webhook that uses the
    external control plane's injector, instead of a locally deployed one:

    {{< text syntax=bash snip_id=get_second_config_cluster_iop >}}
    $ cat <<EOF > second-config-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: external
      values:
        global:
          istioNamespace: external-istiod
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/:ENV:cluster=${SECOND_CLUSTER_NAME}:ENV:net=network2
    EOF
    {{< /text >}}

    Then, install the configuration on the remote cluster:

    {{< text bash >}}
    $ istioctl manifest generate -f second-config-cluster.yaml | kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
    {{< /text >}}

1. Confirm that the remote cluster's webhook configuration has been installed:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_SECOND_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          4m13s
    {{< /text >}}

### Setup east-west gateways

1. Deploy east-west gateways on both remote clusters:

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --mesh mesh1 --cluster "${REMOTE_CLUSTER_NAME}" --network network1 > eastwest-gateway-1.yaml
    $ istioctl manifest generate -f eastwest-gateway-1.yaml \
        --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --mesh mesh1 --cluster "${SECOND_CLUSTER_NAME}" --network network2 > eastwest-gateway-2.yaml
    $ istioctl manifest generate -f eastwest-gateway-2.yaml \
        --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
    {{< /text >}}

1. Wait for the east-west gateways to be assigned external IP addresses:

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl --context="${CTX_SECOND_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.99   ...       51s
    {{< /text >}}

1. Expose services via the east-west gateways:

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" apply -n external-istiod -f \
        @samples/multicluster/expose-services.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ kubectl --context="${CTX_SECOND_CLUSTER}" apply -n external-istiod -f \
        @samples/multicluster/expose-services.yaml@
    {{< /text >}}

### Validate the installation

1. Create, and label for injection, the `sample` namespace on the remote cluster:

    {{< text bash >}}
    $ kubectl create --context="${CTX_SECOND_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_SECOND_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy the `helloworld` (`v2`) and `sleep` samples:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sample --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

1. Wait a few seconds for the `helloworld` and `sleep` pods to be running with sidecars injected:

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_SECOND_CLUSTER}"
    NAME                            READY   STATUS    RESTARTS   AGE
    helloworld-v2-54df5f84b-9hxgw   2/2     Running   0          10s
    sleep-557747455f-wtdbr          2/2     Running   0          9s
    {{< /text >}}

1. Send a request from the `sleep` pod to the `helloworld` service:

    {{< text bash >}}
    $ kubectl exec --context="${CTX_SECOND_CLUSTER}" -n sample -c sleep \
        "$(kubectl get pod --context="${CTX_SECOND_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    {{< /text >}}

1. Confirm that when accessing the `helloworld` application several times through the ingress gateway, both version `v1`
   and `v2` are now being called:

    {{< text bash >}}
    $ for i in {1..10}; do curl -s "http://${GATEWAY_URL}/hello"; done
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    ...
    {{< /text >}}
