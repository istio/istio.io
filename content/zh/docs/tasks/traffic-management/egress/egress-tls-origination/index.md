---
title: Egress TLS 源
description: 描述如何配置 Istio 对来自外部服务的流量执行 TLS 发起。
keywords: [traffic-management,egress]
weight: 20
aliases:
  - /zh/docs/examples/advanced-gateways/egress-tls-origination/
owner: istio/wg-networking-maintainers
test: yes
---

[控制出口流量](/zh/docs/tasks/traffic-management/egress/)的任务向我们展示了位于服务网格内部的应用应如何访问外部
（即服务网格之外）的 HTTP 和 HTTPS 服务。
正如该任务所述，[`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/)
用于配置 Istio 以受控的方式访问外部服务。
本示例将演示如何通过配置 Istio 去实现对发往外部服务的流量的 {{< gloss >}}TLS origination{{< /gloss >}}。
若此时原始的流量为 HTTP，则 Istio 会将其转换为 HTTPS 连接。

## 使用场景  {#use-case}

假设有一个传统应用正在使用 HTTP 和外部服务进行通信。
而运行该应用的组织却收到了一个新的需求，该需求要求必须对所有外部的流量进行加密。
此时，使用 Istio 便可通过修改配置实现此需求，而无需更改应用中的任何代码。
该应用可以发送未加密的 HTTP 请求，由 Istio 为请求进行加密。

从应用源头发起未加密的 HTTP 请求，并让 Istio 执行 TLS
升级的另一个好处是可以产生更好的遥测并为未加密的请求提供更多的路由控制。

## 开始之前  {#before-you-begin}

* 根据[安装指南](/zh/docs/setup/)中的说明部署 Istio。

* 启动 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，该应用将用作外部调用的测试源。

    如果启用了 [Sidecar 的自动注入功能](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，
    运行以下命令部署 `sleep` 应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则在部署 `sleep` 应用之前，您必须手动注入 Sidecar。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    请注意，实际上任何可以执行 `exec` 和 `curl` 的 Pod 都可以用来完成这一任务。

* 创建一个环境变量来保存用于将请求发送到外部服务 Pod 的名称。
    如果您使用的是 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，请运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 配置对外部服务的访问   {#configuring-access-to-an-external-service}

首先，使用与[访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control)任务中的相同配置，
来配置对外部服务 `edition.cnn.com` 的访问。
但这一次我们将使用单个 `ServiceEntry` 来启用对服务的 HTTP 和 HTTPS 访问。

1. 创建一个 `ServiceEntry` 启用对 `edition.cnn.com` 的访问：

    {{< text syntax=bash snip_id=apply_simple >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1. 向外部的 HTTP 服务发送请求：

    {{< text syntax=bash snip_id=curl_simple >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    ...
    {{< /text >}}

    输出应与上面类似（某些细节用省略号代替）。

请注意 **curl** 的 `-L` 标志，该标志指示 **curl** 将遵循重定向。
在这种情况下，服务器将对到 `http://edition.cnn.com/politics` 的 HTTP 请求返回重定向响应
（[301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2)）。
而重定向响应将指示客户端使用 HTTPS 向 `https://edition.cnn.com/politics` 重新发送请求。
对于第二个请求，服务器则返回了请求的内容和 **200 OK** 状态码。

尽管 **curl** 命令简明地处理了重定向，但是这里有两个问题。
第一个问题是请求冗余，它使获取 `http://edition.cnn.com/politics` 内容的延迟加倍。
第二个问题是 URL 中的路径（在本例中为 **politics**）被以明文的形式发送。
如果有人嗅探您的应用与 `edition.cnn.com` 之间的通信，他将会知晓该应用获取了此网站中哪些特定的内容。
而出于隐私的原因，您可能希望阻止这些内容被披露。

通过配置 `Istio` 执行 `TLS` 发起，则可以解决这两个问题。

## 用于出口流量的 TLS 源   {#TLS-origination-for-egress-traffic}

1. 重新定义上一节的 `ServiceEntry` 和 `VirtualService` 以重写 HTTP 请求端口，
   并添加一个 `DestinationRule` 以执行 TLS 发起。

    {{< text syntax=bash snip_id=apply_origination >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: SIMPLE # 访问 edition.cnn.com 时启动 HTTPS
    EOF
    {{< /text >}}

    上面的 `DestinationRule` 将对端口 80 和 `ServiceEntry` 上的 HTTP 请求执行 TLS 发起。
    然后将端口 80 上的请求重定向到目标端口 443。

1. 如上一节一样，向 `http://edition.cnn.com/politics` 发送 HTTP 请求：

    {{< text syntax=bash snip_id=curl_origination_http >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    这次将会收到唯一的 **200 OK** 响应。
    因为 Istio 为 **curl** 执行了 TLS 发起，原始的 HTTP 被升级为 HTTPS 并转发到 `edition.cnn.com`。
    服务器直接返回内容而无需重定向。这消除了客户端与服务器之间的请求冗余，使网格保持加密状态，
    隐藏了您的应用获取 `edition.cnn.com` 中 **politics** 的事实。

    请注意，您使用了一些与上一节相同的命令。
    对于以编程方式访问外部服务的应用程序，不需更改代码。
    您可以通过配置 Istio 来获得 TLS 发起的好处，而无需更改一行代码。

1. 请注意，使用 HTTPS 访问外部服务的应用程序将继续像以前一样工作：

    {{< text syntax=bash snip_id=curl_origination_https >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/2 200
    ...
    {{< /text >}}

## 其它安全注意事项   {#additional-security-considerations}

由于应用程序 Pod 和本地主机上的 Sidecar 代理之间的流量仍未加密，
因此能够渗透应用程序节点的攻击者仍然能够看到该节点本地网络上的未加密通信。
在某些环境中，严格的安全性要求可能规定所有流量都必须加密，即使在节点的本地网络上也是如此。
鉴于如此严格的要求，应用程序应仅使用 HTTPS（TLS），本示例中描述的 TLS 发起还不足以满足要求。

还要注意，即使应用发起的是 HTTPS 请求，攻击者也可能会通过检查
[服务器名称指示（SNI）](https://zh.wikipedia.org/wiki/%E6%9C%8D%E5%8A%A1%E5%99%A8%E5%90%8D%E7%A7%B0%E6%8C%87%E7%A4%BA)
知道客户端正在对 `edition.cnn.com` 发送请求。**SNI** 字段在 TLS 握手过程中以未加密的形式发送。
使用 HTTPS 可以防止攻击者知道客户端访问了哪些特点的内容，但并不能阻止攻击者得知客户端访问了 `edition.cnn.com` 站点。

### 清理 TLS 发起配置   {#cleanup-the-tls-origination-configuration}

移除您创建的 Istio 配置项：

{{< text bash >}}
$ kubectl delete serviceentry edition-cnn-com
$ kubectl delete destinationrule edition-cnn-com
{{< /text >}}

## 出口流量的双向 TLS 源   {#mutual-tls-origination-for-egress-traffic}

本节介绍如何配置 Sidecar 为外部服务执行 TLS 发起，这次使用需要双向 TLS 的服务。
此示例涉及许多内容，需要先执行以下前置操作：

1. 生成客户端和服务器证书
1. 部署支持双向 TLS 协议的外部服务
1. 将客户端（sleep Pod）配置为使用在步骤 1 中创建的凭据

完成上述前置操作后，您可以将外部流量配置为经由该 Sidecar，执行 TLS 发起。

### 生成客户端证书、服务器证书、客户端密钥和服务器密钥   {#generate-client-and-server-certificates-and-keys}

对于此任务，您可以使用您最喜欢的工具来生成证书和密钥。
以下命令使用 [openssl](https://man.openbsd.org/openssl.1)。

1.  创建根证书和私钥来为您的服务签署证书：

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  为 `my-nginx.mesh-external.svc.cluster.local` 创建证书和私钥：

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    或者，如果您想要为目标启用 SAN 验证，您可以将
    `SubjectAltNames` 添加到证书中。例如：

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1.  生成客户端证书和私钥：

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### 部署双向 TLS 服务器   {#deploy-a-mutual-tls-server}

要模拟支持双向 TLS 协议的实际外部服务，请在 Kubernetes 集群中部署一个
[NGINX](https://www.nginx.com) 服务器，但在 Istio 服务网格之外运行，
即在没有启用 Istio Sidecar 代理注入的命名空间中。

1.  创建一个命名空间来表示 Istio 网格外部的服务，命名为 `mesh-external`。
    请注意，Sidecar 代理不会自动注入到此命名空间的 Pod 中，
    因为未在其中[启用](/zh/docs/setup/additional-setup/sidecar-injection/#deploying-an-app)自动 Sidecar 注入。

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1.  创建 Kubernetes [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)
    来保存服务器证书和 CA 证书。

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  为 NGINX 服务器创建配置文件：

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  创建一个 Kubernetes [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/)
    来保存 NGINX 服务器的配置：

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  部署 NGINX 服务器：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
      annotations:
        "networking.istio.io/exportTo": "." # simulate an external service by not exporting outside this namespace
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

### 配置客户端 —— sleep Pod   {#configure-the-client-sleep-pod}

1.  创建 Kubernetes [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)
    来保存客户端的证书：

    {{< text bash >}}
    $ kubectl create secret generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

    **必须**在部署客户端 Pod 的统一命名空间中创建密钥，本例为 `default` 命名空间。

    {{< boilerplate crl-tip >}}

1. 创建必需的 `RBAC` 以确保在上述步骤中创建的密钥对客户端 Pod 是可访问的，在本例中是 `sleep`。

    {{< text bash >}}
    $ kubectl create role client-credential-role --resource=secret --verb=list
    $ kubectl create rolebinding client-credential-role-binding --role=client-credential-role --serviceaccount=default:sleep
    {{< /text >}}

### 为 Sidecar 上的出口流量配置双向 TLS 源   {#configure-mutual-tls-origination-for-egress-traffic-at-sidecar}

1. 添加 `ServiceEntry` 将 HTTP 请求重定向到 443 端口，并且添加 `DestinationRule`
   以执行发起双向 TLS：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: originate-mtls-for-nginx
    spec:
      hosts:
      - my-nginx.mesh-external.svc.cluster.local
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
        targetPort: 443
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-mtls-for-nginx
    spec:
      workloadSelector:
        matchLabels:
          app: sleep
      host: my-nginx.mesh-external.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: MUTUAL
            credentialName: client-credential # 这必须与之前创建的用于保存客户端证书的 Secret 相匹配，并且仅当 DR 具有工作负载选择器时才有效
            sni: my-nginx.mesh-external.svc.cluster.local # 这是可选的
    EOF
    {{< /text >}}

    上面 `DestinationRule` 将在 80 端口对 HTTP 执行发起 mTLS 请求，
    之后 `ServiceEntry` 将把 80 端口的请求重定向到 443 端口。

1.  验证凭据是否已提供给 Sidecar 并且处于活跃状态：

    {{< text bash >}}
    $ istioctl proxy-config secret deploy/sleep | grep client-credential
    kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:15:20Z     2023-06-05T12:15:20Z
    kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           10792363984292733914                       2024-06-04T12:15:19Z     2023-06-05T12:15:19Z
    {{< /text >}}

1.  发送一个 HTTP 请求到 `http://my-nginx.mesh-external.svc.cluster.local`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

1.  检查 `sleep` Pod 的日志中是否有与我们的请求相对应的行：

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy | grep 'my-nginx.mesh-external.svc.cluster.local'
    {{< /text >}}

    您应看到一行类似以下的输出：

    {{< text plain>}}
    [2022-05-19T10:01:06.795Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 1 0 "-" "curl/7.83.1-DEV" "96e8d8a7-92ce-9939-aa47-9f5f530a69fb" "my-nginx.mesh-external.svc.cluster.local:443" "10.107.176.65:443"
    {{< /text >}}

### 清理双向 TLS 发起配置   {#cleanup-the-mutual-tls-origination-configuration}

1. 移除创建的 Kubernetes 资源：

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete secret client-credential
    $ kubectl delete rolebinding client-credential-role-binding
    $ kubectl delete role client-credential-role
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    $ kubectl delete serviceentry originate-mtls-for-nginx
    $ kubectl delete destinationrule originate-mtls-for-nginx
    {{< /text >}}

1. 删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1. 删除本示例中用过的和生成的那些配置文件：

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## 清理常用配置    {#cleanup-common-configuration}

删除 `sleep` Service 和 Deployment：

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
