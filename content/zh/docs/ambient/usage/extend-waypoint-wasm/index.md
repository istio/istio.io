---
title: 使用 WebAssembly 插件扩展 waypoint
description: 说明如何在 Ambient 模式中使用远程 WebAssembly 模块。
weight: 55
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供了[使用 WebAssembly（Wasm）扩展其功能的能力](/zh/docs/concepts/wasm/)。
Wasm 可扩展性的一个主要优势是可以在运行时动态加载扩展插件。
本文概述了如何在 Istio 中使用 Wasm 功能扩展 Ambient 模式。
在 Ambient 模式下，必须将 Wasm 配置应用到部署在每个命名空间中的 waypoint 代理。

## 开始之前 {#before-you-begin}

1. 参照 [Ambient 模式入门指南](/zh/docs/ambient/getting-started)中的指示说明设置 Istio。
1. 部署 [Bookinfo 示例应用](/zh/docs/ambient/getting-started/deploy-sample-app)。
1. [将 default 命名空间添加到 Ambient 网格](/zh/docs/ambient/getting-started/secure-and-visualize)。
1. 部署 [sleep]({{< github_tree >}}/samples/sleep) 样例应用，用作发送请求的测试源。

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

## 在网关处 {#at-a-gateway}

Istio 使用 Kubernetes Gateway API，提供了一个集中的入口点来管理进入服务网格的流量。
我们将在网关级别配置一个 WasmPlugin，确保所有通过网关的流量都遵循扩展的身份验证规则。

### 为网关配置 WebAssembly 插件 {#configure-a-webassembly-plugin-for-a-gateway}

在此示例中，您将向网格添加一个 HTTP
[基本的身份验证模块](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)。
您将配置 Istio 从远程镜像仓库中拉取并加载基本身份验证模块。
此模块将被配置为在调用 `/productpage` 时运行。
这些步骤与[分发 WebAssembly 模块](/zh/docs/tasks/extensibility/wasm-module-distribution/)大致相同，
区别是推荐使用 `targetRefs` 而不是标签选择算符。

要使用远程 Wasm 模块配置一个 WebAssembly 过滤器，
请创建一个指向 `bookinfo-gateway` 的 `WasmPlugin` 资源：

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway # gateway name retrieved from previous step
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

HTTP 过滤器将被作为身份验证过滤器注入网关。
Istio 代理将解释 WasmPlugin 配置，从 OCI 镜像仓库下载远程 Wasm 模块到本地文件，
并通过引用该文件在网关处注入 HTTP 过滤器。

### 通过网关来验证流量 {#verify-the-traffic-via-the-gateway}

1. 在没有凭据的情况下测试 `/productpage`：

    {{< text syntax=bash snip_id=test_gateway_productpage_without_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

1. 使用 WasmPlugin 资源中配置的凭据来测试 `/productpage`：

    {{< text syntax=bash snip_id=test_gateway_productpage_with_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## 在 waypoint 处设置命名空间中的所有服务 {#apply-wasm-configuration-at-waypoint-proxy}

waypoint 代理在 Istio 的 Ambient 模式中扮演了一个重要的角色：在服务网格内确保通讯安全和高效。
下文将探索如何将 Wasm 配置应用到 waypoint，动态增强代理功能。

### 部署 waypoint 代理 {#deploy-a-waypoint-proxy}

遵循 [waypoint 部署说明](/zh/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy)将
waypoint 代理部署到 bookinfo 命名空间中。

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

验证到达服务的流量：

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### 为 waypoint 配置 WebAssembly 插件 {#configure-a-webassembly-plugin-for-a-waypoint}

要使用远程 Wasm 模块配置 WebAssembly 过滤器，
请创建指向 `waypoint` 网关的 `WasmPlugin` 资源：

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint # gateway name retrieved from previous step
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### 查看配置的插件 {#view-the-configured-plugin}

{{< text syntax=bash snip_id=get_wasmplugin >}}
$ kubectl get wasmplugin
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### 通过 waypoint 代理来验证流量 {#verify-the-traffic-via-waypoint-proxy}

1. 在不含凭据的情况下测试内部 `/productpage`：

    {{< text syntax=bash snip_id=test_waypoint_productpage_without_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

1. 在有凭据的情况下测试内部 `/productpage`：

    {{< text syntax=bash snip_id=test_waypoint_productpage_with_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## 在 waypoint 处设置特定的服务 {#at-a-waypoint-for-a-specific-service}

要为特定服务使用远程 Wasm 模块配置 WebAssembly 过滤器，
请直接创建指向特定服务的 WasmPlugin 资源。

创建一个指向 `reviews` 服务的 `WasmPlugin`，以便此扩展仅适用于 `reviews` 服务。
在此配置中，身份验证令牌和前缀是专门为 `reviews` 服务定制的，
确保只有指向它的请求才会受到此身份验证机制的影响。

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/reviews"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "MXQtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### 验证指向服务的流量 {#verify-the-traffic-targeting-the-service}

1. 使用通用 `waypoint` 代理处配置的凭据来测试内部 `/productpage`：

    {{< text syntax=bash snip_id=test_waypoint_service_productpage_with_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

1. 使用特定的 `reviews-svc-waypoint` 代理处配置的凭据来测试内部 `/reviews`：

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_with_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

1. 在没有凭据的情况下测试内部 `/reviews`：

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_without_credentials >}}
    $ kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

当在没有凭据的情况下执行提供的命令时，它会验证访问内部 `/productpage` 会造成
401 未经授权的响应，这确认了在没有正确身份验证凭据的情况下访问资源会失败的预期行为。

## 清理 {#cleanup}

1. 移除 WasmPlugin 配置：

    {{< text syntax=bash snip_id=remove_wasmplugin >}}
    $ kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

1. 参考 [Ambient 模式卸载指南](/zh/docs/ambient/getting-started/#uninstall)移除
   Istio 和样例测试应用。
