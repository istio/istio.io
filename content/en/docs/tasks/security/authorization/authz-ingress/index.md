---
title: Authorization on Ingress Gateway
description: How to set up access control on an ingress gateway.
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
owner: istio/wg-security-maintainers
test: yes
---

This task shows you how to enforce access control on an Istio ingress gateway
using an authorization policy.

An Istio authorization policy supports IP-based allow lists or deny lists as well as
the attribute-based allow lists or deny lists previously provided by Mixer policy.
The Mixer policy is deprecated in 1.5 and not recommended for production use.

## Before you begin

Before you begin this task, do the following:

* Read the [Authorization conceptual documentation](/docs/concepts/security/#authorization).

* Install Istio using the [Istio installation guide](/docs/setup/install/istioctl/).

* Deploy a workload, `httpbin` in a namespace, for example `foo`, and expose it
through the Istio ingress gateway with this command:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin-gateway.yaml@) -n foo
    {{< /text >}}

* Turn on RBAC debugging in Envoy for the ingress gateway:

    {{< text bash >}}
    $ kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
    {{< /text >}}

* Verify that the `httpbin` workload and ingress gateway are working as expected using this command:

    {{< text bash >}}
    $ curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output, retry after a few seconds.
Caching and propagation overhead can cause a delay.
{{< /warning >}}

## Getting traffic into Kubernetes and Istio

* All methods of getting traffic into Kubernetes involve opening a port on all worker nodes.  The main features that accomplish this are the `NodePort` service and the `LoadBalancer` service.  Even the Kubernetes `Ingress` resource must be backed by an Ingress controller that will create either a `NodePort` or a `LoadBalancer` service.

* A `NodePort` just opens up a port in the range 30000-32767 on each worker node and uses a label selector to identify which Pods to send the traffic to.  You have to manually create some kind of load balancer in front of your worker nodes or use Round-Robin DNS.

* A `LoadBalancer` is just like a `NodePort`, except it also creates an environment specific external load balancer to handle distributing traffic to the worker nodes.  For example, in AWS EKS, the `LoadBalancer` service will create an ELB with your worker nodes as targets.  If your Kubernetes environment does not have a `LoadBalancer` implementation, then it will just behave like a `NodePort`.  An Istio ingress gateway creates a `LoadBalancer` service.

* What if the Pod that is handling traffic from the `NodePort` or `LoadBalancer` isn't running on the worker node that received the traffic?  Kubernetes has its own internal proxy called kube-proxy that receives the packets and forwards them to the correct node.

## Source IP address of the original client

* If a packet goes through an external load balancer and/or kube-proxy, then the original source IP address of the client is lost.  There are a few ways to handle this if you need the original client IP for logging or security purposes:

      1. If you are using an HTTP/HTTPS external load balancer, it can put the original client IP address in the X-Forwarded-For header.  Istio can extract the client IP address from this header with some configuration.  See [Configuring Gateway Network Topology](/docs/ops/configuration/traffic-management/network-topologies/). Quick example if using a single load balancer in front of Kubernetes:

        {{< text yaml >}}
        apiVersion: install.istio.io/v1alpha1
        kind: IstioOperator
        spec:
          meshConfig:
            accessLogEncoding: JSON
            accessLogFile: /dev/stdout
            defaultConfig:
              gatewayTopology:
                numTrustedProxies: 1
        {{< /text >}}

      1. If you are using a TCP external load balancer, it can use the [Proxy Protocol](https://www.haproxy.com/blog/haproxy/proxy-protocol/) to embed the original client IP address in the packet data.  Both the external load balancer and the Istio ingress gateway must support the proxy protocol for it to work.  In Istio, you can enable it with an `EnvoyFilter` like below:

        {{< text yaml >}}
        apiVersion: networking.istio.io/v1alpha3
        kind: EnvoyFilter
        metadata:
          name: proxy-protocol
          namespace: istio-system
        spec:
          workloadSelector:
            labels:
              istio: ingressgateway
          configPatches:
          - applyTo: LISTENER
            patch:
              operation: MERGE
              value:
                listener_filters:
                - name: envoy.listener.proxy_protocol
        {{< /text >}}

        Here is a sample of the `IstioOperator` that shows how to configure the Istio ingress gateway on AWS EKS to support the Proxy Protocol:

        {{< text yaml >}}
        apiVersion: install.istio.io/v1alpha1
        kind: IstioOperator
        spec:
          meshConfig:
            accessLogEncoding: JSON
            accessLogFile: /dev/stdout
          components:
            ingressGateways:
            - enabled: true
              k8s:
                hpaSpec:
                  maxReplicas: 10
                  minReplicas: 5
                serviceAnnotations:
                  service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
                  service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
                  service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: elb-logs
                  service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: k8sELBIngressGW
                  service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
                affinity:
                  podAntiAffinity:
                    preferredDuringSchedulingIgnoredDuringExecution:
                    - podAffinityTerm:
                        labelSelector:
                          matchLabels:
                            istio: ingressgateway
                        topologyKey: failure-domain.beta.kubernetes.io/zone
                      weight: 1
              name: istio-ingressgateway
        {{< /text >}}

      1. If you are using a Layer 4 load balancer that preserves the client IP address (AWS Network Load Balancer, GCP External Network Load Balancer) or you are using Round-Robin DNS, then you can also preserve the client IP inside Kubernetes by bypassing kube-proxy and preventing it from sending traffic to other nodes.  **However, you must run an ingress gateway pod on every node.** If you don't, then any node that receives traffic and doesn't have an ingress gateway will drop the traffic. See [Source IP for Services with `Type=NodePort`](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)
    for more information. Update the ingress gateway to set `externalTrafficPolicy: local` to preserve the
    original client source IP on the ingress gateway using the following command:

        {{< text  bash >}}
        $ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
        {{< /text >}}

## IP-based allow list and deny list

**`ipBlocks` vs `remoteIpBlocks`:** If you are using the X-Forwarded-For HTTP header or the Proxy Protocol to determine the original client IP address, then you should use `remoteIpBlocks` in your `AuthorizationPolicy`. If you are using `externalTrafficPolicy: local`, then you should use `ipBlocks` in your `AuthorizationPolicy`.

1.  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    to define the `INGRESS_HOST` and `INGRESS_PORT` environment variables.

1. The following command creates the authorization policy, `ingress-policy`, for
the Istio ingress gateway. The following policy sets the `action` field to `ALLOW` to
allow the IP addresses specified in the `ipBlocks` to access the ingress gateway.
IP addresses not in the list will be denied. The `ipBlocks` supports both single IP address and CIDR notation.
Create the authorization policy:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
            ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
    EOF
    {{< /text >}}

1. Here is the same policy, but using `remoteIpBlocks` instead of `ipBlocks`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
            remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Find your original client IP address if you don't know it and assign it to a variable:

    {{< text bash >}}
    $ kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done
    2020-10-27T18:06:51.650243Z debug envoy rbac checking request: requestedServerName: , sourceIP: 10.233.33.91:31236, directRemoteIP: 10.233.33.91:31236, remoteIP: 192.168.10.15:0,localAddress: 10.233.22.111:8443, ssl: uriSanPeerCertificate: , dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin'
    {{< /text >}}

    If you are using X-Forwarded-For or the Proxy Protocol, then your client IP address is in the `remoteIP` field.  Otherwise, it is the `directRemoteIP` field.

    {{< text bash >}}
    $ export CLIENT_IP=192.168.10.15
    {{< /text >}}

1. Update the `ingress-policy` to include your client IP address:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
            ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
    EOF
    {{< /text >}}

1. With `remoteIpBlocks`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
            remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is allowed:

    {{< text bash >}}
    $ curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Update the `ingress-policy` authorization policy to set
the `action` key to `DENY` so that the IP addresses specified in the `ipBlocks` are
not allowed to access the ingress gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: DENY
      rules:
      - from:
        - source:
            ipBlocks: ["$CLIENT_IP"]
    EOF
    {{< /text >}}

1. With `remoteIpBlocks`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: ingress-policy
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: DENY
      rules:
      - from:
        - source:
            remoteIpBlocks: ["$CLIENT_IP"]
    EOF
    {{< /text >}}

1. Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. You could use an online proxy service to access the ingress gateway using a
different client IP to verify the request is allowed.

1. If you are not getting the responses you expect, view the ingress gateway logs which should show RBAC debugging information:

    {{< text bash >}}
    $ kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
    {{< /text >}}

## Clean up

1. Remove the namespace `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. Remove the authorization policy:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy ingress-policy -n istio-system
    {{< /text >}}