---
title: Proxy protocol on AWS NLB and Istio ingress gateway
description: How to enable proxy protocol on AWS NLB and Istio ingress gateway.
publishdate: 2020-12-11
attribution: "Xinhui Li (Salesforce) "
keywords: [trafficManagement,protocol extending]
---
This blog presents my latest experience about how to configure and enable proxy protocol with stack of AWS NLB and Istio Ingress gateway. The [Proxy Protocol](https://www.haproxy.com/blog/haproxy/proxy-protocol/) was designed to chain proxies and reverse-proxies without losing the client information. The proxy protocol prevents the need for infrastructure changes or `NATing` firewalls, and offers the benefits of being protocol agnostic and providing good scalability. Additionally, we also enable the `X-Forwarded-For` HTTP header in the deployment to make the client IP address easy to read. In this blog, traffic management of Istio ingress is shown with an httpbin service on ports 80 and 443 to demonstrate the use of proxy protocol. Note that both v1 and v2 of the proxy protocol work for the purpose of this example, but because the AWS NLB currently only supports v2, proxy protocol v2 is used in the rest of this blog by default. The following image shows the use of proxy protocol v2 with an AWS NLB.

{{< tip >}}
A receiver may be configured to support both version 1 and version 2 of the
protocol. Identifying the protocol version is easy:

- If the incoming byte count is 16 or more and the first 13 bytes match the protocol signature block `\x0D\x0A\x0D\x0A\x00\x0D\x0A\x51\x55\x49\x54\x0A\x02`, the protocol is version 2.

- Otherwise, if the incoming byte count is 8 or more, and the 5 first characters match the `US-ASCII` representation of "PROXY"(`\x50\x52\x4F\x58\x59`), then the protocol must be parsed as version 1.

- Otherwise the protocol is not covered by this specification and the connection must be dropped.
{{< /tip >}}

{{< image width="100%" link="./aws-proxy-protocol.png" caption="AWS NLB portal to enable proxy protocol" >}}

## Separate setups for 80 and 443

Before going through the following steps, an AWS environment that is configured with the proper VPC, IAM, and Kubernetes setup is assumed.

### Step 1: Install Istio with AWS NLB

The blog [Configuring Istio Ingress with AWS NLB](/blog/2018/aws-nlb/) provides detailed steps to set up AWS IAM roles and enable the usage of AWS NLB by Helm. You can also use other automation tools, such as Terraform, to achieve the same goal. In the following example, more complete configurations are shown in order to enable proxy protocol and `X-Forwarded-For` at the same time.

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    proxy.istio.io/config: '{"gatewayTopology" : { "numTrustedProxies": 2 } }'
  labels:
    app: istio-ingressgateway
    istio: ingressgateway
    release: istio
  name: istio-ingressgateway
{{< /text >}}

### Step 2: Create proxy-protocol Envoy Filter

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
        - name: envoy.filters.listener.proxy_protocol
        - name: envoy.filters.listener.tls_inspector
{{< /text >}}

### Step 3: Enable `X-Forwarded-For` header

This [blog](/docs/ops/configuration/traffic-management/network-topologies/) includes several samples of configuring Gateway Network Topology. In the following example, the configurations are tuned to enable `X-Forwarded-For` without any middle proxy.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingressgateway-settings
  namespace: istio-system
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      listener:
        filterChain:
          filter:
            name: envoy.http_connection_manager
    patch:
      operation: MERGE
      value:
        name: envoy.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager
          skip_xff_append: false
          use_remote_address: true
          xff_num_trusted_hops: 1
{{< /text >}}

### Step 4: Deploy ingress gateway for httpbin on port 80 and 443

{{< warning>}}
When following the [secure ingress setup](/docs/tasks/traffic-management/ingress/secure-ingress/), macOS users must add an additional patch to generate certificates for TLS.
{{< /warning >}}

{{< text yaml >}}
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
    - "a25fa0b4835b.elb.us-west-2.amazonaws.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "a25fa0b4835b.elb.us-west-2.amazonaws.com"
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
{{< /text >}}

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway2
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - "a25fa0b4835b.elb.us-west-2.amazonaws.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "a25fa0b4835b.elb.us-west-2.amazonaws.com"
  gateways:
  - mygateway2
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
{{< /text  >}}

### Step 5: Check header output of httpbin

Check port 443 (80 will be similar) and compare the cases with and without proxy protocol.

{{< text yaml >}}
//////with proxy_protocal enabled in the stack
*   Trying YY.XXX.141.26...
* TCP_NODELAY set
* Connection failed
* connect to YY.XXX.141.26 port 443 failed: Operation timed out
*   Trying YY.XXX.205.117...
* TCP_NODELAY set
* Connected to a25fa0b4835b.elb.us-west-2.amazonaws.com (XX.YYY.205.117) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: new_certificates/example.com.crt
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=a25fa0b4835b.elb.us-west-2.amazonaws.com; O=httpbin organization
*  start date: Oct 29 20:39:12 2020 GMT
*  expire date: Oct 29 20:39:12 2021 GMT
*  common name: a25fa0b4835b.elb.us-west-2.amazonaws.com (matched)
*  issuer: O=example Inc.; CN=example.com
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fc6c8810800)
> GET /headers?show_env=1 HTTP/2
> Host: a25fa0b4835b.elb.us-west-2.amazonaws.com
> User-Agent: curl/7.64.1
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< server: istio-envoy
< date: Thu, 29 Oct 2020 21:39:46 GMT
< content-type: application/json
< content-length: 629
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 2
<
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "a25fa0b4835b.elb.us-west-2.amazonaws.com",
    "User-Agent": "curl/7.64.1",
    "X-B3-Sampled": "0",
    "X-B3-Spanid": "74f99a1c6fc29975",
    "X-B3-Traceid": "85db86fe6aa322a074f99a1c6fc29975",
    "X-Envoy-Attempt-Count": "1",
    "X-Envoy-Decorator-Operation": "httpbin.default.svc.cluster.local:8000/headers*",
    "X-Envoy-External-Address": "XX.110.54.41",
    "X-Forwarded-For": "XX.110.54.41",
    "X-Forwarded-Proto": "https",
    "X-Request-Id": "5c3bc236-0c49-4401-b2fd-2dbfbce506fc"
  }
}
* Connection #0 to host a25fa0b4835b.elb.us-west-2.amazonaws.com left intact
* Closing connection 0
{{< /text >}}

{{< text yaml >}}
//////////without proxy_protocal
*   Trying YY.XXX.141.26...
* TCP_NODELAY set
* Connection failed
* connect to YY.XXX.141.26 port 443 failed: Operation timed out
*   Trying YY.XXX.205.117...
* TCP_NODELAY set
* Connected to a25fa0b4835b.elb.us-west-2.amazonaws.com (YY.XXX.205.117) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: new_certificates/example.com.crt
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=a25fa0b4835b.elb.us-west-2.amazonaws.com; O=httpbin organization
*  start date: Oct 29 20:39:12 2020 GMT
*  expire date: Oct 29 20:39:12 2021 GMT
*  common name: a25fa0b4835b.elb.us-west-2.amazonaws.com (matched)
*  issuer: O=example Inc.; CN=example.com
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fbf8c808200)
> GET /headers?show_env=1 HTTP/2
> Host: a25fa0b4835b.elb.us-west-2.amazonaws.com
> User-Agent: curl/7.64.1
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< server: istio-envoy
< date: Thu, 29 Oct 2020 20:44:01 GMT
< content-type: application/json
< content-length: 612
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 1
<
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "a25fa0b4835b.elb.us-west-2.amazonaws.com",
    "User-Agent": "curl/7.64.1",
    "X-B3-Sampled": "0",
    "X-B3-Spanid": "69913a6e6e949334",
    "X-B3-Traceid": "729d5da3618545da69913a6e6e949334",
    "X-Envoy-Attempt-Count": "1",
    "X-Envoy-Decorator-Operation": "httpbin.default.svc.cluster.local:8000/headers*",
    "X-Envoy-Internal": "true",
    "X-Forwarded-For": "172.16.5.30",
    "X-Forwarded-Proto": "https",
    "X-Request-Id": "299c7f8a-5f89-480a-82c9-028c76d45d84"
  }
}
* Connection #0 to host a25fa0b4835b.elb.us-west-2.amazonaws.com left intact
* Closing connection 0
{{< /text >}}

## Conclusion

This blog presents the deployment of a stack that consists of an AWS NLB and Istio ingress gateway that are enabled with proxy-protocol. We hope it is useful to you if you are interested in protocol enabling in an anecdotal, experiential, and more informal way. However, note that the `X-Forwarded-For` header should be used only for the convenience of reading in test, as dealing with fake `X-Forwarded-For` attacks is not within the scope of this blog.

## References

- [protocol settings](https://docs.nginx.com/nginx/admin-guide/load-balancer/using-proxy-protocol/)

- [protocol introduction](https://www.haproxy.com/blog/haproxy/proxy-protocol/)
