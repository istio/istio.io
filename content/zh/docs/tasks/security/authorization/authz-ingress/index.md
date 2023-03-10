---
title: 入口网关
description: 展示如何在入口网关上设置访问控制。
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
owner: istio/wg-security-maintainers
test: yes
---

此任务向您展示如何使用授权策略在 Istio 入口网关上实施基于 IP 的访问控制。

## 开始之前 {#before-you-begin}

在开始此任务之前，请执行以下操作：

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 使用 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 在命名空间中部署工作负载 `httpbin`，例如 `foo`，并使用以下命令通过 Istio 入口网关公开它：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin-gateway.yaml@) -n foo
    {{< /text >}}

* 在 Envoy 中为入口网关打开 RBAC 调试：

    {{< text bash >}}
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
    {{< /text >}}

*  遵从[确定入口 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的指示说明来定义 `INGRESS_HOST` 和 `INGRESS_PORT` 环境变量。

* 使用以下命令验证 `httpbin` 工作负载和入口网关正在按预期工作：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您没有看到预期的输出，请在几秒钟后重试。缓存和传播开销可能会导致延迟。
{{< /warning >}}

## 将流量引入 Kubernetes 和 Istio {#getting-traffic-into-Kubernetes-and-Istio}

所有将流量引入 Kubernetes 的方法都涉及在所有工作节点上打开一个端口，实现这一点的主要功能是 `NodePort` 服务和 `LoadBalancer` 服务，甚至 Kubernetes 的 `Ingress` 资源也必须由 Ingress 控制器支持，该控制器将创建 `NodePort` 或 `LoadBalancer` 服务。

* `NodePort` 只是在每个工作节点上打开一个 30000-32767 范围内的端口，并使用标签选择器来识别将流量发送到哪些 Pod。您必须在工作节点前面手动创建某种负载均衡器或使用轮询模式的 DNS。

* `LoadBalancer` 就像 `NodePort` 一样，除了它还创建一个特定于环境的外部负载均衡器来处理将流量分配到工作节点。例如，在 AWS EKS 中，`LoadBalancer` 服务将创建一个以您的工作程序节点为目标的经典 ELB。如果您的 Kubernetes 环境没有 `LoadBalancer` 实现，那么它的行为就像 `NodePort`。Istio 入口网关创建一个 `LoadBalancer`服务。

如果处理来自 `NodePort` 或 `LoadBalancer` 的流量的 Pod 没有在接收流量的工作节点上运行怎么办？Kubernetes 有自己的内部代理，称为 kube-proxy，用于接收数据包并将数据包转发到正确的节点。

## 原始客户端的源 IP 地址 {#source-ip-address-of-the-original-client}

如果数据包通过外部代理负载均衡器和/或 kube-proxy，则客户端的原始源 IP 地址会丢失。以下是一些保留原始客户端 IP 以用于日志记录或安全目的的策略。

{{< tabset category-name="lb" >}}

{{< tab name="TCP/UDP 代理负载均衡器" category-value="proxy" >}}

如果您使用的是 TCP/UDP 代理外部负载均衡器（AWS Classic ELB），它可以使用[代理协议](https://www.haproxy.com/blog/haproxy/proxy-protocol/)嵌入原始数据包数据中的客户端 IP 地址。外部负载均衡器和 Istio 入口网关都必须支持代理协议才能工作。在 Istio 中，您可以使用 `EnvoyFilter` 启用它，如下所示：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio: ingressgateway
{{< /text >}}

以下是 `IstioOperator` 示例，展示了如何在 AWS EKS 上配置 Istio 入口网关以支持代理协议：

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
          service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5"
          service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
          service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: elb-logs
          service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: k8sELBIngressGW
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
        affinity:
          podAntiAffinity:
            preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchLabels:
                    istio: ingressgateway
                topologyKey: failure-domain.beta.kubernetes.io/zone
              weight: 1
      name: istio-ingressgateway
{{< /text >}}

{{< /tab >}}

{{< tab name="Network Load Balancer" category-value="network" >}}

如果您使用的是保留客户端 IP 地址的 TCP/UDP 网络负载均衡器（AWS 网络负载均衡器、GCP 外部网络负载均衡器、Azure 负载均衡器），或者您使用的是轮询模式的 DNS，那么您还可以保留客户端 IP 在 Kubernetes 内部绕过 kube-proxy 并阻止它向其他节点发送流量。**但是，您必须在每个节点上运行一个入口网关 Pod。**
如果不这样做，那么任何接收流量但没有入口网关的节点都会丢弃流量。有关更多信息，请参阅[使用 `Type=NodePort` 的服务的源 IP](https://kubernetes.io/zh-cn/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)。
使用以下命令更新入口网关以设置 `externalTrafficPolicy: Local` 以保留入口网关上的原始客户端源 IP：

{{< text bash >}}
$ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< tab name="HTTP/HTTPS Load Balancer" category-value="http" >}}

如果您使用的是 HTTP/HTTPS 外部负载均衡器（AWS ALB、GCP），它可以将原始客户端 IP 地址放在 X-Forwarded-For 标头中。Istio 可以通过一些配置从此标头中提取客户端 IP 地址。请参阅[配置网关网络拓扑](/zh/docs/ops/configuration/traffic-management/network-topologies/)。如果在 Kubernetes 前面使用单个负载均衡器，请参考以下快速示例：

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

{{< /tab >}}

{{< /tabset >}}

作为参考，以下是 Istio 在流行的托管 Kubernetes 环境中使用 `LoadBalancer` 服务创建的负载均衡器类型：

|云提供商 | 负载均衡器名称            | 负载均衡器类型
----------------|-------------------------------|-------------------
|AWS EKS        | Classic Elastic Load Balancer | TCP Proxy
|GCP GKE        | TCP/UDP Network Load Balancer | Network
|Azure AKS      | Azure Load Balancer           | Network
|DO DOKS        | Load Balancer                 | Network

{{< tip >}}
您可以在安装 Istio 时使用如下所示的 `serviceAnnotation` 指示 AWS EKS 创建网络负载均衡器：

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

{{< /tip >}}

## 基于 IP 的允许列表和拒绝列表{#ip-based-allow-list-and-deny-list}

**何时使用 `ipBlocks` 与 `remoteIpBlocks`：** 如果您使用 X-Forwarded-For HTTP 标头或代理协议来确定原始客户端 IP 地址，那么您应该在您的 `AuthorizationPolicy` 中使用 `remoteIpBlocks`。
如果您使用的是 `externalTrafficPolicy: Local`，那么您应该在 `AuthorizationPolicy` 中使用 `ipBlocks`。

| 负载均衡器类型 | 客户端源 IP   | `ipBlocks` 与 `remoteIpBlocks`
--------------------|----------------------|---------------------------
| TCP Proxy         | Proxy Protocol       | `remoteIpBlocks`
| Network           | packet source address| `ipBlocks`
| HTTP/HTTPS        | X-Forwarded-For      | `remoteIpBlocks`

* 以下命令为 Istio 入口网关创建授权策略 `ingress-policy`。以下策略将 `action` 字段设置为 `ALLOW`，以允 `ipBlocks` 中指定的 IP 地址访问入口网关。不在列表中的 IP 地址将被拒绝。`ipBlocks` 支持单个 IP 地址和 CIDR 表示法。

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

创建授权策略：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tabset >}}

* 验证对入口网关的请求是否被拒绝：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* 更新 `ingress-policy` 以包含您的客户端 IP 地址：

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

如果您不知道原始客户端 IP 地址并将其分配给变量，请查找它：

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

如果您不知道原始客户端 IP 地址并将其分配给变量，请查找它：

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

创建授权策略：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tabset >}}

* 验证是否允许对入口网关的请求：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* 更新 `ingress-policy` 授权策略，将 `action` 键设置为 `DENY`，从而不允许 `ipBlocks` 中指定的 IP 地址访问入口网关：

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tab >}}

{{< tab name="remoteIpBlocks" category-value="remoteIpBlocks" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
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

{{< /tabset >}}

* 验证对入口网关的请求是否被拒绝：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* 您可以使用在线代理服务使用不同的客户端 IP 访问入口网关，以验证请求是否被允许。

* 如果您没有得到预期的响应，请查看应显示 RBAC 调试信息的入口网关日志：

    {{< text bash >}}
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
    {{< /text >}}

## 清理 {#clean-up}

* 移除命名空间 `foo`：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* 移除授权策略：

    {{< text bash >}}
    $ kubectl delete authorizationpolicy ingress-policy -n istio-system
    {{< /text >}}
