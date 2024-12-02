---
title: 执行鉴权政策
description: 在 Ambient 网格中执行四层和七层鉴权策略。
weight: 4
owner: istio/wg-networking-maintainers
test: yes
---

将应用程序添加到 Ambient 网格后，您可以使用四层鉴权策略保护应用程序访问。

此功能允许您根据自动发布给网格中所有工作负载的客户端工作负载身份来控制对服务的访问。

## 执行四层鉴权策略 {#enforce-layer-4-authorization-policy}

让我们创建一个[鉴权策略](/zh/docs/reference/config/security/authorization-policy/)，
以限制哪些服务可以与 `productpage` 服务进行通信。该策略应用于带有 `app: productpage`
标签的 Pod，并且仅允许来自服务帐户 `cluster.local/ns/default/sa/bookinfo-gateway-istio` 的调用。
这是您在上一步中部署的 Bookinfo 网关所使用的服务帐户。

{{< text syntax=bash snip_id=deploy_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
EOF
{{< /text >}}

如果您在浏览器中打开 Bookinfo 应用程序（`http://localhost:8080/productpage`），
如之前一样，您将看到产品页面。但是，如果您尝试从不同的服务帐户访问 `productpage` 服务，则会看到错误。

让我们尝试从集群中的不同客户端访问 Bookinfo 应用程序：

{{< text syntax=bash snip_id=deploy_curl >}}
$ kubectl apply -f samples/curl/curl.yaml
{{< /text >}}

由于 `curl` Pod 使用不同的服务账户，它无法访问 `productpage` 服务：

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage"
command terminated with exit code 56
{{< /text >}}

## 执行七层鉴权策略 {#enforce-layer-7-authorization-policy}

要实施七层策略，您首先需要为命名空间部署一个 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}。
此代理将处理进入命名空间的所有七层流量。

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

您可以查看 waypoint 代理并确保其具有 `Programmed=True` 状态：

{{< text bash >}}
$ kubectl get gtw waypoint
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         42s
{{< /text >}}

添加 [L7 鉴权策略](/zh/docs/ambient/usage/l7-features/)将明确允许 `curl` 服务向
`productpage` 服务发送 `GET` 请求，但不能执行其他操作：

{{< text syntax=bash snip_id=deploy_l7_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/curl
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

请注意，`targetRefs` 字段使用于指定 waypoint 代理授权策略的目标服务。
规则部分与以前类似，但这次您添加了 `to` 部分来指定允许的操作。

{{< tip >}}
要了解如何启用更多 Istio 功能，请阅读[使用七层功能用户指南](/zh/docs/ambient/usage/l7-features/)。
{{< /tip >}}

确认新的 waypoint 代理正在执行更新后的鉴权策略：

{{< text bash >}}
$ # 由于您没有使用 GET 操作，因此此操作会失败并出现 RBAC 错误
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage" -X DELETE
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # 由于 reviews-v1 服务的身份不被允许，因此此操作失败并出现 RBAC 错误
$ kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/productpage
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # 这是有效的，因为您明确允许来自 curl Pod 的 GET 请求
$ kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

## 下一步 {#next-steps}

使用 waypoint 代理后，您现在可以在命名空间中执行七层策略。
除了鉴权策略之外，[您还可以使用 waypoint 代理在服务之间拆分流量](../manage-traffic/)。
这在进行金丝雀部署或 A/B 测试时非常有用。
