---
title: Secure Gateways
description: 通过TLS或mTLS将服务公开到服务网格之外。
weight: 20
aliases:
    - /zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/
    - /zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/
keywords: [traffic-management,ingress,sds-credentials]
owner: istio/wg-networking-maintainers
test: yes
---

[Ingress流量控制任务](/zh/docs/tasks/traffic-management/ingress/ingress-control)描述了如何配置入口网关以向外部公开HTTP服务。此任务描述如何使用TLS或双向TLS公开安全的HTTPS服务。

## 准备工作{#before-you-begin}

1. 执行[准备工作](/zh/docs/tasks/traffic-management/ingress/ingress-control#before-you-begin)中的步骤。完成[Ingress流量控制](/zh/docs/tasks/traffic-management/ingress/ingress-control)中[确定Ingress的IP和Port](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)部分任务。执行完这些步骤后，您应该已部署Istio和 [httpbin]({{< github_tree >}}/samples/httpbin)服务，并设置了环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 。

1.  对于macOS用户，请验证您是否使用通过LibreSSL库编译的curl：

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    如果上述命令输出的是如图所示的LibreSSL版本，则curl命令应按照此任务中的说明正确运行。否则，请尝试使用curl的其他实现，例如在Linux机器上。

## 生成客户端和服务器证书和密钥{#generate-client-and-server-certificates-and-keys}

对于此任务，您可以使用自己喜欢的工具来生成证书和密钥。下面的命令使用[openssl](https://man.openbsd.org/openssl.1)

1.  创建用于服务签名的根证书和私钥：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  为 `httpbin.example.com` 创建证书和私钥：:

    {{< text bash >}}
    $ openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
    {{< /text >}}

### 配置单机TLS入口网关

1.  确定已在[准备工作](/zh/docs/tasks/traffic-management/ingress/ingress-control#before-you-begin)环节完成[httpbin]({{< github_tree >}}/samples/httpbin)服务的部署。

1.  为Ingress网关创建Secret:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls httpbin-credential --key=httpbin.example.com.key --cert=httpbin.example.com.crt
    {{< /text >}}

    {{< warning >}}
    Secret 名字 **不能** 以 `istio` 或 `prometheus` 开头, 且不能包含 `token` 字段。
    {{< /warning >}}

1.  为端口443定义一个带有 `servers:` 部分的网关，并将 `credentialName` 的值指定为 `httpbin-credential`。这些值与secret名称相同。 TLS模式的值应为 `SIMPLE`。

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

1.  配置网关的入口流量路由，定义相应的虚拟服务。

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

1.  发送HTTPS请求访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    {{< /text >}}

    The `httpbin` service will return the
    [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

1.  删除网关的secret，并创建一个新的secret来修改入口网关的凭据。

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    {{< /text >}}

    {{< text bash >}}
    $ mkdir new_certificates
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout new_certificates/example.com.key -out new_certificates/example.com.crt
    $ openssl req -out new_certificates/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout new_certificates/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -days 365 -CA new_certificates/example.com.crt -CAkey new_certificates/example.com.key -set_serial 0 -in new_certificates/httpbin.example.com.csr -out new_certificates/httpbin.example.com.crt
    $ kubectl create -n istio-system secret tls httpbin-credential \
    --key=new_certificates/httpbin.example.com.key \
    --cert=new_certificates/httpbin.example.com.crt
    {{< /text >}}

1.  `curl` 使用新证书链访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert new_certificates/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

1. 如果使用先前的证书链访问httpbin，将返回失败。

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### 为多个主机配置TLS入口网关 {#configure-a-TLS-ingress-gateway-for-multiple-hosts}

您可以为多个主机（例如 `httpbin.example.com` 和 `helloworld-v1.example.com` ）配置入口网关。入口网关检索与特定凭据名称相对应的唯一凭据。

1.  要恢复httpbin的凭据，请删除secret并重新创建。

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
    --key=httpbin.example.com.key \
    --cert=httpbin.example.com.crt
    {{< /text >}}

1.  启动 `helloworld-v1`

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld-v1
      labels:
        app: helloworld-v1
    spec:
      ports:
      - name: http
        port: 5000
      selector:
        app: helloworld-v1
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: helloworld-v1
          version: v1
      template:
        metadata:
          labels:
            app: helloworld-v1
            version: v1
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v1
            resources:
              requests:
                cpu: "100m"
            imagePullPolicy: IfNotPresent #Always
            ports:
            - containerPort: 5000
    EOF
    {{< /text >}}

1.  为 `helloworld-v1.example.com` 生成证书和私钥：

    {{< text bash >}}
    $ openssl req -out helloworld-v1.example.com.csr -newkey rsa:2048 -nodes -keyout helloworld-v1.example.com.key -subj "/CN=helloworld-v1.example.com/O=helloworld organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in helloworld-v1.example.com.csr -out helloworld-v1.example.com.crt
    {{< /text >}}

1.  创建 `helloworld-credential` secret:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls helloworld-credential --key=helloworld-v1.example.com.key --cert=helloworld-v1.example.com.crt
    {{< /text >}}

1.  为端口443定义一个包含两个server定义的网关。将每个端口上的 `credentialName` 的值分别设置为 `httpbin-credential` 和 `helloworld-credential` 。将TLS模式设置为 `SIMPLE`。

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
        - helloworld-v1.example.com
    EOF
    {{< /text >}}

1.  配置网关的流量路由。定义相应的虚拟服务。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: helloworld-v1
    spec:
      hosts:
      - helloworld-v1.example.com
      gateways:
      - mygateway
      http:
      - match:
        - uri:
            exact: /hello
        route:
        - destination:
            host: helloworld-v1
            port:
              number: 5000
    EOF
    {{< /text >}}

1. 发送一个 HTTPS 请求到 `helloworld-v1.example.com`:

    {{< text bash >}}
    $ curl -v -HHost:helloworld-v1.example.com --resolve "helloworld-v1.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt "https://helloworld-v1.example.com:$SECURE_INGRESS_PORT/hello"
    HTTP/2 200
    {{< /text >}}

1. 发送一个 HTTPS 请求到 `httpbin.example.com`，仍然返回一个茶壶:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

### 配置双向TLS入口网关 {#configure-a-mutual-TLS-ingress-gateway}

您可以扩展网关的定义以支持[双向TLS](https://en.wikipedia.org/wiki/Mutual_authentication)。删除入口网关的secret并创建一个新的，以更改入口网关的凭据。服务器使用CA证书来验证其客户端，并且必须使用名称 `cacert` 来持有CA证书。

{{< text bash >}}
$ kubectl -n istio-system delete secret httpbin-credential
$ kubectl create -n istio-system secret generic httpbin-credential --from-file=tls.key=httpbin.example.com.key \
--from-file=tls.crt=httpbin.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

1. 更改网关的定义, 将TLS模式设置为 `MUTUAL` 。

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

1. 尝试使用先前的方法发送HTTPS请求，并查看失败的详情：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

1.  生成客户端证书和私钥：

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

1. 重新发送带客户端证书和私钥的 `curl` 请求。使用--cert标志传递客户端证书，使用--key标志传递私钥。

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example.com.crt --cert client.example.com.crt --key client.example.com.key \
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

Istio支持读取不同的Secret格式，以支持与各种工具（例如[cert-manager](/zh/docs/ops/integrations/certmanager/))的集成：

* 如上所述，包含 `tls.key` 和 `tls.crt` 的TLS secret。对于双向TLS，可以使用 `ca.crt` 密钥。
* 包含 `key` 和 `cert` 的通用Secret。对于双向TLS，可以使用 `cacert` 密钥。
* 包含 `key` 和 `cert` 的通用Secret。对于双向TLS，还可以单独设置名为 `<secret>-cacert` 的通用secret，该secret含 `cacert` 密钥。例如，`httpbin-credential` 包含 `key` 和 `cert`，而 `httpbin-credential-cacert` 包含 `cacert`。

## Troubleshooting {#troubleshooting}

*   检查 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 环境变量的值。核实以下命令的输出，确保它们具有有效值：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
    {{< /text >}}

*   检查 `istio-ingressgateway` 控制器的日志中是否有错误消息：

    {{< text bash >}}
    $ kubectl logs -n istio-system "$(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}')"
    {{< /text >}}

*   如果使用macOS，请按照[准备工作](#before-you-begin)部分中的说明，验证您正在使用通过[LibreSSL](http://www.libressl.org)库编译的curl。

*   验证secret是否已在 `istio-system` 命名空间中成功创建:

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` 和 `helloworld-credential` 应该显示在secret列表中。

*   检查日志以确认入口网关代理已将密钥/证书对推送到入口网关。

    {{< text bash >}}
    $ kubectl logs -n istio-system "$(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}')"
    {{< /text >}}

    日志应显示已添加`httpbin-credential` secret。如果使用双向TLS，则还应显示 `httpbin-credential-cacert` secret。验证日志是否显示网关代理接收到来自入口网关的SDS请求（资源名称为 `httpbin-credential`），且入口网关已获得密钥/证书对。如果使用双向TLS，则日志应显示密钥/证书已发送到入口网关，网关代理已收到带有 `httpbin-credential-cacert`资源名称的SDS请求，并且入口网关已获得根证书。

## 清除 {#cleanup}

1.  删除网关配置，虚拟服务定义和secret：

    {{< text bash >}}
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret httpbin-credential \
    helloworld-credential
    $ kubectl delete --ignore-not-found=true virtualservice helloworld-v1
    {{< /text >}}

1.  删除证书和密钥：

    {{< text bash >}}
    $ rm -rf example.com.crt example.com.key httpbin.example.com.crt httpbin.example.com.key httpbin.example.com.csr helloworld-v1.example.com.crt helloworld-v1.example.com.key helloworld-v1.example.com.csr client.example.com.crt client.example.com.csr client.example.com.key ./new_certificates
    {{< /text >}}

1. 关闭 `httpbin` 和 `helloworld-v1` 服务：

    {{< text bash >}}
    $ kubectl delete deployment --ignore-not-found=true httpbin helloworld-v1
    $ kubectl delete service --ignore-not-found=true httpbin helloworld-v1
    {{< /text >}}
