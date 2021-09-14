---
title: Ingress Gateways
description: Describes how to configure an Istio gateway to expose a service outside of the service mesh.
weight: 10
keywords: [traffic-management,ingress]
aliases:
    - /docs/tasks/ingress.html
    - /docs/tasks/ingress
owner: istio/wg-networking-maintainers
test: yes
---

Along with support for Kubernetes [Ingress](/docs/tasks/traffic-management/ingress/kubernetes-ingress/), Istio offers another configuration model, [Istio Gateway](/docs/reference/config/networking/gateway/). A `Gateway` provides more extensive customization and flexibility than `Ingress`, and allows Istio features such as monitoring and route rules to be applied to traffic entering the cluster.

This task describes how to configure Istio to expose a service outside of the service mesh using an Istio `Gateway`.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Make sure your current directory is the `istio` directory.

{{< boilerplate start-httpbin-service >}}

*   Determine the ingress IP and ports as described in the following subsection.

### Determining the ingress IP and ports

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers:

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
{{< /text >}}

If the `EXTERNAL-IP` value is set, your environment has an external load balancer that you can use for the ingress gateway.
If the `EXTERNAL-IP` value is `<none>` (or perpetually `<pending>`), your environment does not provide an external load balancer for the ingress gateway.
In this case, you can access the gateway using the service's [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport).

Choose the instructions corresponding to your environment:

{{< tabset category-name="gateway-ip" >}}

{{< tab name="external load balancer" category-value="external-lb" >}}

Follow these instructions if you have determined that your environment has an external load balancer.

Set the ingress IP and ports:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
$ export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
{{< /text >}}

{{< warning >}}
In certain environments, the load balancer may be exposed using a host name, instead of an IP address.
In this case, the ingress gateway's `EXTERNAL-IP` value will not be an IP address,
but rather a host name, and the above command will have failed to set the `INGRESS_HOST` environment variable.
Use the following command to correct the `INGRESS_HOST` value:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="node port" category-value="node-port" >}}

Follow these instructions if you have determined that your environment does not have an external load balancer,
so you need to use a node port instead.

Set the ingress ports:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
$ export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
{{< /text >}}

Setting the ingress IP depends on the cluster provider:

1.  _GKE:_

    {{< text bash >}}
    $ export INGRESS_HOST=worker-node-address
    {{< /text >}}

    You need to create firewall rules to allow the TCP traffic to the _ingressgateway_ service's ports.
    Run the following commands to allow the traffic for the HTTP port, the secure port (HTTPS) or both:

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
    $ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
    {{< /text >}}

1.  _IBM Cloud Kubernetes Service:_

    {{< text bash >}}
    $ ibmcloud ks workers --cluster cluster-name-or-id
    $ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
    {{< /text >}}

1.  _Minikube:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(minikube ip)
    {{< /text >}}

1.  _Docker For Desktop:_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _Other environments:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Configuring ingress using an Istio gateway

An ingress [Gateway](/docs/reference/config/networking/gateway/) describes a load balancer operating at the edge of the mesh that receives incoming HTTP/TCP connections.
It configures exposed ports, protocols, etc.
but, unlike [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/),
does not include any traffic routing configuration. Traffic routing for ingress traffic is instead configured
using Istio routing rules, exactly in the same way as for internal service requests.

Let's see how you can configure a `Gateway` on port 80 for HTTP traffic.

1.  Create an Istio `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "httpbin.example.com"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /status
        - uri:
            prefix: /delay
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

    You have now created a [virtual service](/docs/reference/config/networking/virtual-service/)
    configuration for the `httpbin` service containing two route rules that allow traffic for paths `/status` and
    `/delay`.

    The [gateways](/docs/reference/config/networking/virtual-service/#VirtualService-gateways) list
    specifies that only requests through your `httpbin-gateway` are allowed.
    All other external requests will be rejected with a 404 response.

    {{< warning >}}
    Internal requests from other services in the mesh are not subject to these rules
    but instead will default to round-robin routing. To apply these rules to internal calls as well,
    you can add the special value `mesh` to the list of `gateways`. Since the internal hostname for the
    service is probably different (e.g., `httpbin.default.svc.cluster.local`) from the external one,
    you will also need to add it to the `hosts` list. Refer to the
    [operations guide](/docs/ops/common-problems/network-issues#route-rules-have-no-effect-on-ingress-gateway-requests)
    for more details.
    {{< /warning >}}

1.  Access the _httpbin_ service using _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Note that you use the `-H` flag to set the _Host_ HTTP header to
    "httpbin.example.com". This is needed because your ingress `Gateway` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Configuring ingress routing based on JWT claims

The Istio ingress gateway also supports routing based on authenticated JWT, which is useful for routing based on end user
identity and more secure compared using the unauthenticated HTTP attributes (e.g. path or header).

This section describes how to configure the ingress gateway to route based on JWT claims.

1.  In order to route based on JWT claims, first create the request authentication to enable JWT validation:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: RequestAuthentication
    metadata:
      name: ingress-jwt
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          istio: ingressgateway
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    EOF
    {{< /text >}}

    The request authentication enables JWT validation on the Istio ingress gateway so that the validated JWT claims
    can later be used in the virtual service for routing purposes.

1. Update the virtual service to route based on validated JWT claims:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "httpbin.example.com"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /status
        - uri:
            prefix: /delay
        - uri:
            prefix: /headers
          headers:
            x-jwt-claim.groups: # "x-jwt-claim" is a reserved header for matching JWT claims only.
              exact: group1
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

    The virtual service uses the reserved header `x-jwt-claim` to match the validated JWT claims that are made available
    by the request authentication.

1. Validate the ingress gateway returns the HTTP code 404 without JWT:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

    You can also create the authorization policy to explicitly reject the request with HTTP code 403 when JWT is missing.

1. Validate the ingress gateway returns the HTTP code 401 with invalid JWT:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer some.invalid.token"
    HTTP/1.1 401 Unauthorized
    ...
    {{< /text >}}

    The 401 is returned by the request authentication because the JWT failed the validation.

1. Validate the ingress gateway routes the request with a valid JWT token that includes the claim `groups: group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode -
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_GROUP"
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

1. Validate the ingress gateway returns the HTTP code 404 with a valid JWT but does not include the claim `groups: group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_NO_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN_NO_GROUP" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_NO_GROUP"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

Note the `x-jwt-claim` is a reserved header name for matching the validated JWT claims only. It will not match the normal
HTTP headers. The first character after the reserved header is used as the separator between claims, for example,

* `x-jwt-claim.groups` or `x-jwt-claim-groups` matches the single claim `groups`
* `x-jwt-claim.key1.key2` or `x-jwt-claim-key1-key2` matches the nested claims `key1` and `key2`
* `x-jwt-claim.key-1.key-2` matches the nested claims `key-1` and `key-2` (the claim name includes `-`)
* `x-jwt-claim-key.1-key.2` matches the nested claims `key.1` and `key.2` (the claim name includes `.`)

The JWT claim match only supports claim of type string or list of strings, nested claims is also supported.

## Accessing ingress services using a browser

Entering the `httpbin` service URL in a browser won't work because you can't pass the _Host_ header
to a browser like you did with `curl`. In a real world situation, this is not a problem
because you configure the requested host properly and DNS resolvable. Thus, you use the host's domain name
in the URL, for example, `https://httpbin.example.com/status/200`.

To work around this problem for simple tests and demos, use a wildcard `*` value for the host in the `Gateway`
and `VirtualService` configurations. For example, if you change your ingress configuration to the following:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

You can then use `$INGRESS_HOST:$INGRESS_PORT` in the browser URL. For example,
`http://$INGRESS_HOST:$INGRESS_PORT/headers` will display all the headers that your browser sends.

## Understanding what happened

The `Gateway` configuration resources allow external traffic to enter the
Istio service mesh and make the traffic management and policy features of Istio
available for edge services.

In the preceding steps, you created a service inside the service mesh
and exposed an HTTP endpoint of the service to external traffic.

## Troubleshooting

1.  Inspect the values of the `INGRESS_HOST` and `INGRESS_PORT` environment variables. Make sure
they have valid values, according to the output of the following commands:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT"
    {{< /text >}}

1.  Check that you have no other Istio ingress gateways defined on the same port:

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1.  Check that you have no Kubernetes Ingress resources defined on the same IP and port:

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1.  If you have an external load balancer and it does not work for you, try to
    [access the gateway using its node port](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

## Cleanup

Delete the `Gateway` and `VirtualService` configuration, and shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete requestauthentication -n istio-system ingress-jwt
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
