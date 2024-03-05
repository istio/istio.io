---
title: Ingress 网关
description: 展示如何在 Ingress 网关上设置访问控制。
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
owner: istio/wg-security-maintainers
test: yes
---

此任务向您展示如何使用授权策略在 Istio Ingress 网关上实施基于 IP 的访问控制。

{{< boilerplate gateway-api-support >}}

## 开始之前 {#before-you-begin}

在开始此任务之前，请执行以下操作：

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 使用 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 在启用 Sidecar 注入的命名空间 `foo` 中部署工作负载 `httpbin`：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    {{< /text >}}

* 通过 Ingress 网关暴露 `httpbin`：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

配置网关:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

在 Envoy 中为 Ingress 网关打开 RBAC 调试：

{{< text bash >}}
$ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
{{< /text >}}

遵从[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的指示说明来定义
`INGRESS_HOST` 和 `INGRESS_PORT` 环境变量。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

创建网关:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

针对 Ingress 网关在 Envoy 中启用 RBAC 调试：

{{< text bash >}}
$ kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n foo --level rbac:debug; done
{{< /text >}}

设置环境变量 `INGRESS_PORT` 和 `INGRESS_HOST`：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 使用以下命令验证 `httpbin` 工作负载和 Ingress 网关是否正常工作:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< warning >}}
    如果没有看到预期的输出，请在几秒钟后重试。
    缓存和传播开销可能会导致延迟。
    {{< /warning >}}

## 将流量引入 Kubernetes 和 Istio {#getting-traffic-into-Kubernetes-and-Istio}

所有将流量引入 Kubernetes 的方法都涉及在所有工作节点上打开一个端口，
实现这一点的主要功能是 `NodePort` 服务和 `LoadBalancer` 服务，甚至
Kubernetes 的 `Ingress` 资源也必须由 Ingress 控制器支持，该控制器将创建
`NodePort` 或 `LoadBalancer` 服务。

* `NodePort` 只是在每个工作节点上打开一个 30000-32767 范围内的端口，
  并使用标签选择器来识别将流量发送到哪些 Pod。
  您必须在工作节点前面手动创建某种负载均衡器或使用轮询模式的 DNS。

* `LoadBalancer` 就像 `NodePort` 一样，
  除了它还创建一个特定于环境的外部负载均衡器来处理将流量分配到工作节点。
  例如，在 AWS EKS 中，`LoadBalancer` 服务将创建一个以您的工作程序节点为目标的经典
  ELB。如果您的 Kubernetes 环境没有 `LoadBalancer` 实现，那么它的行为就像
  `NodePort`。Istio Ingress 网关创建一个 `LoadBalancer`服务。

如果处理来自 `NodePort` 或 `LoadBalancer` 的流量的 Pod
没有在接收流量的工作节点上运行怎么办？Kubernetes 有自己的内部代理，
称为 kube-proxy，用于接收数据包并将数据包转发到正确的节点。

## 原始客户端的源 IP 地址 {#source-ip-address-of-the-original-client}

如果数据包通过外部代理负载均衡器和/或 kube-proxy，则客户端的原始源 IP 地址将丢失。
以下小节介绍了为不同类型的负载均衡保留原始客户端 IP 以用于日志记录或安全目的的一些策略：

1. [TCP/UDP Proxy Load Balancer](#tcp-proxy)
1. [Network Load Balancer](#network)
1. [HTTP/HTTPS Load Balancer](#http-https)

以下是 Istio 在流行的托管 Kubernetes 环境下使用 `LoadBalancer` 服务创建的负载均衡器类型，以供参考：

|云提供商 | 负载均衡器名称           | 负载均衡器类型
----------------|-------------------------------|-------------------
|AWS EKS        | Classic Elastic Load Balancer | TCP Proxy
|GCP GKE        | TCP/UDP Network Load Balancer | Network
|Azure AKS      | Azure Load Balancer           | Network
|IBM IKS/ROKS   | Network Load Balancer         | Network
|DO DOKS        | Load Balancer                 | Network

{{< tip >}}
您可以指示 AWS EKS 在网关服务上创建带有注解的 Network Load Balancer：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
  components:
    ingressGateways:
    - enabled: true
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  gatewayClassName: istio
  ...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< /tip >}}

### TCP/UDP 代理负载均衡器 {#tcp-proxy}

如果您使用的是 TCP/UDP 代理外部负载均衡器 (AWS Classic ELB)，
它可以使用 [PROXY 协议](https://www.haproxy.com/blog/haproxy/proxy-protocol/)
将原始客户端 IP 地址嵌入到分组数据中。外部负载均衡器和 Istio Ingress 网关都必须支持 PROXY 协议才能工作。

以下是一个样例配置，显示了如何在支持 PROXY 协议的 AWS EKS 上部署 Ingress Gateway：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
    defaultConfig:
      gatewayTopology:
        proxyProtocol: {}
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
        ...
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
    proxy.istio.io/config: '{"gatewayTopology" : { "proxyProtocol": {} }}'
spec:
  gatewayClassName: istio
  ...
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: httpbin-gateway
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: httpbin-gateway-istio
  minReplicas: 5
  maxReplicas: 10
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 网络负载均衡器 {#network}

如果您正在使用保留客户端 IP 地址的 TCP/UDP 网络负载均衡器 (AWS 网络负载均衡器、
GCP 外部网络负载均衡器、Azure 负载均衡器)，或者您正在使用轮询 DNS，则您可以通过绕过
kube-proxy 并阻止其将流量发送到其他节点，使用 `externalTrafficPolicy: Local`
设置来同时保留 Kubernetes 内部的客户端 IP。

{{< warning >}}
对于生产部署，如果您开启了 `externalTrafficPolicy: Local`，
强烈建议 **将一个 Ingress 网关实例部署到多个节点**。
否则，这将导致 **只有** 具有活动 Ingress 网关实例的节点能够接受并将传入的 NLB 流量分发到集群的其余部分，
从而造成潜在的 Ingress 流量瓶颈和降低的内部负载均衡能力，
甚至在具有 Ingress 网关实例的节点子集关闭时完全丧失到集群的 Ingress 流量。
有关更多信息，请参阅[服务源 IP `Type=NodePort`](https://kubernetes.io/zh-cn/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)。
{{< /warning >}}

使用以下命令更新 Ingress 网关以设置 `externalTrafficPolicy: Local` 以保留 Ingress 网关上的原始客户端源 IP：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl patch svc httpbin-gateway-istio -n foo -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### HTTP/HTTPS 负载均衡 {#http-https}

如果您使用的是 HTTP/HTTPS 外部负载均衡器 (AWS、ALB、GCP)，它可以将原始客户端 IP 地址放在
X-Forwarded-For 报头中。通过一些配置，Istio 可以从该报头中提取客户端 IP 地址。
请参阅[配置网关网络拓扑](/zh/docs/ops/configuration/traffic-management/network-topologies/)。
在 Kubernetes 面前使用单个负载均衡的快速示例：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: 1
{{< /text >}}

## 基于 IP 的允许列表和拒绝列表 {#ip-based-allow-list-and-deny-list}

**何时使用 `ipBlocks` 与 `remoteIpBlocks`:** 如果您使用 X-Forwarded-For HTTP 头部
或 PROXY 协议来确定原始客户端 IP 地址，则应在 `AuthorizationPolicy` 中使用 `remoteIpBlocks`。
如果您使用的是 `externalTrafficPolicy: Local`，那么您的 `AuthorizationPolicy` 中应该使用
`ipBlocks`。

| 负载均衡器类型 | 客户端源 IP   | `ipBlocks` 与 `remoteIpBlocks`
--------------------|----------------------|---------------------------
| TCP Proxy         | PROXY Protocol       | `remoteIpBlocks`
| Network           | packet source address| `ipBlocks`
| HTTP/HTTPS        | X-Forwarded-For      | `remoteIpBlocks`

* 以下命令为创建授权策略`ingress-policy` Istio Ingress 网关。
  以下策略将 `action` 字段设置为 `ALLOW` 以允许 `ipBlocks` 中指定的 IP 地址访问 Ingress 网关。
  不在列表中的 IP 地址将被拒绝。`ipBlocks` 支持单 IP 地址和 CIDR 表示法。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 验证对 Ingress 网关的请求是否被拒绝：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* 将原始客户端 IP 地址分配给环境变量。如果您不知道，您可以使用以下命令在 Envoy 日志中找到它：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 更新 `ingress-policy` 以包含您的客户端 IP 地址:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 验证是否允许对 Ingress 网关的请求：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* 更新 `ingress-policy` 授权策略，将 `action` 键设置为 `DENY`，
  禁止 `ipBlocks` 中指定的 IP 地址访问 Ingress 网关：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        ipBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        ipBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 验证对 Ingress 网关的请求是否被拒绝：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* 您可以使用在线代理服务来访问使用不同客户端 IP 的 Ingress 网关，以验证请求是否被允许。

* 如果您没有得到预期的响应，请查看应显示 RBAC 调试信息的 Ingress 网关日志：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo; done
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 清理 {#clean-up}

* 删除授权策略：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete authorizationpolicy ingress-policy -n istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete authorizationpolicy ingress-policy -n foo
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 移除命令空间 `foo`：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}
