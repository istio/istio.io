---
title: Egress TLS Origination
description: 描述如何配置 Istio 对来自外部服务的流量执行 TLS 发起。
keywords: [traffic-management,egress]
weight: 20
aliases:
  - /zh/docs/examples/advanced-gateways/egress-tls-origination/
owner: istio/wg-networking-maintainers
test: yes
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)的任务向我们展示了位于服务网格内部的应用应如何访问外部（即服务网格之外）的 HTTP 和 HTTPS 服务。
正如该任务所述，[`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/) 用于配置 Istio 以受控的方式访问外部服务。
本示例将演示如何通过配置 Istio 去实现对发往外部服务的流量的 {{< gloss >}}TLS origination{{< /gloss >}}。
若此时原始的流量为 HTTP，则 Istio 会将其转换为 HTTPS 连接。

## 使用场景{#use-case}

假设有一个传统应用正在使用 HTTP 和外部服务进行通信。
而运行该应用的组织却收到了一个新的需求，该需求要求必须对所有外部的流量进行加密。
此时，使用 Istio 便可通过修改配置实现此需求，而无需更改应用中的任何代码。
该应用可以发送未加密的 HTTP 请求，然后 Istio 将为应用加密请求。

从应用源头发送未加密的 HTTP 请求并让 Istio 执行 TSL
升级的另一个好处是可以产生更好的遥测并为未加密的请求提供更多的路由控制。

## 开始之前{#before-you-begin}

*   根据[安装指南](/zh/docs/setup/)中的说明部署 Istio。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 示例，该示例将用作外部调用的测试源。

    如果启用了 [Sidecar 的自动注入功能](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，运行以下命令部署 `sleep` 应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则在部署 `sleep` 应用之前，您必须手动注入 Sidecar。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    请注意，实际上任何可以 `exec` 和 `curl` 的 Pod 都可以用来完成这一任务。

*   创建一个环境变量来保存用于将请求发送到外部服务 Pod 的名称。
    如果您使用 [sleep]({{< github_tree >}}/samples/sleep) 示例，请运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 配置对外部服务的访问{#configuring-access-to-an-external-service}

首先，使用与 [Egress 流量控制](/zh/docs/tasks/traffic-management/egress/)任务中的相同技术，
配置对外部服务 `edition.cnn.com` 的访问。
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
 ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2))。
而重定向响应将指示客户端使用 HTTPS 向 `https://edition.cnn.com/politics` 重新发送请求。
对于第二个请求，服务器则返回了请求的内容和 _200 OK_ 状态码。

尽管 **curl** 命令简明地处理了重定向，但是这里有两个问题。
第一个问题是请求冗余，它使获取 `http://edition.cnn.com/politics` 内容的延迟加倍。
第二个问题是 URL 中的路径（在本例中为 **politics** ）被以明文的形式发送。
如果有人嗅探您的应用与 `edition.cnn.com` 之间的通信，他将会知晓该应用获取了此网站中哪些特定的内容。
而出于隐私的原因，您可能希望阻止这些内容被披露。

通过配置 `Istio` 执行 `TLS` 发起，则可以解决这两个问题。

## 用于 egress 流量的 TLS 发起{#TLS-origination-for-egress-traffic}

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
            mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
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
    因为 Istio 为 **curl** 执行了 TSL 发起，原始的 HTTP 被升级为 HTTPS 并转发到 `edition.cnn.com`。
    服务器直接返回内容而无需重定向。这消除了客户端与服务器之间的请求冗余，使网格保持加密状态，
    隐藏了您的应用获取 `edition.cnn.com` 中 **politics** 的事实。

    请注意，您使用了一些与上一节相同的命令。
    您可以通过配置 Istio，使以编程方式访问外部服务的应用无需更改任何代码即可获得 TLS 发起的好处。

1. 请注意，使用 HTTPS 访问外部服务的应用程序将继续像以前一样工作：

    {{< text syntax=bash snip_id=curl_origination_https >}}
    $ kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/2 200
    ...
    {{< /text >}}

## 其它安全注意事项{#additional-security-considerations}

由于应用容器与本地 Host 上的 Sidecar 代理之间的流量仍未加密，能够渗透到您应用 Node 的攻击者仍然可以看到未加密 Node 本地网络上的通信。
在某些环境中，严格的安全性要求可能规定所有流量都必须加密，即使在 Node 的本地网络上也是如此。
此时，使用在此示例中描述的 TLS 发起是不能满足要求的，应用应仅使用 HTTPS（TLS）而不是 HTTP。

还要注意，即使应用发起的是 HTTPS 请求，攻击者也可能会通过检查
[Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication)
知道客户端正在对 `edition.cnn.com` 发送请求。**SNI** 字段在 TLS 握手过程中以未加密的形式发送。
使用 HTTPS 可以防止攻击者知道客户端访问了哪些特点的内容，但并不能阻止攻击者得知客户端访问了 `edition.cnn.com` 站点。

### 清理 TLS 发起配置{#cleanup-the-tls-origination-configuration}

移除您创建的 Istio 配置项:

{{< text bash >}}
$ kubectl delete serviceentry edition-cnn-com
$ kubectl delete destinationrule edition-cnn-com
{{< /text >}}

## 出口流量的双向 TLS 发起{#mutual-tls-origination-for-egress-traffic}

本节介绍如何配置 sidecar 为外部服务执行 TLS 发起，这次使用需要双向 TLS 的服务。
此示例涉及许多内容，需要先执行以下前置操作：

1. 生成客户端和服务器证书
1. 部署支持双向 TLS 协议的外部服务
1. 将客户端（sleep Pod）配置为使用在步骤 1 中创建的凭据

完成上述前置操作后，您可以将外部流量配置为经由该 Sidecar，执行 TLS 发起。

### 生成客户端证书、服务器证书、客户端密钥和服务器密钥{#generate-client-and-server-certificates-and-keys}

按照 Egress Gateway TLS 发起任务中的[这些步骤](/zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#generate-client-and-server-certificates-and-keys)进行操作。

### 部署双向 TLS 服务器{#deploy-a-mutual-tls-server}

按照 Egress Gateway TLS 发起任务中的[这些步骤](/zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#deploy-a-mutual-tls-server)进行操作。

### 配置客户端——sleep Pod{#configure-the-client-sleep-pod}

1.  创建 Kubernetes [密钥](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)来保存客户端的证书：

    {{< text bash >}}
    $ kubectl create secret generic client-credential --from-file=tls.key=client.example.com.key \
      --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
    {{< /text >}}

    **必须**在部署客户端 Pod 的统一命名空间中创建密钥，本例为 `default`。

    {{< boilerplate crl-tip >}}

1. 创建必需的 `RBAC` 以确保在上述步骤中创建的密钥对客户端 Pod 是可访问的，在本例中是 `sleep`。

    {{< text bash >}}
    $ kubectl create role client-credential-role --resource=secret --verb=list
    $ kubectl create rolebinding client-credential-role-binding --role=client-credential-role --serviceaccount=default:sleep
    {{< /text >}}

### 为 Sidecar 上的出口流量配置双向 TLS 发起{#configure-mutual-tls-origination-for-egress-traffic-at-sidecar}

1. 添加 `ServiceEntry` 将 HTTP 请求重定向到 443 端口，并且添加 `DestinationRule` 以执行发起双向 TLS:

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
            credentialName: client-credential # this must match the secret created earlier to hold client certs, and works only when DR has a workloadSelector
            sni: my-nginx.mesh-external.svc.cluster.local # this is optional
    EOF
    {{< /text >}}

    上面 `DestinationRule` 将在 80 端口对 HTTP 执行发起 mTLS 请求，
    之后 `ServiceEntry` 将把 80 端口的请求重定向到 443 端口。

1.  验证凭据是否已提供给 Sidecar 并且处于活跃状态。

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

1.  检查 `sleep` Pod 的日志中是否有与我们的请求相对应的行。

    {{< text bash >}}
    $ kubectl logs -l app=sleep -c istio-proxy | grep 'my-nginx.mesh-external.svc.cluster.local'
    {{< /text >}}

    您应看到一行类似以下的输出：

    {{< text plain>}}
    [2022-05-19T10:01:06.795Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 1 0 "-" "curl/7.83.1-DEV" "96e8d8a7-92ce-9939-aa47-9f5f530a69fb" "my-nginx.mesh-external.svc.cluster.local:443" "10.107.176.65:443"
    {{< /text >}}

### 清理双向 TLS 发起配置{#cleanup-the-mutual-tls-origination-configuration}

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

1.  删除证书和私钥：

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

1. 删除本示例中用过的和生成的那些配置文件：

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## 清理常用配置{#cleanup-common-configuration}

删除 `sleep` Service 和 Deployment：

{{< text bash >}}
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}
