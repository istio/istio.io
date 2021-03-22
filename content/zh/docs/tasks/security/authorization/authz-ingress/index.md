---
title: 入口网关授权
description: 如何在入口网关上设置访问控制。
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
aliases:
- /zh/docs/tasks/security/authz-ingress/
owner: istio/wg-security-maintainers
test: yes
---

此任务演示如何使用授权策略在 Istio 入口网关上实施基于IP的访问控制。

## 开始之前 {#before-you-begin}

开始此任务之前，请确认执行以下操作：

* 阅读了[授权概念](/zh/docs/concepts/security/#authorization)。

* 通过 [Istio 安装指南](/zh/docs/setup/install/istioctl/) 安装完成 Istio。

* 在命名空间（例如 `foo`）中部署工作负载 `httpbin`，并使用以下命令通过 Istio 入口网关将其公开：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin-gateway.yaml@) -n foo
    {{< /text >}}

* 为入口网关启用 Envoy 的 RBAC 调试：

    {{< text bash >}}
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
    {{< /text >}}

*  根据[确定入口 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)说明
   定义 `INGRESS_HOST` 和 `INGRESS_PORT` 环境变量。

* 使用以下命令验证 `httpbin` 工作负载和入口网关是否按预期工作：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果你没有看到预期的输出，请在几秒钟后重试。
缓存和传播开销可能会导致延迟。
{{< /warning >}}

## 将流量导入 Kubernetes 和 Istio {#getting-traffic-into-Kubernetes-and-Istio}

所有让流量进入 Kubernetes 的方法都需要在所有工作节点上打开一个端口。实现这一点的主要特性是 `NodePort` 服务和 `LoadBalancer` 服务。
甚至 Kubernetes 的 `Ingress` 资源也必须由一个 Ingress controller 来支持，该 Ingress controller 将创建一个 `NodePort` 或一个 `LoadBalancer` 服务。

* `NodePort` 只需在每个工作节点上打开一个范围在 30000-32767 的端口，并使用标签选择器来标识要将流量发送到哪些 Pod。你必须在工作节点前手动创建负载均衡器，或者使用循环DNS。

* `LoadBalancer` 与 `NodePort` 类似，不同的是它还创建了一个特定于环境的外部负载均衡器来处理分发到工作节点的流量。
  例如，在AWS EKS中，`LoadBalancer` 服务将创建一个以工作节点为目标的经典ELB。如果你的 Kubernetes 环境没有 `LoadBalancer` 实现，那么它的行为就会像 `NodePort`。
  Istio 入口网关创建 `LoadBalancer` 服务。

如果处理来自 `NodePort` 或 `LoadBalancer` 的流量的 Pod 没有在接收流量的工作节点上运行呢？Kubernetes 有自己的内部代理 Kube Proxy，它接收数据包并将它们转发到正确的节点。

## 原始客户端的源 IP 地址 {#source-IP-address-of-the-original-client}

如果数据包通过外部代理负载均衡器或 Kube Proxy，则客户端的原始源IP地址将会丢失。以下是一些出于日志记录或安全目的而保留原始客户端 IP 的策略。

{{< tabset category-name="lb" >}}

{{< tab name="TCP/UDP Proxy Load Balancer" category-value="proxy" >}}

{{< warning >}}
关键 [bug](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0) 已在 Envoy 中报告：对于非 HTTP 连接，代理协议下游地址还原不正确。

请不要将 `remoteIpBlocks` 字段和 `remote_ip` 属性用于非 HTTP 连接上的代理协议，直到发布了具有适当修复的较新版本的 Istio。

注意：Istio 不支持代理协议，它只能通过 `EnvoyFilter` API 启用，使用风险自负。
{{< /warning >}}

如果您使用的是 TCP/UDP 代理外部负载均衡器（AWS Classic ELB），那么它可以使用 [代理协议](https://www.haproxy.com/blog/haproxy/proxy-protocol/) 在包数据中嵌入原始的客户端 IP 地址。
外部负载均衡器和 Istio 入口网关都必须支持代理协议才能工作。在 Istio 中，可以使用 `EnvoyFilter` 启用它，如下所示：

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

下面是一个 `IstioOperator` 示例，演示如何在 AWS EKS 上配置 Istio 入口网关以支持代理协议：

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

If you are using a TCP/UDP network load balancer that preserves the client IP address (AWS Network Load Balancer, GCP External Network Load Balancer, Azure Load Balancer) or you are using Round-Robin DNS, then you can also preserve the client IP inside Kubernetes by bypassing kube-proxy and preventing it from sending traffic to other nodes.  **However, you must run an ingress gateway pod on every node.** If you don't, then any node that receives traffic and doesn't have an ingress gateway will drop the traffic. See [Source IP for Services with `Type=NodePort`](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport)
for more information. Update the ingress gateway to set `externalTrafficPolicy: Local` to preserve the
original client source IP on the ingress gateway using the following command:

{{< text bash >}}
$ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< tab name="HTTP/HTTPS Load Balancer" category-value="http" >}}

If you are using an HTTP/HTTPS external load balancer (AWS ALB, GCP ), it can put the original client IP address in the X-Forwarded-For header.  Istio can extract the client IP address from this header with some configuration.  See [Configuring Gateway Network Topology](/zh/docs/ops/configuration/traffic-management/network-topologies/). Quick example if using a single load balancer in front of Kubernetes:

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

For reference, here are the types of load balancers created by Istio with a `LoadBalancer` service on popular managed Kubernetes environments:

|Cloud Provider | Load Balancer Name            | Load Balancer Type
----------------|-------------------------------|-------------------
|AWS EKS        | Classic Elastic Load Balancer | TCP Proxy
|GCP GKE        | TCP/UDP Network Load Balancer | Network
|Azure AKS      | Azure Load Balancer           | Network
|DO DOKS        | Load Balancer                 | Network

{{< tip >}}
You can instruct AWS EKS to create a Network Load Balancer when you install Istio by using a `serviceAnnotation` like below:

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

## IP-based allow list and deny list

**When to use `ipBlocks` vs. `remoteIpBlocks`:** If you are using the X-Forwarded-For HTTP header or the Proxy Protocol to determine the original client IP address, then you should use `remoteIpBlocks` in your `AuthorizationPolicy`. If you are using `externalTrafficPolicy: Local`, then you should use `ipBlocks` in your `AuthorizationPolicy`.

|Load Balancer Type |Source of Client IP   | `ipBlocks` vs. `remoteIpBlocks`
--------------------|----------------------|---------------------------
| TCP Proxy         | Proxy Protocol       | `remoteIpBlocks`
| Network           | packet source address| `ipBlocks`
| HTTP/HTTPS        | X-Forwarded-For      | `remoteIpBlocks`

* The following command creates the authorization policy, `ingress-policy`, for
the Istio ingress gateway. The following policy sets the `action` field to `ALLOW` to
allow the IP addresses specified in the `ipBlocks` to access the ingress gateway.
IP addresses not in the list will be denied. The `ipBlocks` supports both single IP address and CIDR notation.

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

Create the AuthorizationPolicy:

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

* Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* Update the `ingress-policy` to include your client IP address:

{{< tabset category-name="source" >}}

{{< tab name="ipBlocks" category-value="ipBlocks" >}}

Find your original client IP address if you don't know it and assign it to a variable:

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

Find your original client IP address if you don't know it and assign it to a variable:

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

Create the AuthorizationPolicy:

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

* Verify that a request to the ingress gateway is allowed:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* Update the `ingress-policy` authorization policy to set
the `action` key to `DENY` so that the IP addresses specified in the `ipBlocks` are
not allowed to access the ingress gateway:

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

* Verify that a request to the ingress gateway is denied:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* You could use an online proxy service to access the ingress gateway using a
different client IP to verify the request is allowed.

* If you are not getting the responses you expect, view the ingress gateway logs which should show RBAC debugging information:

    {{< text bash >}}
    $ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
    {{< /text >}}

## Clean up

* Remove the namespace `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* Remove the authorization policy:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy ingress-policy -n istio-system
    {{< /text >}}
