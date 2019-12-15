---
title: 安全网关（文件挂载）
description: 使用文件挂载的证书将一个服务通过 TLS 或 mTLS 暴露出服务网格之外。
weight: 20
aliases:
    - /zh/docs/tasks/traffic-management/secure-ingress/mount/
keywords: [traffic-management,ingress,file-mount-credentials]
---

[控制 Ingress 流量任务](/zh/docs/tasks/traffic-management/ingress)描述了如何配置一个 ingress 网关以将 HTTP 服务暴露给外部流量。本任务则展示了如何使用简单或双向 TLS 暴露安全 HTTPS 服务。

TLS 所必需的私钥、服务器证书和根证书使用基于文件挂载的方式进行配置。

## 开始之前{#before-you-begin}

1. 执行[开始之前](/zh/docs/tasks/traffic-management/ingress/ingress-control#before-you-begin)任务和[控制 Ingress 流量](/zh/docs/tasks/traffic-management/ingress)任务中的[确认 ingress 的 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)小节中的步骤。执行完毕后，Istio 和 [httpbin]({{< github_tree >}}/samples/httpbin) 服务都已经部署完毕。环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 也已经设置。

1. 对于 macOS 用户，确认您的 _curl_ 使用了 [LibreSSL](http://www.libressl.org) 库来编译：

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    如果如上面的输出中所示打印了 _LibreSSL_ 的版本，则 _curl_ 应该可以按照此任务中的说明正常工作。否则，请尝试别的 _curl_，例如运行于 Linux 计算机的版本。

## 生成服务器证书和私钥{#generate-server-certificate-and-private-key}

此任务您可以使用您喜欢的工具来生成证书和私钥。下列命令使用了 [openssl](https://man.openbsd.org/openssl.1)

1. 创建一个根证书和私钥以为您的服务所用的证书签名：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1. 为 `httpbin.example.com` 创建一个证书和私钥：

    {{< text bash >}}
    $ openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
    {{< /text >}}

## 基于文件挂载的方式配置 TLS ingress 网关{#configure-a-TLS-ingress-gateway-with-a-file-mount-based-approach}

本节中，您将配置一个使用 443 端口的 ingress 网关，以处理 HTTPS 流量。
首先使用证书和私钥创建一个 secret。该 secret 将被挂载为 `/etc/istio/ingressgateway-certs` 路径下的一个文件。
然后您可以创建一个网关定义，它将配置一个运行于端口 443 的服务。

1. 创建一个 Kubernetes secret 以保存服务器的证书和私钥。使用 `kubectl` 在命名空间 `istio-system` 下创建 secret `istio-ingressgateway-certs`。Istio 网关将会自动加载该 secret。

    {{< warning >}}
    该 secret **必须**在 `istio-system` 命名空间下，且名为 `istio-ingressgateway-certs`，以与此任务中使用的 Istio 默认 ingress 网关的配置保持一致。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key httpbin.example.com.key --cert httpbin.example.com.crt
    secret "istio-ingressgateway-certs" created
    {{< /text >}}

    请注意，默认情况下，`istio-system` 命名空间下的所有 pod 都能挂载这个 secret 并访问该私钥。您可以将 ingress 网关部署到一个单独的命名空间中，并在那创建 secret，这样就只有这个 ingress 网关 pod 才能挂载它。

    验证 `tls.crt` 和 `tls.key` 都已经挂载到 ingress 网关 pod 中：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
    {{< /text >}}

1. 为 443 端口定义 `Gateway` 并设置 `server`。

    {{< warning >}}
    证书和私钥**必须**位于 `/etc/istio/ingressgateway-certs`，否则网关将无法加载它们。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
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
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 配置路由以让流量从 `Gateway` 进入。定义与[控制 Ingress 流量](/zh/docs/tasks/traffic-management/ingress/ingress-control/#configuring-ingress-using-an-Istio-gateway)任务中相同的 `VirtualService`：

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

1. 使用 _curl_ 发送一个 `https` 请求到 `SECURE_INGRESS_PORT` 以通过 HTTPS 访问 `httpbin` 服务。

    `--resolve` 标志让 _curl_ 在通过 TLS 访问网关 IP 时支持 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 值 `httpbin.example.com`。
    `--cacert` 选项则让 _curl_ 使用您创建的证书来验证服务器。

    {{< tip >}}
    `-HHost:httpbin.example.com` 标志也包含了，但只有当 `SECURE_INGRESS_PORT` 与实际网关端口（443）不同（例如，您通过映射的 `NodePort` 来访问服务）时才真正需要。
    {{< /tip >}}

    通过发送请求到 `/status/418` URL 路径，您可以很好地看到您的 `httpbin` 服务确实已被访问。
    `httpbin` 服务将返回 [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) 代码。

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    Server certificate:
      subject: CN=httpbin.example.com; O=httpbin organization
      start date: Oct 27 19:32:48 2019 GMT
      expire date: Oct 26 19:32:48 2020 GMT
      common name: httpbin.example.com (matched)
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify ok.
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

    {{< tip >}}
    网关定义传播需要时间，因此您可能会得到以下报错：
    `Failed to connect to httpbin.example.com port <your secure port>: Connection refused`。请稍后重新执行 _curl_ 命令。
    {{< /tip >}}

    在 _curl_ 的输出中寻找 _Server certificate_ 部分，尤其是找到与 _common name_ 匹配的行：`common name: httpbin.example.com (matched)`。
    输出中的 `SSL certificate verify ok` 这一行表示服务端的证书验证成功。
    如果一切顺利，您还应该看到返回的状态 418，以及精美的茶壶图。

## 配置双向 TLS ingress 网关{#configure-a-mutual-TLS-ingress-gateway}

本节中您将您的网关的定义从上一节中扩展为支持外部客户端和网关之间的[双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication)。

1. 创建一个 Kubernetes `Secret` 以保存服务端将用来验证它的客户端的 [CA](https://en.wikipedia.org/wiki/Certificate_authority) 证书。使用 `kubectl` 在命名空间 `istio-system` 中创建 secret `istio-ingressgateway-ca-certs`。Istio 网关将会自动加载该 secret。

    {{< warning >}}
    该 secret **必须**在 `istio-system` 命名空间下，且名为 `istio-ingressgateway-ca-certs`，以与此任务中使用的 Istio 默认 ingress 网关的配置保持一致。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=example.com.crt
    secret "istio-ingressgateway-ca-certs" created
    {{< /text >}}

1. 重新定义之前的 `Gateway`，修改 TLS 模式为 `MUTUAL`，并指定 `caCertificates`：

    {{< warning >}}
    证书**必须**位于 `/etc/istio/ingressgateway-ca-certs`，否则网关将无法加载它们。
    证书的（短）文件名必须与您创建 secret 的名称相同，在本例中为 `example.com.crt`。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
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
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          caCertificates: /etc/istio/ingressgateway-ca-certs/example.com.crt
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 像上一节中一样通过 HTTPS 访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    curl: (35) error:14094410:SSL routines:SSL3_READ_BYTES:sslv3 alert handshake failure
    {{< /text >}}

    {{< warning >}}
    网关定义传播需要时间，因此您可能会仍然得到 _418_ 状态码。请稍后重新执行 _curl_ 命令。
    {{< /warning >}}

    这次您将得到一个报错，因为服务端拒绝接受未认证的请求。您需要传递 _curl_ 客户端证书和私钥以将请求签名。

1. 为 `httpbin.example.com` 服务创建客户端证书。您可以使用 `httpbin-client.example.com` URI 来指定客户端，或使用其它 URI。

    {{< text bash >}}
    $ openssl req -out httpbin-client.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin-client.example.com.key -subj "/CN=httpbin-client.example.com/O=httpbin's client organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin-client.example.com.csr -out httpbin-client.example.com.crt
    {{< /text >}}

1. 重新用 _curl_ 发送之前的请求，这次通过参数传递客户端证书（添加 `--cert` 选项）和您的私钥（`--key` 选项）：

    {{< text bash >}}
    $ curl -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt --cert httpbin-client.example.com.crt --key httpbin-client.example.com.key https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

    这次服务器成功执行了客户端身份验证，您再次收到了漂亮的茶壶图。

## 为多主机配置 TLS ingress 网关{#configure-a-TLS-ingress-gateway-for-multiple-hosts}

本节中您将为多个主机（`httpbin.example.com` 和 `bookinfo.com`）配置 ingress 网关。
Ingress 网关将向客户端提供与每个请求的服务器相对应的唯一证书。

与之前的小节不同，Istio 默认 ingress 网关无法立即使用，因为它仅被预配置为支持一个安全主机。
您需要先使用另一个 secret 配置并重新部署 ingress 网关服务器，然后才能使用它来处理第二台主机。

### 为 `bookinfo.com` 创建服务器证书和私钥{#create-a-server-certificate-and-private-key-for-book-info}

{{< text bash >}}
$ openssl req -out bookinfo.com.csr -newkey rsa:2048 -nodes -keyout bookinfo.com.key -subj "/CN=bookinfo.com/O=bookinfo organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in bookinfo.com.csr -out bookinfo.com.crt
{{< /text >}}

### 使用新证书重新部署 `istio-ingressgateway`{#redeploy-Istio-ingress-gateway-with-the-new-certificate}

1. 创建一个新的 secret 以保存 `bookinfo.com` 的证书：

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-bookinfo-certs --key bookinfo.com.key --cert bookinfo.com.crt
    secret "istio-ingressgateway-bookinfo-certs" created
    {{< /text >}}

1. 更新 `istio-ingressgateway` deployment 以挂载新创建的 secret。创建如下 `gateway-patch.json` 文件以更新 `istio-ingressgateway` deployment：

    {{< text bash >}}
    $ cat > gateway-patch.json <<EOF
    [{
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/0",
      "value": {
        "mountPath": "/etc/istio/ingressgateway-bookinfo-certs",
        "name": "ingressgateway-bookinfo-certs",
        "readOnly": true
      }
    },
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/0",
      "value": {
      "name": "ingressgateway-bookinfo-certs",
        "secret": {
          "secretName": "istio-ingressgateway-bookinfo-certs",
          "optional": true
        }
      }
    }]
    EOF
    {{< /text >}}

1. 使用以下命令应用 `istio-ingressgateway` deployment 更新：

    {{< text bash >}}
    $ kubectl -n istio-system patch --type=json deploy istio-ingressgateway -p "$(cat gateway-patch.json)"
    {{< /text >}}

1. 验证 `istio-ingressgateway` pod 已成功加载私钥和证书：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-bookinfo-certs
    {{< /text >}}

    `tls.crt` 和 `tls.key` 应该出现在文件夹之中。

### 配置 `bookinfo.com` 主机的流量{#configure-traffic-for-the-book-info-host}

1. 部署[Bookinfo 示例应用](/zh/docs/examples/bookinfo/)，但不要部署网关：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

1. 为 `bookinfo.com` 定义网关：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: bookinfo-gateway
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 443
          name: https-bookinfo
          protocol: HTTPS
        tls:
          mode: SIMPLE
          serverCertificate: /etc/istio/ingressgateway-bookinfo-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-bookinfo-certs/tls.key
        hosts:
        - "bookinfo.com"
    EOF
    {{< /text >}}

1. 配置 `bookinfo.com` 的路由。定义类似 [`samples/bookinfo/networking/bookinfo-gateway.yaml`]({{< github_file >}}/samples/bookinfo/networking/bookinfo-gateway.yaml) 的 `VirtualService`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      hosts:
      - "bookinfo.com"
      gateways:
      - bookinfo-gateway
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            port:
              number: 9080
    EOF
    {{< /text >}}

1. 发送到 _Bookinfo_ `productpage` 的请求：

    {{< text bash >}}
    $ curl -o /dev/null -s -v -w "%{http_code}\n" -HHost:bookinfo.com --resolve bookinfo.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt -HHost:bookinfo.com https://bookinfo.com:$SECURE_INGRESS_PORT/productpage
    ...
    Server certificate:
      subject: CN=bookinfo.com; O=bookinfo organization
      start date: Oct 27 20:08:32 2019 GMT
      expire date: Oct 26 20:08:32 2020 GMT
      common name: bookinfo.com (matched)
      issuer: O=example Inc.; CN=example.com
    SSL certificate verify ok.
    ...
    200
    {{< /text >}}

1. 验证 `httbin.example.com` 像之前一样可访问。发送一个请求给它，您会再次看到您喜爱的茶壶：

    {{< text bash >}}
    $ curl -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert example.com.crt --cert httpbin-client.example.com.crt --key httpbin-client.example.com.key https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
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

## 问题排查{#troubleshooting}

*   检查环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 的值。通过下列命令的输出确保它们都有有效值：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

*   验证 `istio-ingressgateway` pod 已经成功加载了私钥和证书：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
    {{< /text >}}

    `tls.crt` 和 `tls.key` 应存在于文件夹之中。

*   如果您已经创建了 `istio-ingressgateway-certs` secret，但是私钥和证书未加载，删掉 ingress 网关 pod 以强行重启 ingress 网关 pod 并重新加载私钥和证书。

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio=ingressgateway
    {{< /text >}}

*   验证 ingress 网关的证书的 `Subject` 是正确的：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-certs/tls.crt | openssl x509 -text -noout | grep 'Subject:'
        Subject: CN=httpbin.example.com, O=httpbin organization
    {{< /text >}}

*   验证 ingress 网关的代理是否知道证书：

    {{< text bash >}}
    $ kubectl exec -ti $(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -n istio-system -- pilot-agent request GET certs
    {
      "ca_cert": "",
      "cert_chain": "Certificate Path: /etc/istio/ingressgateway-certs/tls.crt, Serial Number: 100212, Days until Expiration: 370"
    }
    {{< /text >}}

*   检查 `istio-ingressgateway` 的日志看是否有错误消息：

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=ingressgateway
    {{< /text >}}

*   对于 macOS 用户，验证您是否使用的是用 [LibreSSL](http://www.libressl.org) 库编译的`curl`，如[开始之前](#before-you-begin)部分中所述。

### 双向 TLS 问题排查{#troubleshooting-for-mutual-TLS}

除了上一节中的步骤之外，请执行以下操作：

*   验证 `istio-ingressgateway` pod 已经加载了 CA 证书：

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-ca-certs
    {{< /text >}}

    `example.com.crt` 应存在于文件夹之中。

*   如果您已经创建了 `istio-ingressgateway-ca-certs` secret，但是 CA 证书未加载，删掉 ingress 网关 pod 以强行重新加载证书：
*   If you created the `istio-ingressgateway-ca-certs` secret, but the CA
    certificate is not loaded, delete the ingress gateway pod and force it to
    reload the certificate:

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio=ingressgateway
    {{< /text >}}

*   验证 ingress 网关的 CA 证书的 `Subject` 是正确的：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-ca-certs/example.com.crt | openssl x509 -text -noout | grep 'Subject:'
    Subject: O=example Inc., CN=example.com
    {{< /text >}}

## 清理{#cleanup}

1. 删除 `Gateway` 配置、`VirtualService` 和 secrets：

    {{< text bash >}}
    $ kubectl delete gateway --ignore-not-found=true httpbin-gateway bookinfo-gateway
    $ kubectl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret istio-ingressgateway-certs istio-ingressgateway-ca-certs
    $ kubectl delete --ignore-not-found=true virtualservice bookinfo
    {{< /text >}}

1. 删除证书目录和用于生成证书的存储库：

    {{< text bash >}}
    $ rm -rf example.com.crt example.com.key httpbin.example.com.crt httpbin.example.com.key httpbin.example.com.csr httpbin-client.example.com.crt httpbin-client.example.com.key httpbin-client.example.com.csr bookinfo.com.crt bookinfo.com.key bookinfo.com.csr
    {{< /text >}}

1. 删除用于重新部署 `istio-ingressgateway` 的更新文件：

    {{< text bash >}}
    $ rm -f gateway-patch.json
    {{< /text >}}

1. 关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

    {{< text bash >}}
    $ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}
