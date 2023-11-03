---
title: 模拟运行
description: 展示如何在不实际执行的情况下，观察授权策略应用后的效果。
weight: 65
keywords: [security,access-control,rbac,authorization,dry-run]
owner: istio/wg-security-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

本任务将向您展示如何使用新的[实验性注解 `istio.io/dry-run`](/zh/docs/reference/config/annotations/)
来设置 Istio 授权策略，并对其进行模拟运行而不实际执行。

模拟运行注解允许您在生产流量上应用授权策略之前更好地理解其效果，
从而帮助减少由于不正确的授权策略引起的生产流量中断风险。

## 开始之前 {#before-you-begin}

在开始本任务之前，请完成以下操作：

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 按照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)来安装 Istio。

* 部署 Zipkin 以检查模拟运行追踪结果。按照
  [Zipkin 任务](/zh/docs/tasks/observability/distributed-tracing/zipkin/)
  将 Zipkin 安装到集群中。

* 部署 Prometheus 以检查模拟运行指标结果。按照
  [Prometheus 任务](/zh/docs/tasks/observability/metrics/querying-metrics/)
  将 Prometheus 安装到集群中。

* 部署测试工作负载：

    本任务使用 `httpbin` 和 `sleep` 两个工作负载，均部署在命名空间 `foo` 中。
    两个工作负载都带有 Envoy 代理 Sidecar。请使用以下命令创建 `foo` 命名空间并部署工作负载：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n foo
    {{< /text >}}

* 启用代理调试级别日志以检查模拟运行日志结果：

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin.foo --level "rbac:debug" | grep rbac
    rbac: debug
    {{< /text >}}

* 使用以下命令验证 `sleep` 是否可以访问 `httpbin`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您按照指南操作无法看到期望的输出，请稍等几秒钟后重试。
因为缓存和传播开销可能会导致某些延迟。
{{< /warning >}}

## 创建模拟运行策略 {#create-dry-run-policy}

1. 使用以下命令创建带有模拟运行注解 `"istio.io/dry-run": "true"` 的授权策略：

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-path-headers
      annotations:
        "istio.io/dry-run": "true"
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            paths: ["/headers"]
    EOF
    {{< /text >}}

    您也可以使用以下命令将现有的授权策略快速更改为模拟运行模式：

    {{< text bash >}}
    $ kubectl annotate --overwrite authorizationpolicies deny-path-headers -n foo istio.io/dry-run='true'
    {{< /text >}}

1. 验证请求路径 `/headers` 是否允许，因为策略是在模拟运行模式下创建的，
   所以请运行以下命令将 20 个请求从 `sleep` 发送到 `httpbin`，
   此请求包含头部 `X-B3-Sampled: 1` 以始终触发 Zipkin 追踪：

    {{< text bash >}}
    $ for i in {1..20}; do kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s -o /dev/null -w "%{http_code}\n"; done
    200
    200
    200
    ...
    {{< /text >}}

## 在代理日志中检查模拟运行结果 {#check-dry-run-results-in-proxy-log}

模拟运行结果可以在代理调试日志中找到，格式为
`shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]`。
运行以下命令检查日志：

{{< text bash >}}
$ kubectl logs "$(kubectl -n foo -l app=httpbin get pods -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo | grep "shadow denied"
2021-11-19T20:20:48.733099Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:21:45.502199Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:22:33.065348Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
...
{{< /text >}}

另见[故障排查指南](/zh/docs/ops/common-problems/security-issues/#ensure-proxies-enforce-policies-correctly)了解日志记录的更多细节。

## 使用 Prometheus 检查指标中的模拟运行结果 {#check-dry-run-result-in-metric-using-prometheus}

1. 使用以下命令打开 Prometheus 仪表板：

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

1. 在 Prometheus 仪表板中，搜索以下指标：

    {{< text plain >}}
    envoy_http_inbound_0_0_0_0_80_rbac{authz_dry_run_action="deny",authz_dry_run_result="denied"}
    {{< /text >}}

1.  验证如下查询的指标结果：

    {{< text plain >}}
    envoy_http_inbound_0_0_0_0_80_rbac{app="httpbin",authz_dry_run_action="deny",authz_dry_run_result="denied",instance="10.44.1.11:15020",istio_io_rev="default",job="kubernetes-pods",kubernetes_namespace="foo",kubernetes_pod_name="httpbin-74fb669cc6-95qm8",pod_template_hash="74fb669cc6",security_istio_io_tlsMode="istio",service_istio_io_canonical_name="httpbin",service_istio_io_canonical_revision="v1",version="v1"}  20
    {{< /text >}}

1. 查询的指标值为 `20`（根据发送的请求数量，您可能会找到不同的值。只要该值大于0，就是预期的结果）。
   这意味着模拟运行策略应用于端口 `80` 上的 `httpbin` 工作负载匹配了一个请求。
   如果策略未处于模拟运行模式，则该策略将拒绝一次请求。

1. 以下是 Prometheus 仪表板的屏幕截图：

    {{< image width="100%" link="./prometheus.png" caption="Prometheus dashboard" >}}

## 使用 Zipkin 检查追踪中的模拟运行结果 {#check-dry-run-result-in-tracing-using-zipkin}

1. 使用以下命令打开 Zipkin 仪表板：

    {{< text bash >}}
    $ istioctl dashboard zipkin
    {{< /text >}}

1. 查找从 `sleep` 到 `httpbin` 的请求的追踪结果。
   如果您由于 Zipkin 中的延迟看到追踪结果，请尝试发送更多请求。

1. 在追踪结果中，您应看到以下自定义标记，表明此请求被命名空间 `foo` 中的模拟运行策略 `deny-path-headers` 拒绝：

    {{< text plain >}}
    istio.authorization.dry_run.deny_policy.name: ns[foo]-policy[deny-path-headers]-rule[0]
    istio.authorization.dry_run.deny_policy.result: denied
    {{< /text >}}

1. 以下是 Zipkin 仪表板的屏幕截图：

    {{< image width="100%" link="./trace.png" caption="Zipkin dashboard" >}}

## 总结 {#summary}

代理调试日志、Prometheus 指标和 Zipkin 追踪结果表明模拟运行策略将拒绝请求。
如果模拟运行结果不符预期，您可以进一步更改策略。

建议保留模拟运行策略一段时间，以便可以使用更多的生产流量进行测试。

当您对模拟运行结果有信心时，可以禁用模拟运行模式，以便该策略开始实际拒绝请求。这可以通过以下任一方法实现：

* 完全删除模拟运行注解】；或

* 将模拟运行注解的值更改为 `false`。

## 限制 {#limiatations}

模拟运行注解目前处于实验阶段，具有以下限制：

* 模拟运行注解目前仅支持 ALLOW 和 DENY 策略；

* 由于在代理中独立执行 ALLOW 和 DENY 策略，所以将有两个单独的模拟运行结果（即日志、指标和追踪标记）。
  您应该考虑所有两个模拟运行结果，因为一个请求可能会被 ALLOW 策略允许，但仍会被另一个 DENY 策略拒绝；

* 代理日志、指标和追踪中的模拟运行结果仅用于手动故障排除，并且不应用作 API，因为它可能随时更改而没有事先通知。

## 清理 {#clean-up}

1. 从您的配置中移除命名空间 `foo`：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. 如果不再需要，可以移除 Prometheus 和 Zipkin。
