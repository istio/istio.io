---
title: Egress Gateways
description: Describes how to configure Istio to direct traffic to external services through a dedicated gateway.
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
This example does not work in Minikube.
{{</warning>}}

The [Accessing External Services](/docs/tasks/traffic-management/egress/egress-control) task shows how to configure
Istio to allow access to external HTTP and HTTPS services from applications inside the mesh.
There, the external services are called directly from the client sidecar.
This example also shows how to configure Istio to call external services, although this time
indirectly via a dedicated _egress gateway_ service.

Istio uses [ingress and egress gateways](/docs/reference/config/networking/gateway/)
to configure load balancers executing at the edge of a service mesh.
An ingress gateway allows you to define entry points into the mesh that all incoming traffic flows through.
Egress gateway is a symmetrical concept; it defines exit points from the mesh. Egress gateways allow
you to apply Istio features, for example, monitoring and route rules, to traffic exiting the mesh.

## Use case

Consider an organization that has a strict security requirement that all traffic leaving
the service mesh must flow through a set of dedicated nodes. These nodes will run on dedicated machines,
separated from the rest of the nodes running applications in the cluster. These special nodes will serve
for policy enforcement on the egress traffic and will be monitored more thoroughly than other nodes.

Another use case is a cluster where the application nodes don't have public IPs, so the in-mesh services that run
on them cannot access the Internet. Defining an egress gateway, directing all the egress traffic through it, and
allocating public IPs to the egress gateway nodes allows the application nodes to access external services in a
controlled way.

{{< boilerplate gateway-api-gamma-support >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    {{< tip >}}
    The egress gateway and access logging will be enabled if you install the `demo`
    [configuration profile](/docs/setup/additional-setup/config-profiles/).
    {{< /tip >}}

*   Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for sending requests.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Set the `SOURCE_POD` environment variable to the name of your source pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

    {{< warning >}}
    The instructions in this task create a destination rule for the egress gateway in the `default` namespace
    and assume that the client, `SOURCE_POD`, is also running in the `default` namespace.
    If not, the destination rule will not be found on the
    [destination rule lookup path](/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)
    and the client requests will fail.
    {{< /warning >}}

*   [Enable Envoy’s access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)
    if not already enabled. For example, using `istioctl`:

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

## Deploy Istio egress gateway

{{< tip >}}
Egress gateways are [deployed automatically](/docs/tasks/traffic-management/ingress/gateway-api/#deployment-methods)
when using Gateway API to configure them. You can skip this section if you are using the `Gateway API` instructions
in the following sections.
{{< /tip >}}

1.  Check if the Istio egress gateway is deployed:

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    If no pods are returned, deploy the Istio egress gateway by performing the following step.

1.  If you used an `IstioOperator` CR to install Istio, add the following fields to your configuration:

    {{< text yaml >}}
    spec:
      components:
        egressGateways:
        - name: istio-egressgateway
          enabled: true
    {{< /text >}}

    Otherwise, add the equivalent settings to your original `istioctl install` command, for example:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set "components.egressGateways[0].name=istio-egressgateway" \
                       --set "components.egressGateways[0].enabled=true"
    {{< /text >}}

## Egress gateway for HTTP traffic

First create a `ServiceEntry` to allow direct traffic to an external service.

1.  Define a `ServiceEntry` for `edition.cnn.com`.

    {{< warning >}}
    `DNS` resolution must be used in the service entry below. If the resolution is `NONE`, the gateway will
    direct the traffic to itself in an infinite loop. This is because the gateway receives a request with the original
    destination IP address which is equal to the service IP of the gateway (since the request is directed by sidecar
    proxies to the gateway).

    With `DNS` resolution, the gateway performs a DNS query to get an IP address of the external service and directs
    the traffic to that IP address.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly by sending an HTTP request to [http://edition.cnn.com/politics](http://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    The output should be the same as in the
    [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/) example,
    without TLS origination.

1.  Create an egress `Gateway` for _edition.cnn.com_, port 80, and a destination rule for
    traffic directed to the egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
To direct multiple hosts through an egress gateway, you can include a list of hosts, or use `*` to match all, in the `Gateway`.
The `subset` field in the `DestinationRule` should be reused for the additional hosts.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Configure route rules to direct traffic from the sidecars to the egress gateway and from the egress gateway
    to the external service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Resend the HTTP request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    The output should be the same as in the step 2.

6)  Check the log of the egress gateway pod for a line corresponding to our request.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
{{< /text >}}

{{< tip >}}
If [mutual TLS Authentication](/docs/tasks/security/authentication/authn-policy/) is enabled, and you have issues connecting to the egress gateway, run the following command to verify the certificate is correct:

{{< text bash >}}
$ istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< tip >}}
If [mutual TLS Authentication](/docs/tasks/security/authentication/authn-policy/) is enabled, and you have issues connecting to the egress gateway, run the following command to verify the certificate is correct:

{{< text bash >}}
$ istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

Note that you only redirected the HTTP traffic from port 80 through the egress gateway.
The HTTPS traffic to port 443 went directly to _edition.cnn.com_.

### Cleanup HTTP gateway

Remove the previous definitions before proceeding to the next step:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Egress gateway for HTTPS traffic

In this section you direct HTTPS traffic (TLS originated by the application) through an egress gateway.
You need to specify port 443 with protocol `TLS` in a corresponding `ServiceEntry` and egress `Gateway`.

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly by sending an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

1.  Create an egress `Gateway` for _edition.cnn.com_, a destination rule and a virtual service
    to direct the traffic through the egress gateway and from the egress gateway to the external service.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
To direct multiple hosts through an egress gateway, you can include a list of hosts, or use `*` to match all, in the `Gateway`.
The `subset` field in the `DestinationRule` should be reused for the additional hosts.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics).
    The output should be the same as before.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

5)  Check the log of the egress gateway's proxy.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Cleanup HTTPS gateway

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete tlsroute direct-cnn-to-egress-gateway
$ kubectl delete tlsroute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Additional security considerations

Note that defining an egress `Gateway` in Istio does not in itself provides any special treatment for the nodes
on which the egress gateway service runs. It is up to the cluster administrator or the cloud provider to deploy
the egress gateways on dedicated nodes and to introduce additional security measures to make these nodes more
secure than the rest of the mesh.

Istio *cannot securely enforce* that all egress traffic actually flows through the egress gateways. Istio only
enables such flow through its sidecar proxies. If attackers bypass the sidecar proxy, they could directly access
external services without traversing the egress gateway. Thus, the attackers escape Istio's control and monitoring.
The cluster administrator or the cloud provider must ensure that no traffic leaves the mesh bypassing the egress
gateway. Mechanisms external to Istio must enforce this requirement. For example, the cluster administrator
can configure a firewall to deny all traffic not coming from the egress gateway.
The [Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can
also forbid all the egress traffic not originating from the egress gateway (see
[the next section](#apply-kubernetes-network-policies) for an example).
Additionally, the cluster administrator or the cloud provider can configure the network to ensure application nodes can
only access the Internet via a gateway. To do this, the cluster administrator or the cloud provider can prevent the
allocation of public IPs to pods other than gateways and can configure NAT devices to drop packets not originating at
the egress gateways.

## Apply Kubernetes network policies

This section shows you how to create a
[Kubernetes network policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to prevent
bypassing of the egress gateway. To test the network policy, you create a namespace, `test-egress`, deploy
the [sleep]({{< github_tree >}}/samples/sleep) sample to it, and then attempt to send requests to a gateway-secured
external service.

1)  Follow the steps in the
    [Egress gateway for HTTPS traffic](#egress-gateway-for-https-traffic) section.

2)  Create the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

3)  Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample to the `test-egress` namespace.

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

4)  Check that the deployed pod has a single container with no Istio sidecar attached:

    {{< text bash >}}
    $ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

5)  Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics) from the `sleep` pod in
    the `test-egress` namespace. The request will succeed since you did not define any restrictive policies yet.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

6)  Label the namespaces where the Istio control plane and egress gateway are running.
    If you deployed Istio in the `istio-system` namespace, the command is:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
$ kubectl label namespace default gateway=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7)  Label the `kube-system` namespace.

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

8)  Define a `NetworkPolicy` to limit the egress traffic from the `test-egress` namespace to traffic destined to
    the control plane, gateway, and to the `kube-system` DNS service (port 53).

    {{< warning >}}
    [Network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
    are implemented by the network plugin in your Kubernetes cluster.
    Depending on your test cluster, the traffic may not be blocked in the following
    step.
    {{< /warning >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

9)  Resend the previous HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it
    should fail since the traffic is blocked by the network policy. Note that the `sleep` pod cannot bypass
    the egress gateway. The only way it can access `edition.cnn.com` is by using an Istio sidecar proxy and by
    directing the traffic to the egress gateway. This setting demonstrates that even if some malicious pod manages to
    bypass its sidecar proxy, it will not be able to access external sites and will be blocked by the network policy.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -v -sS https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

10) Now inject an Istio sidecar proxy into the `sleep` pod in the `test-egress` namespace by first enabling
    automatic sidecar proxy injection in the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

11) Then redeploy the `sleep` deployment:

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

12) Check that the deployed pod has two containers, including the Istio sidecar proxy (`istio-proxy`):

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
sleep istio-proxy
{{< /text >}}

Before proceeding, you'll need to create a similar destination rule as the one used for the `sleep` pod in the `default` namespace,
to direct the `test-egress` namespace traffic through the egress gateway:

{{< text bash >}}
$ kubectl apply -n test-egress -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
sleep istio-proxy
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

13) Send an HTTPS request to [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it should succeed
    since the traffic flows to the egress gateway is allowed by the
    Network Policy you defined. The gateway then forwards the traffic to `edition.cnn.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -sS -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

14) Check the log of the egress gateway's proxy.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

If Istio is deployed in the `istio-system` namespace, the command to print the log is:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Access the log corresponding to the egress gateway using the Istio-generated pod label:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504837 46 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Cleanup network policies

1.  Delete the resources created in this section:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
$ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl label namespace default gateway-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Follow the steps in the [Cleanup HTTPS gateway](#cleanup-https-gateway) section.

## Cleanup

Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
