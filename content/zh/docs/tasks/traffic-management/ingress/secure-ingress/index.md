---
title: 安全网关
description: 通过 TLS 或 mTLS 将服务暴露到服务网格外。
weight: 20
aliases:
    - /zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/
    - /zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/
keywords: [traffic-management,ingress,sds-credentials]
owner: istio/wg-networking-maintainers
test: yes
---

[Ingress 流量控制任务](/zh/docs/tasks/traffic-management/ingress/ingress-control)描述了如何配置入口网关以向外部公开
HTTP 服务。此任务描述如何使用 TLS 或 mTLS 公开安全的 HTTPS 服务。

{{< boilerplate gateway-api-support >}}

## 准备工作{#before-you-begin}

* 参考[安装指南](/zh/docs/setup/)部署 Istio。

* 部署 [httpbin]({{< github_tree >}}/samples/httpbin) 示例：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

* 对于 macOS 用户，请验证您是否使用通过 [LibreSSL](http://www.libressl.org) 库编译的 `curl`：

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    如果上述命令输出的是如图所示的 LibreSSL 版本，则 `curl` 命令应按照此任务中的说明正确运行。
    否则，请尝试使用 `curl` 的其他实现，例如在 Linux 机器上。

## 生成客户端和服务器证书和密钥{#generate-client-and-server-certificates-and-keys}

对于此任务，您可以使用自己喜欢的工具来生成证书和密钥。
下面的命令使用 [openssl](https://man.openbsd.org/openssl.1)。

1.  创建用于服务签名的根证书和私钥：

    {{< text bash >}}
    $ mkdir example_certs1
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs1/example.com.key -out example_certs1/example.com.crt
    {{< /text >}}

1.  为 `httpbin.example.com` 创建证书和私钥：

    {{< text bash >}}
    $ openssl req -out example_certs1/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 0 -in example_certs1/httpbin.example.com.csr -out example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  创建第二组相同类型的证书和密钥：

    {{< text bash >}}
    $ mkdir example_certs2
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs2/example.com.key -out example_certs2/example.com.crt
    $ openssl req -out example_certs2/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs2/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs2/example.com.crt -CAkey example_certs2/example.com.key -set_serial 0 -in example_certs2/httpbin.example.com.csr -out example_certs2/httpbin.example.com.crt
    {{< /text >}}

1.  为 `helloworld.example.com` 生成证书和私钥：

    {{< text bash >}}
    $ openssl req -out example_certs1/helloworld.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/helloworld.example.com.key -subj "/CN=helloworld.example.com/O=helloworld organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/helloworld.example.com.csr -out example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  生成客户端证书和私钥：

    {{< text bash >}}
    $ openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
    {{< /text >}}

{{< tip >}}
您可以通过运行以下命令确认您拥有所有需要的文件：

{{< text bash >}}
$ ls example_cert*
example_certs1:
client.example.com.crt          example.com.key                 httpbin.example.com.crt
client.example.com.csr          helloworld.example.com.crt      httpbin.example.com.csr
client.example.com.key          helloworld.example.com.csr      httpbin.example.com.key
example.com.crt                 helloworld.example.com.key

example_certs2:
example.com.crt         httpbin.example.com.crt httpbin.example.com.key
example.com.key         httpbin.example.com.csr
{{< /text >}}

{{< /tip >}}

### 配置单机 TLS 入口网关 {#configure-a-tls-ingress-gateway-for-a-single-host}

1.  为入口网关创建 Secret:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  配置入口网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

首先，使用 `servers:` 为 443 端口定义一个网关，并将 `credentialName` 的值设置为 `httpbin-credential`。
该值与 Secret 的名称相同。TLS 模式的值应为 `SIMPLE`。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
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
    - httpbin.example.com
EOF
{{< /text >}}

接下来，通过定义相应的虚拟服务来配置网关的入口流量路由：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - mygateway
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

最后，按照[这些说明](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
设置访问网关的 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 变量。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

首先，创建一个 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway)：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

接下来，通过定义相应的 `HTTPRoute` 配置网关的入口流量路由：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

最后，从 `Gateway` 资源中获取网关地址和端口：

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway -n istio-system
$ export INGRESS_HOST=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  向 `httpbin` 服务发送 HTTPS 请求：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

    `httpbin` 服务将返回 [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) 代码。

1)  通过删除网关的 Secret 然后使用不同的证书和密钥重新创建它来更改网关的凭据：

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs2/httpbin.example.com.key \
      --cert=example_certs2/httpbin.example.com.crt
    {{< /text >}}

1)  使用新的证书链和 `curl` 来访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs2/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

1) 如果您使用之前的证书链来访问 `httpbin`，则会失败：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### 为多个主机配置 TLS 入口网关 {#configure-a-TLS-ingress-gateway-for-multiple-hosts}

您可以为多个主机（例如 `httpbin.example.com` 和 `helloworld-v1.example.com`）配置入口网关。
入口网关配置有与每个主机相对应的唯一凭据。

1.  通过删除并使用原始证书和密钥重新创建 Secret 来恢复上一个示例中的 `httpbin` 凭据：

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  启动 `helloworld-v1` 示例：

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1
    {{< /text >}}

1.  创建 `helloworld-credential` Secret：

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls helloworld-credential --key=helloworld-v1.example.com.key --cert=helloworld-v1.example.com.crt
    {{< /text >}}

1.  使用 `httpbin.example.com` 和 `helloworld.example.com` 主机配置入口网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

为 443 端口定义一个具有两个服务器部分的网关。将每个端口上的 `credentialName`
值分别设置为 `httpbin-credential` 和 `helloworld-credential`。将 TLS 模式设置为 `SIMPLE`。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https-httpbin
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential
    hosts:
    - httpbin.example.com
  - port:
      number: 443
      name: https-helloworld
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: helloworld-credential
    hosts:
    - helloworld.example.com
EOF
{{< /text >}}

通过定义相应的虚拟服务来配置网关的流量路由。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.example.com
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

在 443 端口上配置具有两个监听器的 `Gateway`。将每个端口的监听器的 `certificateRefs`
的名字分别设置为 `httpbin-credential` 和 `helloworld-credential`。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https-httpbin
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
  - name: https-helloworld
    hostname: "helloworld.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: helloworld-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

为 `helloworld` 服务配置网关的流量路由：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["helloworld.example.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) 向 `helloworld.example.com` 发送 HTTPS 请求：

    {{< text bash >}}
    $ curl -v -HHost:helloworld.example.com --resolve "helloworld.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://helloworld.example.com:$SECURE_INGRESS_PORT/hello"
    ...
    HTTP/2 200
    ...
    {{< /text >}}

1) 向 `httpbin.example.com` 发送一个 HTTPS 请求，仍然返回一个茶壶：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

### 配置双向 TLS 入口网关 {#configure-a-mutual-tls-ingress-gateway}

您可以扩展网关的定义以支持[双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication)。

1. 通过删除其 Secret 并创建一个新的来更改入口网关的凭据。服务器使用 CA
   证书来验证其客户端，我们必须使用名称 `cacert` 来持有 CA 证书。

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential \
      --from-file=tls.key=example_certs1/httpbin.example.com.key \
      --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
      --from-file=ca.crt=example_certs1/example.com.crt
    {{< /text >}}

    {{< tip >}}

    {{< boilerplate crl-tip >}}

    凭据也可以包括 [OCSP Staple](https://datatracker.ietf.org/doc/html/rfc6961)
    使用参数 `--from-file=tls.ocsp-staple=/some/path/to/your-ocsp-staple.pem` 指定的
    `tls.ocsp-staple` 作为键名。

    {{< /tip >}}

1. 配置入口网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

更改网关的定义以将 TLS 模式设置为 `MUTUAL`。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - httpbin.example.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

因为 Kubernetes Gateway API 目前不支持 [Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway)
中的双向 TLS 终止，所以我们使用 Istio 特定的选项 `gateway.istio.io/tls-terminate-mode: MUTUAL` 来配置它：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
      options:
        gateway.istio.io/tls-terminate-mode: MUTUAL
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) 尝试使用之前的方法发送 HTTPS 请求，看看它是如何失败的：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * TLSv1.3 (IN), TLS alert, unknown (628):
    * OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
    {{< /text >}}

1) 将客户端证书和私钥传递给 `curl` 并重新发送请求。将带有  `--cert` 标志的客户证书和带有 `--key` 标志的私钥传递给 `curl`：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
      "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

## 更多信息 {#more-info}

### 密钥格式 {#key-formats}

Istio 支持读取几种不同的 Secret 格式，以支持与各种工具的集成，例如 [cert-manager](/zh/docs/ops/integrations/certmanager/)：

* 带有 `tls.key` 和 `tls.crt` 的 TLS Secret，如上所述。对于双向 TLS，`ca.crt` 可以作为密钥。
* 带有 `key` 和 `cert` 键的通用 Secret。对于双向 TLS，`cacert` 可以作为密钥。
* 带有 `key` 和 `cert` 键的通用 Secret。对于双向 TLS，名为 `<secret>-cacert` 的带有 `cacert` 键的通用 Secret。
  例如，`httpbin-credential` 有 `key` 和 `cert`，`httpbin-credential-cacert` 有 `cacert`。
* `cacert` 键值可以是一个 CA 捆绑包，由串联的各个 CA 证书组成。

### SNI 路由 {#sni-routing}

HTTPS `Gateway` 将在转发请求之前对其配置的主机执行 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)
匹配，这可能会导致某些请求失败。有关详细信息，
请参阅[配置 SNI 路由](/zh/docs/ops/common-problems/network-issues/#configuring-sni-routing-when-not-sending-sni)。

## 问题排查 {#troubleshooting}

*   检查 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 环境变量的值。根据以下命令的输出，确保它们具有有效值：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
    {{< /text >}}

*   确保 `INGRESS_HOST` 的值是一个 IP 地址。在某些云平台（例如 AWS）中，您可能会得到一个域名而不是 IP 地址。
    此任务需要一个 IP 地 址，因此您需要使用类似以下的命令进行转换：

    {{< text bash >}}
    $ nslookup ab52747ba608744d8afd530ffd975cbf-330887905.us-east-1.elb.amazonaws.com
    $ export INGRESS_HOST=3.225.207.109
    {{< /text >}}

*   检查网关控制器的日志以获取错误消息：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

*   如果使用 macOS，请验证您使用的是使用 [LibreSSL](http://www.libressl.org/) `curl`
    库编译的，如[准备工作](#before-you-begin)部分中所述。

*   验证已在 `istio-system` 命名空间中成功创建 Secret：

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` 和 `helloworld-credential` 应当显示在 Secret 列表中。

*   检查日志以验证入口网关代理已将密钥/证书对推送到入口网关：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

    日志应显示 `httpbin-credential` Secret 已添加。如果使用双向 TLS，
    那么 `httpbin-credential-cacert` Secret 也应该出现。
    验证日志显示网关代理接收到来自入口网关的 SDS 请求，资源的名称是 `httpbin-credential`，
    并且入口网关获得了密钥/证书对。如果使用双向 TLS，日志应显示密钥/证书已发送到入口网关，
    网关代理收到带有 `httpbin-credential-cacert` 资源名称的 SDS 请求，并且入口网关获得了根证书。

## 清理 {#cleanup}

1.  删除网关配置和路由：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system gtw mygateway
$ kubectl delete httproute httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  删除 Secret、证书和密钥：

    {{< text bash >}}
    $ kubectl delete -n istio-system secret httpbin-credential helloworld-credential
    $ rm -rf ./example_certs1 ./example_certs2
    {{< /text >}}

1)  关闭 `httpbin` 和 `helloworld` 服务：

    {{< text bash >}}
    $ kubectl delete -f samples/httpbin/httpbin.yaml
    $ kubectl delete deployment helloworld-v1
    $ kubectl delete service helloworld
    {{< /text >}}
