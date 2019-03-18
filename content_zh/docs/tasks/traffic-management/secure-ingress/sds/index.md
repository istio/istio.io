---
title: 使用 SDS 为 Gateway 提供 HTTPS 加密支持
description: 如何配置 Istio，借助 SDS（Secret 发现服务），使用 TLS 或双向 TLS 将服务开放到网格之外。
weight: 32
keywords: [traffic-management,ingress,sds-credentials]
---

[控制 Ingress 流量任务](/zh/docs/tasks/traffic-management/ingress)中描述了如何进行配置，通过 Ingress Gateway 把服务的 HTTP 端点暴露给外部。这里更进一步，使用单向或者双向 TLS 来完成开放服务的任务。双向 TLS 所需的私钥、服务器证书以及根证书都由 Secret 发现服务（SDS）完成配置。

## 开始之前 {#before-you-begin}

1. 首先要完成 [Ingress 任务的初始化步骤](/zh/docs/tasks/traffic-management/ingress#前提条件)，并[获取 Ingress 的地址和端口](/zh/docs/tasks/traffic-management/ingress#确定入口-ip-和端口)，在完成这些步骤之后，也就是完成了 Istio 和 [httpbin]({{< github_tree >}}/samples/httpbin) 的部署，并设置了 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 两个环境变量的值。

1. macOS 用户应该检查一下本机的 `curl` 是否是使用 [LibreSSL](http://www.libressl.org) 库进行编译的：

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    如果上面的命令输出了一段 LibreSSL 的版本信息，就说明你的 `curl` 命令可以完成本任务的内容。否则就要想办法换一个不同的 `curl` 了，例如可以换用一台运行 Linux 的工作站。

## 为服务器和客户端生成证书 {#generate-client-and-server-certificates-and-keys}

可以使用各种常用工具来生成证书和私钥。这个例子中用了一个来自 <https://github.com/nicholasjackson/mtls-go-example> 的[脚本](https://github.com/nicholasjackson/mtls-go-example/blob/master/generate.sh)来完成工作。

1. 克隆[示例代码库](https://github.com/nicholasjackson/mtls-go-example)：

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1. 进入代码库文件夹：

    {{< text bash >}}
    $ pushd mtls-go-example
    {{< /text >}}

1. 为 `httpbin.example.com` 生成证书。注意要把下面命令中的 `password` 替换为其它值。

    {{< text bash >}}
    $ ./generate.sh httpbin.example.com password
    {{< /text >}}

    看到提示后，所有问题都输入 `Y` 即可。这个命令会生成四个目录：`1_root`、`2_intermediate`、`3_application` 以及 `4_client`。这些目录中包含了后续过程所需的客户端和服务端证书。

1. 把证书移动到 `httpbin.example.com` 目录之中：

    {{< text bash >}}
    $ mkdir ~+1/httpbin.example.com && mv 1_root 2_intermediate 3_application 4_client ~+1/httpbin.example.com
    {{< /text >}}

1. 返回之前的目录：

    {{< text bash >}}
    $ popd
    {{< /text >}}

## 使用 SDS 配置 TLS Ingress 网关

可以配置 TLS Ingress 网关，让它从 Ingress 网关代理通过 SDS 获取凭据。Ingress 网关代理和 Ingress 网关在同一个 Pod 中运行，监视 Ingress 网关所在命名空间中新建的 `Secret`。在 Ingress 网关中启用 SDS 具有如下好处：

* Ingress 网关无需重启，就可以动态的新增、删除或者更新密钥/证书对以及根证书。

* 无需加载 `Secret` 卷。创建了 `kubernetes` `Secret` 之后，这个 `Secret` 就会被网关代理捕获，并以密钥/证书对和根证书的形式发送给 Ingress 网关。

* 网关代理能够监视多个密钥/证书对。只需要为每个主机名创建 `Secret` 并更新网关定义就可以了。

1. 在 Ingress 网关上启用 SDS，并部署 Ingress 网关代理。

    这个功能缺省是禁用的，因此需要在 Helm 中打开 [`istio-ingressgateway.sds.enabled` 开关]({{<github_blob>}}/install/kubernetes/helm/istio/charts/gateways/values.yaml)，然后生成 `istio-ingressgateway.yaml` 文件：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio \
    --namespace istio-system -x charts/gateways/templates/deployment.yaml \
    --set gateways.istio-egressgateway.enabled=false \
    --set gateways.istio-ingressgateway.sds.enabled=true > \
    $HOME/istio-ingressgateway.yaml
    $ kubectl apply -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1. 设置两个环境变量：`INGRESS_HOST` 和 `SECURE_INGRESS_PORT`：

    {{< text bash >}}
    $ export SECURE_INGRESS_PORT=$(kubectl -n istio-system \
    get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    $ export INGRESS_HOST=$(kubectl -n istio-system \
    get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

### 为单一主机配置 TLS Ingress 网关 {#configure-a-TLS-ingress-gateway-for-a-single-host}

1. 启动 `httpbin` 样例：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - name: http
        port: 8000
      selector:
        app: httpbin
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: httpbin
            version: v1
        spec:
          containers:
          - image: docker.io/citizenstig/httpbin
            imagePullPolicy: IfNotPresent
            name: httpbin
            ports:
            - containerPort: 8000
    EOF
    {{< /text >}}

1. 为 Ingress 网关创建 `Secret：`

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic httpbin-credential \
    --from-file=key=httpbin.example.com/3_application/private/httpbin.example.com.key.pem \
    --from-file=cert=httpbin.example.com/3_application/certs/httpbin.example.com.cert.pem
    {{< /text >}}

1. 创建一个网关，其 `servers:` 字段的端口为 443，设置 `credentialName` 的值为  `httpbin-credential`。这个值就是 `Secret` 的名字。TLS 模式设置为 `SIMPLE`。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # 使用缺省的 Ingress 网关。
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: "httpbin-credential" # 和 Secret 名称一致
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 配置网关的 Ingress 流量路由，并配置对应的 `VirtualService`：：

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

1. 用 HTTPS 协议访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    {{< /text >}}

    `httpbin` 服务会返回 [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3)。

1. 删除网关的 `Secret`，并新建另外一个，然后修改 Ingress 网关的凭据：

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    {{< /text >}}

    {{< text bash >}}
    $ pushd mtls-go-example
    $ ./generate.sh httpbin.example.com <password>
    $ mkdir ~+1/httpbin.new.example.com && mv 1_root 2_intermediate \
    3_application 4_client ~+1/httpbin.new.example.com
    $ popd
    $ kubectl create -n istio-system secret generic httpbin-credential \
    --from-file=key=httpbin.new.example.com/3_application/private/httpbin.example.com.key.pem \
    --from-file=cert=httpbin.new.example.com/3_application/certs/httpbin.example.com.cert.pem
    {{< /text >}}

1. 使用 `curl` 访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.new.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
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

1. 如果尝试使用之前的证书链来再次访问 `httpbin`，就会得到失败的结果：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * SSL certificate problem: unable to get local issuer certificate
    {{< /text >}}

### 为 TLS Ingress 网关配置多个主机名 {#configure-a-TLS-ingress-gateway-for-multiple-hosts}

可以把多个主机名配置到同一个 Ingress 网关上，例如 `httpbin.example.com` 和 `helloworld-v1.example.com`。Ingress 网关会为每个 `credentialName` 获取一个唯一的凭据。

1. 启动 `hellowworld-v1` 示例：

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
        port: 8000
      selector:
        app: helloworld-v1
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: helloworld-v1
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

1. 为 Ingress 网关创建一个 Ingress。如果已经创建了  `httpbin-credential`，就可以创建 `helloworld-credential` Secret 了。

    {{< text bash >}}
    $ pushd mtls-go-example
    $ ./generate.sh helloworld-v1.example.com <password>
    $ mkdir ~+1/helloworld-v1.example.com && mv 1_root 2_intermediate \
    3_application 4_client ~+1/helloworld-v1.example.com
    $ popd
    $ kubectl create -n istio-system secret generic helloworld-credential \
    --from-file=key=helloworld-v1.example.com/3_application/private/helloworld-v1.example.com.key.pem \
    --from-file=cert=helloworld-v1.example.com/3_application/certs/helloworld-v1.example.com.cert.pem
    {{< /text >}}

1. 定义一个网关，其中包含了两个 `server`，都开放了 443 端口。两个 `credentialName` 字段分别赋值为 `httpbin-credential` 和 `helloworld-credential`。`serverCertificate` 以及 `privateKey` 应该为空。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # 使用缺省的 Ingress 网关
      servers:
      - port:
          number: 443
          name: https-httpbin
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: "httpbin-credential"
        hosts:
        - "httpbin.example.com"
      - port:
          number: 443
          name: https-helloworld
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: "helloworld-credential"
        hosts:
        - "helloworld-v1.example.com"
    EOF
    {{< /text >}}

1. 配置网关的流量路由，配置 `VirtualService`：、

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: helloworld-v1
    spec:
      hosts:
      - "helloworld-v1.example.com"
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

1. 向 `helloworld-v1.example.com` 发送 HTTPS 请求：

    {{< text bash >}}
    $ curl -v -HHost:helloworld-v1.example.com \
    --resolve helloworld-v1.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert helloworld-v1.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://helloworld-v1.example.com:$SECURE_INGRESS_PORT/hello
    HTTP/2 200
    {{< /text >}}

1. 发送 HTTPS 请求到 `httpbin.example.com`，还是会看到茶壶：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

### 配置双向 TLS Ingress 网关 {#configure-a-mutual-TLS-ingress-gateway}

可以对网关的定义进行扩展，加入[双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication) 的支持。要修改 Ingress 网关的凭据，就要删除并重建对应的 `Secret`。服务器会使用 CA 证书对客户端进行校验，因此需要使用 `cacert` 字段来保存 CA 证书：

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential  \
    --from-file=key=httpbin.example.com/3_application/private/httpbin.example.com.key.pem \
    --from-file=cert=httpbin.example.com/3_application/certs/httpbin.example.com.cert.pem \
    --from-file=cacert=httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem
    {{< /text >}}

1. 修改网关定义，设置 TLS 的模式为 `MUTUAL`：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
     name: mygateway
    spec:
     selector:
       istio: ingressgateway # Istio 的缺省 Ingress 网关
     servers:
     - port:
         number: 443
         name: https
         protocol: HTTPS
       tls:
         mode: MUTUAL
         credentialName: "httpbin-credential" # 和 Secret 名称一致
       hosts:
       - "httpbin.example.com"
    EOF
    {{< /text >}}

1. 使用前面的方式尝试发出 HTTPS 请求，会看到失败的过程：

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    * TLSv1.2 (OUT), TLS header, Certificate Status (22):
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (IN), TLS handshake, Server key exchange (12):
    * TLSv1.2 (IN), TLS handshake, Request CERT (13):
    * TLSv1.2 (IN), TLS handshake, Server finished (14):
    * TLSv1.2 (OUT), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
    * TLSv1.2 (OUT), TLS change cipher, Client hello (1):
    * TLSv1.2 (OUT), TLS handshake, Finished (20):
    * TLSv1.2 (IN), TLS alert, Server hello (2):
    * error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
    {{< /text >}}

1. 在 `curl` 命令中加入客户端证书和私钥的参数，重新发送请求。（客户端证书参数为 `--cert`，私钥参数为 `--key`）

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com \
    --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert httpbin.example.com/2_intermediate/certs/ca-chain.cert.pem \
    --cert httpbin.example.com/4_client/certs/httpbin.example.com.cert.pem \
    --key httpbin.example.com/4_client/private/httpbin.example.com.key.pem \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/

    {{< /text >}}

## 故障排查 {#troubleshooting}

* 查看 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 环境变量。根据下面的输出内容，确认其中是否包含了有效的值：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

* 检查 `istio-ingressgateway` 控制器的日志，搜寻其中的错误信息：

    {{< text bash >}}
    $ kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

* 如果使用的是 macOS，检查其编译信息，确认其中包含 [LibreSSL](http://www.libressl.org)，具体步骤在[开始之前](#before-you-begin)一节中有具体描述。

* 在 `istio-system` 命名空间中是否成功创建了 `Secret`：

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` 和 `helloworld-credential` 都应该出现在列表之中。

* 检查日志，看 Ingress 网关代理是否已经成功的把密钥和证书对推送给了 Ingress 网关：

    {{< text bash >}}
    $ kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}') -c ingress-sds
    {{< /text >}}

    正常情况下，日志中应该显示 `httpbin-credential` 已经成功创建。如果使用的是双向 TLS，还应该看到 `httpbin-credential-cacert`。通过对日志的查看，能够验证 Ingress 网关代理从 Ingress 网关收到了 SDS 请求，资源名称是  `httpbin-credential`，Ingress 网关最后得到了应有的密钥/证书对。如果使用的是双向 TLS，日志会显示出密钥/证书对已经发送给 Ingress 网关，网关代理接收到了资源名为 `httpbin-credential-cacert` 的 SDS 请求，Ingress 网关用这种方式获取根证书。

## 清理 {#cleanup}

1. 删除网关配置、`VirtualService` 以及 `Secret`：

    {{< text bash >}}
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret httpbin-credential \
    helloworld-credential
    $ kubectl delete --ignore-not-found=true virtualservice helloworld-v1
    {{< /text >}}

1. 删除证书目录以及用于生成证书的代码库：

    {{< text bash >}}
    $ rm -rf httpbin.example.com helloworld-v1.example.com mtls-go-example
    {{< /text >}}

1. 删除用于重新部署 Ingress 网关的文件：

    {{< text bash >}}
    $ rm -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1. 关闭 `httpbin` 和 `helloworld-v1` 服务：

    {{< text bash >}}
    $ kubectl delete service --ignore-not-found=true helloworld-v1
    $ kubectl delete service --ignore-not-found=true httpbin
    {{< /text >}}
