---
title: "Istio Ambient Mesh 入门"
description: "Istio Ambient Mesh 入门分步指南。"
publishdate: 2022-09-07T08:00:00-06:00
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [ambient,demo,guide]
---

Ambient Mesh 是 [Istio 如今引入的全新数据平面模式](/zh/blog/2022/introducing-ambient-mesh/)。
跟随本入门指南，您可以体验 Ambient Mesh 如何简化您的应用上线，如何助力当前业务运营，如何减少服务网格基础设施的资源用量。

## 以 Ambient 模式安装 Istio {#install-istio-with-ambient-mode}

1. [下载支持 Ambient Mesh 的 Istio 预览版](https://gcsweb.istio.io/gcs/istio-build/dev/0.0.0-ambient.191fe680b52c1754ee72a06b3e0d3f9d116f2e82)。
1. 检查[支持的环境]({{< github_raw >}}/tree/experimental-ambient#supported-environments)。
   我们推荐使用不低于 1.21 版本的 Kubernetes 集群，至少要有 2 个节点。
   如果您还没有 Kubernetes 集群，您可以在本地安装（例如参照以下命令用 kind 安装）或在 Google 或 AWS 的云上部署一个 Kubernetes 集群：

{{< text bash >}}
$ kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ambient
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
{{< /text >}}

`ambient` 配置文件设计用于帮助开始使用 Ambient Mesh。
使用上述下载的 `istioctl`，用 `ambient` 配置文件将 Istio 安装到您的 Kubernetes 集群上：

{{< text bash >}}
$ istioctl install --set profile=ambient
{{< /text >}}

运行以上命令后，您将获得以下输出，表示这四个组件已成功安装！

{{< text plain >}}
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ CNI installed
✔ Installation complete
{{< /text >}}

默认情况下，ambient 配置文件已启用了 Istio 核心功能、Istiod、Ingress Gateway、零信任隧道代理 (ztunnel) 和 CNI 插件。
Istio CNI 插件负责检测哪些应用 Pod 属于 Ambient Mesh 并配置 ztunnel 之间的流量重定向。
您将看到以下 Pod 用默认的 ambient 配置文件安装到了 istio-system 命名空间中：

{{< text bash >}}
$ kubectl get pod -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-cni-node-97p9l                    1/1     Running   0          29s
istio-cni-node-rtnvr                    1/1     Running   0          29s
istio-cni-node-vkqzv                    1/1     Running   0          29s
istio-ingressgateway-5dc9759c74-xlp2j   1/1     Running   0          29s
istiod-64f6d7db7c-dq8lt                 1/1     Running   0          47s
ztunnel-bq6w2                           1/1     Running   0          47s
ztunnel-tcn4m                           1/1     Running   0          47s
ztunnel-tm9zl                           1/1     Running   0          47s
{{< /text >}}

istio-cni 和 ztunnel 组件被部署为 [Kubernetes `DaemonSet`](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/daemonset/) 运行在每个节点上。
每个 Istio CNI Pod 都会检查相同节点上并置的所有 Pod，以查看这些 Pod 是否属于 Ambient Mesh。
对于这些 Pod，CNI 插件将配置流量重定向，使得所有传入和传出 Pod 的流量均先重定向到并置的 ztunnel。
当新的 Pod 部署到此节点上或被移除时，CNI 插件会监控并更新重定向逻辑。

## 部署您的应用{#deploy-your-applications}

您将使用 [bookinfo 应用](/zh/docs/examples/bookinfo/)样例，此样例位于前面几步中下载的 Istio 包内。
在 ambient 模式中，将应用部署到 Kubernetes 集群的方式与没有 Istio 时的部署方式完全相同。
这意味着您可以在启用 Ambient Mesh 之前先让应用运行在 Kubernetes 中，然后将这些应用接入网格，不需要重启或重新配置这些应用。

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f https://raw.githubusercontent.com/linsun/sample-apps/main/sleep/sleep.yaml
$ kubectl apply -f https://raw.githubusercontent.com/linsun/sample-apps/main/sleep/notsleep.yaml
{{< /text >}}

{{< image width="75%"
    link="app-not-in-ambient.png"
    caption="采用纯文本流量未处于 Ambient Mesh 的应用"
    >}}

注：`sleep` 和 `notsleep` 是两个简单的应用，可用作 curl 客户端。

将 `productpage` 连接到 Istio Ingress Gateway，因此您可以从集群外部访问 bookinfo 应用：

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

测试您的 bookinfo 应用，不管有没有网关该应用都必须能够工作。
注：您可以将以下 `istio-ingressgateway.istio-system` 替换为其负载均衡器 IP（或 hostname）：

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

## 添加您的应用到 Ambient Mesh {#adding-your-application-to-the-ambient-mesh}

您只需为命名空间添加标签就能让给定命名空间内的所有 Pod 成为 Ambient Mesh 的一部分：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
{{< /text >}}

恭喜！您已成功将 default 命名空间中的所有 Pod 添加到 Ambient Mesh。
此处最大的优势是不需要重启，也不需要部署任何东西！

发送一些测试流量：

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

您在 Ambient Mesh 中的应用之间会使用 mTLS 通信。

{{< image width="75%"
    link="app-in-ambient-secure-overlay.png"
    caption="采用安全覆盖层从 sleep 到 `productpage` 以及从 `productpage` 到 reviews 的入站请求"
    >}}

如果您对每个身份的 X.509 证书有所好奇，您可以运行以下命令了解该证书相关的更多信息：

{{< text bash >}}
$ istioctl pc secret ds/ztunnel -n istio-system -o json | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode | openssl x509 -noout -text -in /dev/stdin
{{< /text >}}

例如，该输出表明本地 Kubernetes 集群签发的证书的 sleep 有效时间原则上为 24 小时。

{{< text plain >}}
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 307564724378612391645160879542592778778 (0xe762cfae32a3b8e3e50cb9abad32b21a)
    Signature Algorithm: SHA256-RSA
        Issuer: O=cluster.local
        Validity
            Not Before: Aug 29 21:00:14 2022 UTC
            Not After : Aug 30 21:02:14 2022 UTC
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: RSA
                Public-Key: (2048 bit)
                Modulus:
                    ac:db:1a:77:72:8a:99:28:4a:0c:7e:43:fa:ff:35:
                    75:aa:88:4b:80:4f:86:ca:69:59:1c:b5:16:7b:71:
                    dd:74:57:e2:bc:cf:ed:29:7d:7b:fa:a2:c9:06:e6:
                    d6:41:43:2a:3c:2c:18:8e:e8:17:f6:82:7a:64:5f:
                    c4:8a:a4:cd:f1:4a:9c:3f:e0:cc:c5:d5:79:49:37:
                    30:10:1b:97:94:2c:b7:1b:ed:a2:62:d9:3b:cd:3b:
                    12:c9:b2:6c:3c:2c:ac:54:5b:a7:79:97:fb:55:89:
                    ca:08:0e:2e:2a:b8:d2:e0:3b:df:b2:21:99:06:1b:
                    60:0d:e8:9d:91:dc:93:2f:7c:27:af:3e:fc:42:99:
                    69:03:9c:05:0b:c2:11:25:1f:71:f0:8a:b1:da:4a:
                    da:11:7c:b4:14:df:6e:75:38:55:29:53:63:f5:56:
                    15:d9:6f:e6:eb:be:61:e4:ce:4b:2a:f9:cb:a6:7f:
                    84:b7:4c:e4:39:c1:4b:1b:d4:4c:70:ac:98:95:fe:
                    3e:ea:5a:2c:6c:12:7d:4e:24:ab:dc:0e:8f:bc:88:
                    02:f2:66:c9:12:f0:f7:9e:23:c9:e2:4d:87:75:b8:
                    17:97:3c:96:83:84:3f:d1:02:6d:1c:17:1a:43:ce:
                    68:e2:f3:d7:dd:9e:a6:7d:d3:12:aa:f5:62:91:d9:
                    8d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                Server Authentication, Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:93:49:C1:B8:AB:BF:0F:7D:44:69:5A:C3:2A:7A:3C:79:19:BE:6A:B7
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/sleep
{{< /text >}}

注：如果您没有得到任何输出，这可能意味着 `ds/ztunnel` 已选择了一个未管理任何证书的节点。
您可以指定一个特定的 ztunnel Pod（例如 `istioctl pc secret ztunnel-tcn4m -n istio-system`）来管理其中一个样例应用 Pod。

## 加固应用访问安全{#secure-application-access}

当您将应用添加到 Ambient Mesh 后，就可以使用 L4 鉴权策略加固应用访问的安全。
这允许您根据客户端工作负载身份来控制对某个服务的访问流量，但这不是 `GET` 和 `POST` 等 HTTP 方法的 L7 级别的控制。

### L4 鉴权策略{#l4-authorization-policies}

显式允许 `sleep` 服务账户和 `istio-ingressgateway` 服务账户来调用 `productpage` 服务：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
EOF
{{< /text >}}

确认上述鉴权策略正在发挥作用：

{{< text bash >}}
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ # this should fail with an empty reply
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

### 7 层鉴权策略{#l7-authorization-policies}

使用 Kubernetes Gateway API，您可以为使用 `bookinfo-productpage` 服务账户的 `productpage` 服务部署一个 waypoint proxy。
任何流向 `productpage` 服务的流量都将由 7 层 (L7) 代理进行调解、实施和观测。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
 name: productpage
 annotations:
   istio.io/service-account: bookinfo-productpage
spec:
 gatewayClassName: istio-mesh
EOF
{{< /text >}}

请注意对于 waypoint proxy，`gatewayClassName` 必须是 `istio-mesh`。

查看 `productpage` waypoint proxy 状态；您应看到网关资源的详情以及状态为 `Ready`：

{{< text bash >}}
$ kubectl get gateway productpage -o yaml
...
status:
  conditions:
  - lastTransitionTime: "2022-09-06T20:24:41Z"
    message: Deployed waypoint proxy to "default" namespace for "bookinfo-productpage"
      service account
    observedGeneration: 1
    reason: Ready
    status: "True"
    type: Ready
{{< /text >}}

更新 `AuthorizationPolicy` 以显式允许 `sleep` 服务账户和 `istio-ingressgateway` 服务账户 `GET` 对应的 `productpage` 服务，但不执行其他操作：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

确认上述鉴权策略正在发挥作用：

{{< text bash >}}
$ # this should fail with an RBAC error because it is not a GET operation
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ -X DELETE | head -n1
$ # this should fail with an RBAC error because the identity is not allowed
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/  | head -n1
$ # this should continue to work
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

{{< image width="75%"
    link="app-in-ambient-l7.png"
    caption="Inbound requests from sleep to `productpage` and from `productpage` to reviews with secure overlay and L7 processing layers"
    >}}

随着 `productpage` waypoint proxy 被部署，对于到 `productpage` 服务的所有请求，您也将自动获取 L7 指标：

{{< text bash >}}
$ kubectl exec deploy/bookinfo-productpage-waypoint-proxy -- curl -s http://localhost:15020/stats/prometheus | grep istio_requests_total
{{< /text >}}

您将看到该指标 `response_code=403` 以及一些指标 `response_code=200`，具体如下：

{{< text plain >}}
istio_requests_total{
  response_code="403",
  source_workload="notsleep",
  source_workload_namespace="default",
  source_principal="spiffe://cluster.local/ns/default/sa/notsleep",
  destination_workload="productpage-v1",
  destination_principal="spiffe://cluster.local/ns/default/sa/bookinfo-productpage",
  connection_security_policy="mutual_tls",
  ...
}
{{< /text >}}

当源工作负载（`notsleep`）通过双向 TLS 连接调用目标工作负载（`productpage-v1`）以及源和目标主体时，该指标显示两个 `403` 响应。

## 控制流量{#control-traffic}

使用 `bookinfo-review` 服务账户为 `review` 服务部署 waypoint proxy，因此流向 `review` 服务的所有流量都将由 waypoint proxy 进行调解。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
 name: reviews
 annotations:
   istio.io/service-account: bookinfo-reviews
spec:
 gatewayClassName: istio-mesh
EOF
{{< /text >}}

应用 `reviews` 虚拟服务以控制 90% 流量到 reviews v1，而 10% 流量到 reviews v2。

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-reviews.yaml
{{< /text >}}

确认 100 个请求中大致有 10% 流量流向 `reviews-v2`：

{{< text bash >}}
$ kubectl exec -it deploy/sleep -- sh -c 'for i in $(seq 1 100); do curl -s http://istio-ingressgateway.istio-system/productpage | grep reviews-v.-; done'
{{< /text >}}

## 结尾语{#wrapping-up}

现有的 Istio 资源继续工作，与您是选择使用 Sidecar 还是 Ambient 数据平面模式无关。

观看一个短视频，看看 Lin Sun 如何在 5 分钟内完成 Istio Ambient Mesh 演示：

<iframe width="560" height="315" src="https://www.youtube.com/embed/wTGF4S4ZmJ0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## 下一步{#what-is-next}

我们很高兴看到全新的 Istio Ambient 数据平面及其简单的 "ambient" 架构。
现在将您的应用接入具有 Ambient 模式的服务网格就像标记命名空间一样简单。
您的应用立即就能享受到 mTLS 与网格流量的身份加密和 L4 可观测性等好处。
如果需要在 Ambient Mesh 中的应用之间控制访问、路由、增强弹性或获得 L7 指标，可以根据需要将 waypoint proxy 应用到您的应用。
我们推崇按需消费，因为这不但能节省资源，还可以通过不断更新许多代理来节省运营成本！
诚挚邀请您试用全新的 Istio Ambient 数据平面架构，体验极简操作。
期待您在 Istio 社区[提出反馈](http://slack.istio.io)！
