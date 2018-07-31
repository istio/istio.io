---
title: 用 HTTPS 加密 Gateway
description: 配置 Istio 令其以 TLS 或双向 TLS 的方式在网格外公开服务。
weight: 31
keywords: [traffic-management,ingress]
---

> 本文任务使用了新的 [v1alpha3 流量控制 API](/blog/2018/v1alpha3-routing/)。旧版本 API 已经过时，会在下一个 Istio 版本中移除。如果需要使用旧版本 API，请阅读[旧版本文档](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)

[控制 Ingress 流量](/docs/tasks/traffic-management/ingress)任务描述了如何对 Ingress gateway 进行配置，从而对外以 HTTP 端点的形式暴露服务。本文中将会对这一任务进行扩展，为服务启用普通或双向 TLS 保护，以 HTTPS 的形式对网格外提供服务。

## 开始之前

1. 执行[开始之前](/docs/tasks/traffic-management/ingress#before-you-begin)的步骤，并且[确定 Ingress 地址和端口](/docs/tasks/traffic-management/ingress#determining-the-ingress-ip-and-ports)。在完成这些步骤后，应该已经部署了可用的 Istio 服务网格以及 [httpbin]({{< github_tree >}}/samples/httpbin) 应用了，并且 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 这两个变量也已经生成并赋值。

1. macOS 用户需要注意，要检查一下 `curl` 的编译是否包含了 [LibreSSL](http://www.libressl.org) 库：

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    如果命令输出中包含了 _LibreSSL_ ，那么 `curl` 命令就是适合于本文任务的。否则就要尝试使用其他的 `curl` 了，例如使用 Linux 系统。

## 生成客户端与服务器的证书和密钥

这里可以使用任意工具来生成证书和密钥，下面我们使用了[一个脚本](https://github.com/nicholasjackson/mtls-go-example/blob/master/generate.sh)：

1. 克隆 <https://github.com/nicholasjackson/mtls-go-example> 仓库：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1. 进入代码目录：

    {{< text bash >}}
    $ cd mtls-go-example
    {{< /text >}}

1. 生成证书（任意指定密码）

    {{< text bash >}}
    $ ./generate.sh httpbin.example.com <password>
    {{< /text >}}

    所有提示问题都选择 `y`。这一命令会生成四个目录： `1_root`、`2_intermediate`、`3_application` 以及 `4_client`，其中包含了后续步骤所需的客户端和服务器的证书。

## 配置 TLS ingress gateway

接下来就要为 Ingress gateway 开放一个 443 端口，用于提供 HTTPS 服务。首先使用密钥和证书作为输入，创建一个 Secret 。然后定义 Gateway 对象，其中包含了一个使用 `443` 端口的 `server`。

1. 创建一个 Kubernetes `sceret` 对象，用于保存服务器的证书和私钥。具体说来就是使用 `kubectl` 命令在命名空间 `istio-system` 中创建一个 secret 对象，命名为 `istio-ingressgateway-certs`。Istio 网关会自动载入这个 secret。

    > 这里的 secret **必须** 在 `istio-system` 命名空间中，并且命名为 `istio-ingressgateway-certs`，否则就不会被正确载入，也就无法在 Istio gateway 中使用了。

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key 3_application/private/httpbin.example.com.key.pem --cert 3_application/certs/httpbin.example.com.cert.pem
    secret "istio-ingressgateway-certs" created
    {{< /text >}}

    注意缺省情况下，`istio-system` 命名空间中所有的 Service account 都是可以访问 Secret 的，所以可能会泄漏私钥。可以通过 [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 设置来进行对涉密数据的保护。

1. 定义一个 Gateway 对象，其中包含了使用 443 端口的 `server` 部分。

    > 证书的私钥的位置 **必须** 是 `/etc/istio/ingressgateway-certs`，否则 Gateway 无法载入。

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
    spec:
      selector:
        istio: ingressgateway # 使用 Istio 的缺省 Gateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 为通过 Gateway 进入的流量进行路由配置。配置一个和[控制 Ingress 流量任务](/docs/tasks/traffic-management/ingress/#configuring-ingress-using-an-istio-gateway) 中一致的 `Virtualservice`：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

1. 用 `curl` 发送 `https` 请求到 `SECURE_INGRESS_PORT`，也就是通过 HTTPS 协议访问 `httpbin` 服务。

    `--resolve` 选项要求 `curl` 通过域名 `httpbin.example.com` 使用 TLS 访问 Gateway 地址，这样也就符合了证书的 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 要求。`--cacert` 参数则让 `curl` 命令使用刚刚生成的证书来对服务器进行校验。

    发送请求到 `/status/418`，会看到漂亮的返回内容，这说明我们成功访问了 `httpbin`。`httpbin` 服务会返回 [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3)。

    {{< text bash >}}
    $ curl -v --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert 2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=httpbin.example.com
      start date: Jun 24 18:45:18 2018 GMT
      expire date: Jul  4 18:45:18 2019 GMT
      common name: httpbin.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=httpbin.example.com
    SSL certificate verify ok.
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

    > Gateway 定义的传播可能需要一些时间，在传播完成之间的访问，可能会得到这样的错误响应：
    > `Failed to connect to httpbin.example.com port <your secure port>: Connection refused`。只需等待一分钟，重新访问即可。

    查看 `curl` 命令返回内容中的 `Server certificate` 部分，注意其中的 `common name`：`common name: httpbin.example.com (matched)`。另外输出中还包含了 `SSL certificate verify ok`，这说明对服务器的证书校验是成功的，返回状态码为 418 和一只茶杯犬。

如果需要支持 [双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication)，请继续下一节内容。

## 配置 Ingress gateway 的双向 TLS 支持

这一节中会再次对 Gateway 定义进行扩展，从而在从外部客户端到 Gateway 的访问中添加对 [双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication) 的支持。

1. 创建一个 Kubernetes secret，用于存储 [CA](https://en.wikipedia.org/wiki/Certificate_authority) 证书，服务器会使用这一证书来对客户端进行校验。用 `kubectl` 在 `istio-system` 命名空间中创建 Secret `istio-ingressgateway-ca-certs`。Istio gateway 会自动载入这个 Secret。

    > 这个 secret **必须** 以 `istio-ingressgateway-ca-certs` 为名并保存在命名空间 `istio-system` 之中，否则 Istio gateway 无法正确完成加载过程。

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=2_intermediate/certs/ca-chain.cert.pem
    secret "istio-ingressgateway-ca-certs" created
    {{< /text >}}

1. 重新定义之前的 Gateway，把其中的 `tls` 一节的 `mode` 字段的值修改为 `MUTUAL`，并给 `caCertificates` 赋值：

    > 证书的位置 **必须** 是 `/etc/istio/ingressgateway-ca-certs`，否则 Gateway 无法加载。证书的文件名必须和创建 Secret 时使用的文件名一致，这里就是 `ca-chain.cert.pem`

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
    spec:
      selector:
        istio: ingressgateway # 是用缺省的 Istio Gateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: MUTUAL
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          caCertificates: /etc/istio/ingressgateway-ca-certs/ca-chain.cert.pem
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 同样的使用 HTTPS 方式访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST  --cacert 2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    curl: (35) error:14094410:SSL routines:SSL3_READ_BYTES:sslv3 alert handshake failure
    {{< /text >}}

    > Gateway 定义的传播可能需要一些时间，在传播完成之前，可能还会得到 `418` 的响应。稍事等待后，可再次执行 `curl`。

    因为服务拒绝接受未经验证的请求，这次访问会得到一个错误返回。因此这次调用必须使用客户端证书，并且需要把密钥传递给 `curl` ，从而完成对请求的签名过程。

1. 再次使用 `curl` 命令发送请求，这次的参数加入了客户端证书（`--cert`）以及私钥（`--key`）:

    {{< text bash >}}
    $ curl --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST  --cacert 2_intermediate/certs/ca-chain.cert.pem --cert 4_client/certs/httpbin.example.com.cert.pem --key 4_client/private/httpbin.example.com.key.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

    这次服务器成功校验了客户端证书并放行，因此就再次看到了正确的返回内容。

## 常见问题

1. 查看 `INGRESS_HOST` 以及 `SECURE_INGRESS_PORT` 这两个环境变量，确定它们的正确取值，具体命令：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

1. 检查 `istio-ingressgateway` Pod 是否正确的加载了证书和私钥：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
    {{< /text >}}

    `tls.crt` 和 `tls.key` 都应该保存在这个目录中。

1. 检查 Ingress gateway 证书中的 `Subject` 字段的正确性：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-certs/tls.crt | openssl x509 -text -noout | grep 'Subject:'
        Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=httpbin.example.com
    {{< /text >}}

1. 检查 Ingress gateway 的代理能够正确访问证书：

    {{< text bash >}}
    $ kubectl exec -ti $(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath={.items[0]..metadata.name}) -n istio-system -- curl  127.0.0.1:15000/certs
    {
      "ca_cert": "",
      "cert_chain": "Certificate Path: /etc/istio/ingressgateway-certs/tls.crt, Serial Number: 100212, Days until Expiration: 370"
    }
    {{< /text >}}

1. 检查 `istio-ingressgateway` 中的错误信息：

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=ingressgateway
    {{< /text >}}

1. macOS 用户，检查 `curl` 是否包含 [LibreSSL](http://www.libressl.org) 库，和[开始之前](#开始之前)中提到的一样。

### 双向 TLS 常见问题

除去刚才提到的内容之外，执行下列检查：

1. 检查 `istio-ingressgateway` Pod 是否正确加载 CA 证书：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-ca-certs
    {{< /text >}}

    `ca-chain.cert.pem` 应该保存在这个路径中。

1. 检查 Ingress gateway 中 CA 证书的 `Subject` 字段内容：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-ca-certs/ca-chain.cert.pem | openssl x509 -text -noout | grep 'Subject:'
    Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=httpbin.example.com
    {{< /text >}}

## 清理

1. 删除 `Gateway` 配置、`VirtualService` 以及 Secret 对象：

    {{< text bash >}}
    $ istioctl delete gateway httpbin-gateway
    $ istioctl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret istio-ingressgateway-certs istio-ingressgateway-ca-certs
    {{< /text >}}

1. 关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

    {{< text bash >}}
    $ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}
