---
title: 出口网关
description: 使用 waypoint 作为出口网关来控制和观察离开网格的流量。
weight: 45
keywords: [ambient,egress,gateway,serviceentry,waypoint]
owner: istio/wg-networking-maintainers
test: yes
---

出口网关是一个专用代理，所有到外部服务的出站流量都必须经过它。
它为离开网格的流量提供了一个可验证的出口点，您可以在其中应用授权策略、启用可观测性并发起 TLS。

在 {{< gloss "sidecar" >}}Sidecar 模式{{< /gloss >}}中，
为单个主机配置出口网关需要协调五个单独的对象：一个 `ServiceEntry`、
一个 `Gateway`、两个 `HTTPRoute` 资源（一个用于将网格流量引导到网关，一个用于将流量从网关转发到目的地）和一个
`DestinationRule`。每个新的外部主机都会重复大部分工作。

在 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}中，
{{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}自然充当出口网关。
ztunnel 在将流量转发到目的地之前自动将流量路由到服务的 waypoint。
如果您将 [`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/)
放置在注册使用 waypoint 的命名空间中，则到该外部主机的所有网格流量都会自动通过该
waypoint，无需额外的路由规则。

## 在开始之前 {#before-you-begin}

- 在[启用 Ambient 模式](/zh/docs/ambient/install/)的情况下安装 Istio。
- 部署工作负载以用作流量源。[curl]({{< github_tree >}}/samples/curl) 示例运行良好：

    {{< text syntax=bash snip_id=deploy_curl >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

- 将工作负载的命名空间标记为 Ambient 模式，以便 ztunnel 拦截其流量：

    {{< text syntax=bash snip_id=label_default_ambient >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    {{< /text >}}

## 设置出口命名空间 {#set-up-the-egress-namespace}

为出口资源创建专用命名空间。将外部服务定义及其策略与应用程序命名空间隔离，
可以简化管理并减少错误配置的影响范围。

{{< text syntax=bash snip_id=create_egress_ns >}}
$ kubectl create namespace istio-egress
$ kubectl label namespace istio-egress istio.io/dataplane-mode=ambient
{{< /text >}}

## 部署出口 waypoint {#deploy-the-egress-waypoint}

在出口命名空间中部署 waypoint 代理并注册命名空间以使用它。
`--enroll-namespace` 标志将 `istio.io/use-waypoint` 标签添加到命名空间，
因此其中定义的每个服务，包括由 `ServiceEntry` 支持的服务，都将通过该路径点进行路由。

{{< boilerplate gateway-api-install-crds >}}

{{< text syntax=bash snip_id=apply_egress_waypoint >}}
$ istioctl waypoint apply --for service --enroll-namespace --namespace istio-egress
✅ waypoint istio-egress/waypoint applied
✅ namespace istio-egress labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

确认 waypoint 已准备好：

{{< text syntax=bash snip_id=wait_egress_waypoint >}}
$ istioctl waypoint list -n istio-egress
NAME       REVISION  TRAFFIC TYPE  PROGRAMMED
waypoint   default   service       True
{{< /text >}}

## 定义外部服务 {#define-an-external-service}

在出口命名空间中创建一个 `ServiceEntry` 来表示外部主机。
由于命名空间已注册为使用 waypoint，因此 ztunnel 会自动通过 waypoint 将所有网格流量路由到该主机。
默认情况下，`ServiceEntry` 在集群范围内可见（`exportTo: *`），
因此每个节点上的 ztunnel 都会将 `httpbin.org` 解析为 `istio-egress` waypoint，无需任何其他配置。

{{< text syntax=bash snip_id=apply_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

## 验证通过出口 waypoint 的流量路径 {#verify-traffic-routes-through-the-egress-waypoint}

从 curl Pod 向外部主机发送请求并确认其到达目的地：

{{< text syntax=bash snip_id=verify_egress_traffic >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

要确认经过该 waypoint 的流量，请检查该 waypoint 的 Envoy 统计数据：

{{< text syntax=bash snip_id=check_waypoint_logs >}}
$ kubectl exec -n istio-egress deploy/waypoint -c istio-proxy -- pilot-agent request GET stats | grep upstream_rq_total
{{< /text >}}

非零的 `upstream_rq_total` 计数（waypoint 向上游转发的请求数）确认 waypoint 正在充当出口网关。

{{< warning >}}
注册命名空间通过 waypoint 路由流量，但如果 waypoint 不可用，
则不会阻止直接路径。如果出口控制是一项安全要求，请添加仅允许 waypoint
身份的 `AuthorizationPolicy`，由 ztunnel 在 L4 强制执行。
请参阅[要求流量经过 waypoint](/zh/docs/ambient/usage/waypoint/#require-waypoint)。
{{< /warning >}}

## 强制执行访问策略 {#enforce-access-policies}

由于流量会经过 waypoint，因此您可以将 L7 授权策略直接附加到 `ServiceEntry`。
以下策略允许任何源仅向 `/get` 发出 `GET` 请求：

{{< text syntax=bash snip_id=apply_authz_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  targetRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-org
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get"]
EOF
{{< /text >}}

应用策略后，验证允许的请求是否成功：

{{< text syntax=bash snip_id=verify_allowed_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

确认不被允许的请求遭到拒绝：

{{< text syntax=bash snip_id=verify_denied_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" -X POST http://httpbin.org/post
403
{{< /text >}}

## 在出口网关发起 TLS 连接 {#originate-tls-at-the-egress-gateway}

应用程序 Pod 可以将明文 HTTP 发送到出口网关；网关在转发到外部主机之前升级到 HTTPS。
这将 TLS 凭证管理集中在网关处，并避免将证书分发到每个应用程序 Pod。

更新 `ServiceEntry` 以将明文端口映射到 TLS 端口，
并添加 `DestinationRule` 以发起 TLS 连接：

{{< text syntax=bash snip_id=apply_tls_origination >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: httpbin-org-tls
  namespace: istio-egress
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
EOF
{{< /text >}}

验证应用程序是否仍然收到响应，现在由网关通过 HTTPS 发送：

{{< text syntax=bash snip_id=verify_tls_origination >}}
$ kubectl exec deploy/curl -- curl -s http://httpbin.org/get | head -5
{{< /text >}}

{{< tip >}}
ztunnel 自动在应用程序 Pod 和出口 waypoint 之间提供 mTLS。
这里的 `DestinationRule` 仅控制从 waypoint 到外部主机的出站 TLS。
{{< /tip >}}

## 添加不带 TLS 发起（TLS origination）的外部服务 {#add-an-external-service-without-tls-origination}

要通过同一出口路径点公开其他外部主机，请在同一命名空间中创建另一个 `ServiceEntry`。
不需要额外的 waypoint 配置，因为命名空间已经注册：

{{< text syntax=bash snip_id=apply_second_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: example-com
  namespace: istio-egress
spec:
  hosts:
  - example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

验证到新主机的流量是否也通过该 waypoint 路由：

{{< text syntax=bash snip_id=verify_second_serviceentry >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://example.com
200
{{< /text >}}

命名空间中的每个 `ServiceEntry` 都会自动通过 waypoint 进行路由，
并且可以携带自己的 `AuthorizationPolicy`。

## 清理 {#cleanup}

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete namespace istio-egress
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

## 参见 {#see-also}

- [配置 waypoint 代理](/zh/docs/ambient/usage/waypoint/)：常规 waypoint 部署和注册
- [要求流量经过 waypoint](/zh/docs/ambient/usage/waypoint/#require-waypoint)：强制出口流量不能绕过 waypoint
- [ServiceEntry 可见性](/zh/docs/ambient/usage/serviceentry-visibility/)：控制哪些命名空间可以发现每个 `ServiceEntry`
- [使用 L7 功能](/zh/docs/ambient/usage/l7-features/)：waypoint 可用的 L7 策略和路由的完整列表
- [出口网关（Sidecar 模式）](/zh/docs/tasks/traffic-management/egress/egress-gateway/)：用于比较的等效 Sidecar 模式配置
