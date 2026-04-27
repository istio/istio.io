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

Istio 提供了通过 [`TrafficExtension`](/zh/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API，
利用 [WebAssembly (Wasm)](/zh/docs/concepts/extensibility/trafficextension/#webassembly-filters) 模块来扩展 waypoint 代理的能力。
在 Ambient 模式下，必须使用 `targetRefs` 将 `TrafficExtension` 资源关联至 waypoint 代理。

## 开始之前 {#before-you-begin}

1. 按照 [Ambient 模式入门指南](/zh/docs/ambient/getting-started) 设置 Istio。
1. 部署 [Bookinfo 示例应用](/zh/docs/ambient/getting-started/deploy-sample-app)。
1. [将 default 命名空间添加到 Ambient 网格](/zh/docs/ambient/getting-started/secure-and-visualize)。
1. 部署 [curl]({{< github_tree >}}/samples/curl) 样例应用，用作发送请求的测试源。

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## 在网关处 {#at-a-gateway}

借助 Kubernetes Gateway API，Istio 提供了一个集中式的入口点，
用于管理流入服务网格的流量。我们将配置一个网关级别的 `TrafficExtension`，
以确保所有流经该网关的流量均受扩展认证规则的约束。

### 为网关配置 WebAssembly 插件 {#configure-a-webassembly-plugin-for-a-gateway}

在此示例中，您将向服务网格添加一个 HTTP [基本认证模块](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)。
您将配置 Istio，使其从远程镜像仓库拉取该基本认证模块并将其加载。
该模块将被配置为在处理对 `/productpage` 的调用时运行。
这些步骤与 [执行 WebAssembly 模块](/zh/docs/tasks/extensibility/wasm-modules/)中的步骤类似，
唯一的区别在于此处使用的是 `targetRefs` 字段，而非标签选择器。

获取网关名称：

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

创建一个以 `bookinfo-gateway` 为目标的 `TrafficExtension`：

{{< text syntax=bash snip_id=apply_wasmplugin_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
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

一个 HTTP 过滤器将被注入到网关处，作为认证过滤器使用。
Istio 代理将解析 `TrafficExtension` 配置，从 OCI 镜像仓库下载远程 Wasm 模块至本地文件，
随后通过引用该文件，将该 HTTP 过滤器注入到网关中。

### 通过网关来验证流量 {#verify-the-traffic-via-the-gateway}

1. 在没有凭据的情况下测试 `/productpage`：

    {{< text syntax=bash snip_id=test_gateway_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

1. 使用 `TrafficExtension` 资源中配置的凭据来测试 `/productpage`：

    {{< text syntax=bash snip_id=test_gateway_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## 在 waypoint 处设置命名空间中的所有服务 {#apply-wasm-configuration-at-waypoint-proxy}

waypoint 代理在 Istio 的 Ambient 模式中发挥着至关重要的作用，
有助于促进服务网格内部安全且高效的通信。接下来，
我们将探讨如何将 Wasm 配置应用到 waypoint 上，从而动态增强代理的功能。

### 部署 waypoint 代理 {#deploy-a-waypoint-proxy}

遵循 [waypoint 部署说明](/zh/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy)将
waypoint 代理部署到 bookinfo 命名空间中。

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

验证到达服务的流量：

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### 为 waypoint 配置 WebAssembly 插件 {#configure-a-webassembly-plugin-for-a-waypoint}

获取 waypoint 网关名称：

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

创建一个以 waypoint 为目标的 `TrafficExtension`：

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
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

{{< text syntax=bash snip_id=get_trafficextension >}}
$ kubectl get trafficextension
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### 通过 waypoint 代理来验证流量 {#verify-the-traffic-via-waypoint-proxy}

1. 在不含凭据的情况下测试内部 `/productpage`：

    {{< text syntax=bash snip_id=test_waypoint_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

1. 在有凭据的情况下测试内部 `/productpage`：

    {{< text syntax=bash snip_id=test_waypoint_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## 在 waypoint 处设置特定的服务 {#at-a-waypoint-for-a-specific-service}

创建一个针对 `reviews` 服务的 `TrafficExtension`，
以确保该扩展仅应用于 `reviews` 服务。在此配置中，
认证令牌和前缀均专为 `reviews` 服务定制，
从而确保仅有发往该服务的请求才会受到此认证机制的约束。

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
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
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

1. 使用为 `reviews` 服务配置的凭据，测试内部 `/reviews` 接口：

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

1. 在没有凭据的情况下测试内部 `/reviews`：

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

## 清理 {#cleanup}

1. 移除 `TrafficExtension` 资源：

    {{< text syntax=bash snip_id=remove_wasmplugin >}}
    $ kubectl delete trafficextension basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

1. 参考 [Ambient 模式卸载指南](/zh/docs/ambient/getting-started/#uninstall)移除
   Istio 和样例测试应用。
