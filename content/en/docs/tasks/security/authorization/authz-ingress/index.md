---
title: Authorization on Ingress Gateway
description: How to set up access control on an ingress gateway.
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
owner: istio/wg-security-maintainers
test: yes
---

This task shows you how to enforce IP-based access control on an Istio ingress gateway using an authorization policy.

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
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
    {{< /text >}}

*  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    to define the `INGRESS_HOST` and `INGRESS_PORT` environment variables.

* Verify that the `httpbin` workload and ingress gateway are working as expected using this command:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
If you don’t see the expected output, retry after a few seconds.
Caching and propagation overhead can cause a delay.
{{< /warning >}}

## Getting traffic into Kubernetes and Istio

All methods of getting traffic into Kubernetes involve opening a port on all worker nodes.  The main features that accomplish this are the `NodePort` service and the `LoadBalancer` service.  Even the Kubernetes `Ingress` resource must be backed by an Ingress controller that will create either a `NodePort` or a `LoadBalancer` service.

* A `NodePort` just opens up a port in the range 30000-32767 on each worker node and uses a label selector to identify which Pods to send the traffic to.  You have to manually create some kind of load balancer in front of your worker nodes or use Round-Robin DNS.

* A `LoadBalancer` is just like a `NodePort`, except it also creates an environment specific external load balancer to handle distributing traffic to the worker nodes.  For example, in AWS EKS, the `LoadBalancer` service will create a Classic ELB with your worker nodes as targets. If your Kubernetes environment does not have a `LoadBalancer` implementation, then it will just behave like a `NodePort`.  An Istio ingress gateway creates a `LoadBalancer` service.

What if the Pod that is handling traffic from the `NodePort` or `LoadBalancer` isn't running on the worker node that received the traffic?  Kubernetes has its own internal proxy called kube-proxy that receives the packets and forwards them to the correct node.

## Source IP address of the original client

If a packet goes through an external proxy load balancer and/or kube-proxy, then the original source IP address of the client is lost.  Below are some strategies for preserving the original client IP for logging or security purposes.

{{< tabset category-name="lb" >}}

{{< tab name="TCP/UDP Proxy Load Balancer" category-value="proxy" >}}

{{< warning >}}
A critical [bug](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0) has been identified in Envoy that the proxy protocol downstream address is restored incorrectly for non-HTTP connections.

Please DO NOT USE the `remoteIpBlocks` field and `remote_ip` attribute with proxy protocol on non-HTTP connections until a newer version of Istio is released with a proper fix.

Note that Istio doesn't support the proxy protocol and it can be enabled only with the `EnvoyFilter` API and should be used at your own risk.
{{< /warning >}}

If you are using a TCP/UDP Proxy external load balancer (AWS Classic ELB), it can use the [Proxy Protocol](https://www.haproxy.com/blog/haproxy/proxy-protocol/) to embed the original client IP address in the packet data.  Both the external load balancer and the Istio ingress gateway must support the proxy protocol for it to work.  In Istio, you can enable it with an `EnvoyFilter` like below:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio: ingressgateway
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

{{< /tab >}}

{{< tab name="Network Load Balancer" category-value="network" >}}

If you are using a TCP/UDP network load balancer that preserves the client IP address (AWS Network Load Balancer, GCP External Network Load Balancer, Azure Load Balancer) or you are using Round-Robin DNS, then you can also preserve the client IP inside Kubernetes by bypassing kube-proxy and preventing it from sending traffic to other nodes.  **However, you must run an ingress gateway pod on every node.** If you don't, then any node that receives traffic and doesn't have an ingress gateway will drop the traffic. See [Source IP for Services with `Type=NodePort`](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)
for more information. Update the ingress gateway to set `externalTrafficPolicy: Local` to preserve the
original client source IP on the ingress gateway using the following command:

{{< text bash >}}
$ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< tab name="HTTP/HTTPS Load Balancer" category-value="http" >}}

If you are using an HTTP/HTTPS external load balancer (AWS ALB, GCP ), it can put the original client IP address in the X-Forwarded-For header.  Istio can extract the client IP address from this header with some configuration.  See [Configuring Gateway Network Topology](/docs/ops/configuration/traffic-management/network-topologies/). Quick example if using a single load balancer in front of Kubernetes:

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

{{< /tab >}}

{{< /tabset >}}

For reference, here are the types of load balancers created by Istio with a `LoadBalancer` service on popular managed Kubernetes environments:

|Cloud Provider | Load Balancer Name            | Load Balancer Type
----------------|-------------------------------|-------------------
|AWS EKS        | Classic Elastic Load Balancer | TCP Proxy
|GCP GKE        | TCP/UDP Network Load Balancer | Network
|Azure AKS      | Azure Load Balancer           | Network
|DO DOKS        | Load Balancer                 | Network

{{< tip >}}
You can instruct AWS EKS to create a Network Load Balancer when you install Istio by using a `serviceAnnotation` like below:

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
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
{{< /text >}}

{{< /tip >}}

## IP-based allow list and deny list

**When to use `ipBlocks` vs. `remoteIpBlocks`:** If you are using the X-Forwarded-For HTTP header or the Proxy Protocol to determine the original client IP address, then you should use `remoteIpBlocks` in your `AuthorizationPolicy`. If you are using `externalTrafficPolicy: Local`, then you should use `ipBlocks` in your `AuthorizationPolicy`.

|Load Balancer Type |Source of Client IP   | `ipBlocks` vs. `remoteIpBlocks`
--------------------|----------------------|---------------------------
| TCP Proxy         | Proxy Protocol       | `remoteIpBlocks`
| Network           | packet source address| `ipBlocks`
| HTTP/HTTPS        | X-Forwarded-For      | `remoteIpBlocks`

* The following command creates the authorization policy, `ingress-policy`, for
the Istio ingress gateway. The following policy sets the `action` field to `ALLOW` to
allow the IP addresses specified in the `ipBlocks` to access the ingress gateway.
IP addresses not in the list will be denied. The `ipBlocks` supports both single IP address and CIDR notation.

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

Create the AuthorizationPolicy:

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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

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

{{< /tab >}}

{{< /tabset >}}

* Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* Update the `ingress-policy` to include your client IP address:

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

Find your original client IP address if you don't know it and assign it to a variable:

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

Find your original client IP address if you don't know it and assign it to a variable:

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

Create the AuthorizationPolicy:

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

{{< /tab >}}

{{< /tabset >}}

* Verify that a request to the ingress gateway is allowed:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* Update the `ingress-policy` authorization policy to set
the `action` key to `DENY` so that the IP addresses specified in the `ipBlocks` are
not allowed to access the ingress gateway:

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

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

{{< /tab >}}

{{< /tabset >}}

* Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* You could use an online proxy service to access the ingress gateway using a
different client IP to verify the request is allowed.

* If you are not getting the responses you expect, view the ingress gateway logs which should show RBAC debugging information:

    {{< text bash >}}
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
    {{< /text >}}

## Clean up

* Remove the namespace `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* Remove the authorization policy:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy ingress-policy -n istio-system
    {{< /text >}}
