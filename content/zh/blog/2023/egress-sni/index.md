---
title: "将出口流量路由至通配符目的地"
description: "一种通用的设置出口网关的方法，可以动态地将流量路由至受限制的目标远程主机集合（包括通配符域名）。"
publishdate: 2023-12-01
attribution: "Gergő Huszty (IBM); Translated by Wilson Wu (DaoCloud)"
keywords: [traffic-management,gateway,mesh,mtls,egress,remote]
---

如果您使用 Istio 处理应用程序发起的流向网格外部目标的流量，您可能熟悉出口网关的概念。
出口网关可用于监控和转发来自网格内应用程序的流量至网格外部的位置。
如果您的系统在受限环境中运行并且您想控制从您的网格访问公共互联网的内容，那么这是一个有用的功能。

在[官方 Istio 文档](https://archive.istio.io/v1.13/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)中，
配置出口网关以处理任意通配符域名的用例一直包含至 1.13 版本，
但随后因为记录的解决方案未得到官方支持或推荐，
并可能在未来的 Istio 版本中出现问题而被移除。尽管如此，
旧的解决方案仍然可以在 1.20 之前的 Istio 版本中使用。
然而，在 Istio 1.20 中放弃了一些该方法所需的 Envoy 的功能。

本文试图描述我们如何解决这个问题，并通过使用与 Istio 版本独立的组件和 Envoy
功能的类似方法来填补空白，而无需单独的 Nginx SNI 代理。
我们的方法允许旧解决方案的用户在其系统面临 Istio 1.20 中的重大变化之前无缝迁移配置。

## 需要解决的问题 {#problem-to-solve}

当前记录的出口网关用例依赖于流量的目标（主机名）是在 `VirtualService` 中静态配置的，
并告知出口网关 Pod 中的 Envoy 在哪里进行 TCP 代理匹配的出站连接。
您可以使用多个（甚至是通配符）DNS 名称来匹配路由条件，
但您无法将流量路由到应用程序请求中指定的确切位置。例如，您可以匹配目标 `*.wikipedia.org` 的流量，
但随后需要将流量转发到单个最终目标，例如 `en.wikipedia.org`。
如果存在另一个服务，例如 `anyservice.wikipedia.org`，
它不是由与 `en.wikipedia.org` 相同的服务器托管的，则到该主机的流量将会失败。
这是因为，即使 HTTP 负载的 TLS 握手中的目标主机名包含 `anyservice.wikipedia.org`，
`en.wikipedia.org` 服务器也无法响应该请求。

此问题的高级解决方案是在每个新的网关连接中检查应用程序 TLS
握手中的原始服务器名称（SNI扩展）（该信息以明文发送，因此不需要TLS终止或其他中间人操作），
并将其用作动态 TCP 代理离开网关的流量的目标。

当通过出口网关进行出口流量限制时，我们需要锁定出口网关，以便它们只能由网格内的客户端使用。
这是通过在应用程序 Sidecar 和网关之间强制执行 `ISTIO_MUTUAL`（mTLS 对等身份验证）来实现的。
这意味着应用程序 L7 负载上将有两层 TLS。一种是应用程序发起的端到端 TLS 会话，
由最终远程目标终止，另一种是 Istio mTLS 会话。

另一件需要记住的事情是，为了减轻任何潜在的应用程序 Pod 异常，
应用程序 Sidecar 和网关都应该执行主机名列表检查。
这样，任何异常的应用程序 Pod 仍然只能访问被允许的目标，仅此而已。

## 使用低等级 Envoy 编程进行解救 {#low-level-envoy-programming-to-the-rescue}

在最近的 Envoy 版本中包括动态 TCP 转发代理解决方案，
该解决方案在每个连接的基础上使用 SNI 标头来确定应用程序请求的目标。
虽然 Istio `VirtualService` 无法配置这样的目标，但我们可以使用
`EnvoyFilter` 来更改 Istio 生成的路由指令，以便使用 SNI 标头来确定目标。

为了使这一切正常工作，我们首先配置一个自定义出口网关来侦听出站流量。
使用 `DestinationRule` 和 `VirtualService`，我们指示应用程序 Sidecar
使用 Istio mTLS 将流量（针对选定的主机名列表）路由到该网关。
在网关 Pod 端，我们使用上面提到的 `EnvoyFilter` 构建 SNI 转发器，
引入内部 Envoy 侦听器和集群以使其全部正常工作。
最后，我们将网关实现的 TCP 代理的内部目标补丁应用到内部 SNI 转发器。

端到端的请求流程如下图所示：

{{< image width="90%" link="./egress-sni-flow.svg" alt="具有任意域名的出口 SNI 路由" title="有任意域名的出口 SNI 路由" caption="有任意域名的出口 SNI 路由" >}}

此图展示了通过 SNI 作为路由转发器向 `en.wikipedia.org` 发起出口 HTTPS 请求。

* 应用程序容器

    应用程序向最终目的地发起 HTTP/TLS 连接。将目标主机名放入 SNI 标头中。
    此 TLS 会话不会在网格内部被解密。仅 SNI 标头被检查（因为它是明文形式）。

* Sidecar 代理

    Sidecar 拦截来自应用程序发起的 TLS 会话的 SNI 标头中匹配主机名的流量。
    基于 VirtualService，流量被路由到出口网关，同时将原始流量包装到 Istio mTLS 中。
    外部 TLS 会话具有包含在 SNI 标头中的网关 Service 地址。

* 网格侦听器

    在网关中创建一个专用侦听器，用于对 Istio mTLS 流量进行双向身份验证。
    外部 Istio mTLS 终止后，它会通过 TCP 代理无条件地将内部 TLS 流量发送到同一网关中的其他（内部）侦听器。

* SNI 转发器

    具有 SNI 转发器的另一个侦听器对原始 TLS 会话执行新的 TLS 标头检查。
    如果内部 SNI 主机名与允许的域名（包括通配符）匹配，则 TCP 会将流量代理到目的地，
    并从每个连接的标头中读取。该侦听器位于 Envoy 内部（允许其重新启动流量处理以查看内部 SNI 值），
    因此任何 Pod（网格内部或外部）都无法直接连接到它。该侦听器是 100% 通过 EnvoyFilter 手动配置的。

## 部署示例 {#deploy-the-sample}

为了部署示例配置，首先创建 `istio-egress` 命名空间，
然后使用以下 YAML 部署出口网关和一些关联的 RBAC 及其 `Service`。
本示例中我们使用网关注入方式来创建网关。根据您的安装方法，
您可能希望以不同的方式部署它（例如，使用 `IstioOperator` CR 或使用 Helm）。

{{< text yaml >}}
# 新的 k8s 集群服务将 egressgateway 放入服务注册表中，
# 以便应用程序 Sidecar 可以在网格内将流量路由到它。
apiVersion: v1
kind: Service
metadata:
  name: egressgateway
  namespace: istio-egress
spec:
  type: ClusterIP
  selector:
    istio: egressgateway
  ports:
  - port: 443
    name: tls-egress
    targetPort: 8443

---
# 使用注入方式的网关 Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-egressgateway
  namespace: istio-egress
spec:
  selector:
    matchLabels:
      istio: egressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: egressgateway
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337

---
# 设置 Role 以允许读取 TLS 凭据
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups:
  - security.openshift.io
  resourceNames:
  - anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-egressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

验证网关 Pod 已启动并在 `istio-egress` 命名空间中运行，
然后应用以下 YAML 来配置网关路由：

{{< text yaml >}}
# 定义一个新的侦听器，对入站连接强制执行 Istio mTLS。
# 这里是 Sidecar 路由应用程序流量的地方，并封装到 Istio mTLS 中。
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 8443
      name: tls-egress
      protocol: TLS
    hosts:
      - "*"
    tls:
      mode: ISTIO_MUTUAL

---
# 如果 SNI 目标主机名匹配，
# VirtualService 将指示网格中的 Sidecar 将传出流量路由到出口网关服务
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-wildcard-through-egress-gateway
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  gateways:
  - mesh
  - egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
        - "*.wikipedia.org"
    route:
    - destination:
        host: egressgateway.istio-egress.svc.cluster.local
        subset: wildcard
# 虚拟路由指令。如果省略，则不会有任何引用指向网关定义，
# 并且 istiod 将优化整个新侦听器。
  tcp:
  - match:
    - gateways:
      - egressgateway
      port: 8443
    route:
    - destination:
        host: "dummy.local"
      weight: 100

---
# 指示 Sidecar 在将流量发送到出口网关时使用 Istio mTLS
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  host: egressgateway.istio-egress.svc.cluster.local
  subsets:
  - name: wildcard
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL

---
# 将远程目标放入服务注册表中
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wildcard
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  ports:
  - number: 443
    name: tls
    protocol: TLS

---
# 网关的访问日志记录
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy

---
# 最后，SNI 转发器的配置、它是内部侦听器以及原始网关侦听器的补丁，
# 用于将所有内容路由到 SNI 转发器。
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: sni-magic
  namespace: istio-system
spec:
  configPatches:
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_cluster
        load_assignment:
          cluster_name: sni_cluster
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  envoy_internal_address:
                    server_listener_name: sni_listener
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: dynamic_forward_proxy_cluster
        lb_policy: CLUSTER_PROVIDED
        cluster_type:
          name: envoy.clusters.dynamic_forward_proxy
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.clusters.dynamic_forward_proxy.v3.ClusterConfig
            dns_cache_config:
              name: dynamic_forward_proxy_cache_config
              dns_lookup_family: V4_ONLY

  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_listener
        internal_listener: {}
        listener_filters:
        - name: envoy.filters.listener.tls_inspector
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector

        filter_chains:
        - filter_chain_match:
            server_names:
            - "*.wikipedia.org"
          filters:
            - name: envoy.filters.network.sni_dynamic_forward_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.sni_dynamic_forward_proxy.v3.FilterConfig
                port_value: 443
                dns_cache_config:
                  name: dynamic_forward_proxy_cache_config
                  dns_lookup_family: V4_ONLY
            - name: envoy.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                stat_prefix: tcp
                cluster: dynamic_forward_proxy_cluster
                access_log:
                - name: envoy.access_loggers.file
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                    path: "/dev/stdout"
                    log_format:
                      text_format_source:
                        inline_string: '[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%
                          %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
                          "%UPSTREAM_TRANSPORT_FAILURE_REASON%" %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
                          %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
                          "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%" %UPSTREAM_CLUSTER%
                          %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS%
                          %REQUESTED_SERVER_NAME% %ROUTE_NAME%

                          '
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.tcp_proxy"
    patch:
      operation: MERGE
      value:
        name: envoy.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: tcp
          cluster: sni_cluster
{{< /text >}}

检查 `istiod` 和网关日志是否有任何错误或警告。如果一切顺利，
您的网格 Sidecar 现在会将 `*.wikipedia.org` 请求路由到您的网关 Pod，
然后网关 Pod 将它们转发到应用程序请求中指定的确切远程主机。

## 尝试一下 {#try-it-out}

按照其他 Istio 出口示例，我们将使用
[sleep]({{< github_tree >}}/samples/sleep) Pod 作为发送请求的测试源。
假设已在默认命名空间中启用了自动 Sidecar 注入，请使用以下命令部署测试应用程序：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

获取您的 sleep 和网关 Pod：

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ export GATEWAY_POD=$(kubectl get pod -n istio-egress -l istio=egressgateway -o jsonpath={.items..metadata.name})
{{< /text >}}

运行以下命令以确认您能够连接到 `wikipedia.org` 站点：

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
{{< /text >}}

我们可以访问到英语和德语的 `wikipedia.org` 子域名，非常棒！

通常，在生产环境中，
我们会通过出口网关[阻止未被配置为重定向的外部请求](/zh/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy)，
但由于我们在测试环境中没有这样做，所以让我们访问另一个外部站点进行比较：

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://cloud.ibm.com/login | grep -o "<title>.*</title>"'
<title>IBM Cloud</title>
{{< /text >}}

由于我们在全局范围内打开了访问日志记录（使用清单中的 `Telemetry` CR），
因此我们现在可以检查日志以了解代理如何处理上述请求。

首先，检查网关日志：

{{< text bash >}}
$ kubectl logs -n istio-egress $GATEWAY_POD
[...]
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 813 111152 55 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48262 envoy://sni_listener/ envoy://internal_client_address/ en.wikipedia.org -
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 1531 111950 55 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55102 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 821 92848 49 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48278 envoy://sni_listener/ envoy://internal_client_address/ de.wikipedia.org -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 1539 93646 50 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55108 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
{{< /text >}}

这里有四条日志，代表上面三个 curl 请求中的两个。每对日志都显示单个请求如何流经 Envoy 流量处理管道。
它们以相反的顺序被打印，但我们可以看到第 2 行和第 4 行显示请求到达网关服务并通过内部 `sni_cluster` 目标传递。
第 1 行和第 3 行显示最终目标是根据内部 SNI 标头确定的，即应用程序设置的目标主机。
请求被转发到 `dynamic_forward_proxy_cluster`，后者最终将请求从 Envoy 发送到远程目标。

很好，但是对 IBM Cloud 的第三个请求在哪里？让我们检查一下 Sidecar 日志：

{{< text bash >}}
$ kubectl logs $SOURCE_POD -c istio-proxy
[...]
[2023-11-24T13:21:52.793Z] "- - -" 0 - - - "-" 813 111152 61 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55102 208.80.153.224:443 172.17.34.35:37020 en.wikipedia.org -
[2023-11-24T13:21:52.994Z] "- - -" 0 - - - "-" 821 92848 55 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55108 208.80.153.224:443 172.17.34.35:37030 de.wikipedia.org -
[2023-11-24T13:21:55.197Z] "- - -" 0 - - - "-" 805 15199 158 - "-" "-" "-" "-" "104.102.54.251:443" PassthroughCluster 172.17.34.35:45584 104.102.54.251:443 172.17.34.35:45582 cloud.ibm.com -
{{< /text >}}

正如您所看到的，到 Wikipedia 的请求是通过网关发送的，
而到 IBM Cloud 的请求是直接从应用程序 Pod 发送到互联网的，如 `PassthroughCluster` 日志所示。

## 总结 {#conclusion}

我们使用出口网关实现了出口 HTTPS/TLS 流量的受控路由，支持任意域名和通配符域名。
在生产环境中，本文中展示的示例将进行扩展以支持 HA 要求
（例如，为网关 `Deployment` 添加区域感知等）并限制应用程序的直接外部网络访问，
以便应用程序只能通过网关访问公共网络，该网关仅限于访问一组预定义的远程主机名。

该解决方案可以轻松进行扩展。您可以在配置中包含多个域名，一旦执行，它们就会被列入白名单！
无需配置每个域的 `VirtualService` 或其他路由详细信息。但要小心的是，
由于域名在配置中的多个位置被列出。如果您使用 CI/CD 工具（例如 Kustomize），
最好将域名列表提取到一个单一位置，使其被渲染到所需的配置资源中。

就是这些！我希望这可以帮到您。如果您是之前基于 Nginx 解决方案的现有用户，
现在可以在升级到 Istio 1.20 之前迁移到此方法，否则您当前的设置会被破坏。

请开心的使用 SNI 路由！

## 参考 {#references}

* [SNI 转发器的 Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [之前使用 Nginx 作为网关中的 SNI 代理容器的解决方案](https://archive.istio.io/v1.13/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)
