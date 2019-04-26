---
title: HTTP Egress 流量监控和访问策略
description: 描述如何配置 Istio 进行 HTTP Egress 流量监控和访问策略。
publishdate: 2018-06-22
last_update: 2019-01-29
attribution: Vadim Eisenberg and Ronen Schaffer (IBM)
keywords: [egress,traffic-management,access-control,monitoring]
---

虽然 Istio 的主要关注点是管理服务网格内微服务之间的流量，但它也可以管理 ingress (从外部进入网格)和 egress (从网格向外)的流量。Istio 可以统一执行访问策略，并为网格内部、ingress 和 egress 流量聚合遥测数据。

在这篇博客文章中，将向您展示如何使用 Istio 进行 HTTP Egress 流量监控和访问策略。

## 用例

考虑一个运行处理 _cnn.com_ 内容的应用程序的组织。应用程序被解耦为部署在 Istio 服务网格中的微服务。应用程序访问 _cnn.com_ 的各种话题页面：[edition.cnn.com/politics](https://edition.cnn.com/politics)， [edition.cnn.com/sport](https://edition.cnn.com/sport) 和  [edition.cnn.com/health](https://edition.cnn.com/health)。该组织[配置了访问 edition.cnn.com 的权限](/docs/examples/advanced-gateways/egress-gateway-tls-origination/)，一切都正常运行。然而，在某一时刻，本组织决定移除政治话题。实际上，这意味着禁止访问 [edition.cnn.com/politics](https://edition.cnn.com/politics) ，只允许访问 [edition.cnn.com/sport](https://edition.cnn.com/sport)和[edition.cnn.com/health](https://edition.cnn.com/health) 。该组织将根据具体情况，向个别应用程序和特定用户授予访问 [edition.cnn.com/politics](https://edition.cnn.com/politics) 的权限。

为了实现这一目标，组织的运维人员监控对外部服务的访问，并分析 Istio 日志，以验证没有向 [edition.cnn.com/politics](https://edition.cnn.com/politics) 发送未经授权的请求。他们还配置了 Istio 来防止自动访问 [edition.cnn.com/politics](https://edition.cnn.com/politics) 。

本组织决心防止对新策略的任何篡改，决定设置一些机制以防止恶意应用程序访问禁止的话题。

## 相关工作和示例

* [Control Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务演示了网格内的应用程序如何访问外部(Kubernetes 集群之外) HTTP 和 HTTPS 服务。
* [配置 Egress 网关](/zh/docs/examples/advanced-gateways/egress-gateway/)示例描述了如何配置 Istio 来通过一个称为 _出口网关_ 的专用网关服务来引导出口流量。
* [带 TLS 发起的 Egress 网关](/docs/examples/advanced-gateways/egress-gateway-tls-origination/) 示例演示了如何允许应用程序向需要 HTTPS 的外部服务器发送 HTTP 请求，同时通过 Egress Gateway 引导流量。
* [收集指标](/docs/tasks/telemetry/metrics/collecting-metrics/)任务描述如何为网格中的服务配置指标。
* [Grafana 的可视化指标](/zh/docs/tasks/telemetry/metrics/using-istio-dashboard/)描述了用于监控网格流量的 Istio 仪表板。
* [基本访问控制](/zh/docs/tasks/policy-enforcement/denial-and-list/)任务显示如何控制对网格内服务的访问。
* [拒绝和白/黑名单](/zh/docs/tasks/policy-enforcement/denial-and-list/)任务显示如何使用黑名单或白名单检查器配置访问策略。

与上面的遥测和安全任务相反，这篇博客文章描述了 Istio 的监控和访问策略，专门应用于 egress 流量。

## 开始之前

按照[带 TLS 发起的 Egress 网关](/docs/examples/advanced-gateways/egress-gateway-tls-origination/)中的步骤，**启用了双向 TLS 身份验证**，而不需要[清除](/docs/examples/advanced-gateways/egress-gateway-tls-origination//#cleanup)步骤。完成该示例后，您可以从安装了 `curl` 的网格中容器访问 [edition.cnn.com/politics](https://edition.cnn.com/politics)。本文假设 `SOURCE_POD` 环境变量包含源 pod 的名称，容器的名称为 `sleep`。

## 配置监控和访问策略

由于您希望以 _安全方式_ 完成您的任务，您应该通过 _egress 网关_ 引导流量，正如[带 TLS 发起的 Egress 网关](/docs/examples/advanced-gateways/egress-gateway-tls-origination/)任务中所描述的那样。这里的 _安全方式_ 意味着您希望防止恶意应用程序绕过 Istio 监控和策略强制。

根据我们的场景，组织执行了[开始之前](#开始之前)部分中的命令，启用 HTTP 流量到 _edition.cnn.com_ ，并将该流量配置为通过 egress 网关。egress 网关执行 TLS 发起到 _edition.cnn.com_ ，因此流量在网格中被加密。此时，组织已经准备好配置 Istio 来监控和应用 _edition.cnn.com_ 流量的访问策略。

### 日志

配置 Istio 以记录对 _*.cnn.com_ 的访问。创建一个 `logentry` 和两个 [stdio](/docs/reference/config/policy-and-telemetry/adapters/stdio/) `handlers`，一个用于记录禁止访问(_error_ 日志级别)，另一个用于记录对 _*.cnn.com_ 的所有访问(_info_ 日志级别)。然后创建规则将 `logentry` 实例定向到 `handlers`。一个规则指导访问 _*.cnn.com/politics_ 为日志禁止访问处理程序,另一个规则指导日志条目的处理程序，输出每个访问 _*.cnn.com_ 作为 _info_ 的日志级别。要了解 Istio `logentries`、`rules` 和 `handlers`，请参见 [Istio 适配器模型](/zh/blog/2017/adapter-model/)。下图显示了涉及的实体和它们之间的依赖关系：

{{< image width="80%"
    link="egress-adapters-monitoring.svg"
    caption="用于 egress 监视和访问策略的实例、规则和处理程序"
    >}}

1.  创建 `logentry`、 `rules` 和 `handlers`。 注意您指定了 `context.reporter.uid` 作为
    `kubernetes://istio-egressgateway` 在规则中只能从 egress 网关获取日志信息。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    # Log entry for egress access
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: egress-access
      namespace: istio-system
    spec:
      severity: '"info"'
      timestamp: request.time
      variables:
        destination: request.host | "unknown"
        path: request.path | "unknown"
        responseCode: response.code | 0
        responseSize: response.size | 0
        reporterUID: context.reporter.uid | "unknown"
        sourcePrincipal: source.principal | "unknown"
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Handler for error egress access entries
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: egress-error-logger
      namespace: istio-system
    spec:
     severity_levels:
       info: 2 # output log level as error
     outputAsJson: true
    ---
    # Rule to handle access to *.cnn.com/politics
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-politics
      namespace: istio-system
    spec:
      match: request.host.endsWith("cnn.com") && request.path.startsWith("/politics") && context.reporter.uid.startsWith("kubernetes://istio-egressgateway")
      actions:
      - handler: egress-error-logger.stdio
        instances:
        - egress-access.logentry
    ---
    # Handler for info egress access entries
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: egress-access-logger
      namespace: istio-system
    spec:
      severity_levels:
        info: 0 # output log level as info
      outputAsJson: true
    ---
    # Rule to handle access to *.cnn.com
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-cnn-access
      namespace: istio-system
    spec:
      match: request.host.endsWith(".cnn.com") && context.reporter.uid.startsWith("kubernetes://istio-egressgateway")
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
    EOF
    {{< /text >}}

1.  发送三个 HTTP 请求到 _cnn.com_ 、 [edition.cnn.com/politics](https://edition.cnn.com/politics)、 [edition.cnn.com/sport](https://edition.cnn.com/sport) 和 [edition.cnn.com/health](https://edition.cnn.com/health)。
三个请求都应该返回 _200 OK_ 。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    {{< /text >}}

1.  查询 Mixer 日志，查看请求信息出现在日志中:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2019-01-29T07:43:24.611462Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":1883355,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"info","time":"2019-01-29T07:43:24.886316Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2094561,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"info","time":"2019-01-29T07:43:25.369663Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2157009,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"error","time":"2019-01-29T07:43:24.611462Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":1883355,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {{< /text >}}

    您将看到与您的三个请求相关的四个日志条目。三个关于访问 _edition.cnn.com_ 的 _info_ 信息和一个关于访问 _edition.cnn.com/politics_ 的 _error_ 信息。服务网格 operators 可以查看所有访问实例，还可以搜索日志中表示禁止访问的 _error_ 日志。这是在自动地阻塞禁止访问之前可以应用的第一个安全措施，即将所有禁止访问实例记录为错误。在某些设置中，这可能是一个足够的安全措施。

    注意以下属性：
      * `destination`、 `path`、 `responseCode` 和 `responseSize` 与请求的 HTTP 参数相关
      * `sourcePrincipal`:`cluster.local/ns/default/sa/sleep` —— 表示 `default` 命名空间中的 `sleep` 服务帐户的字符串
      * `reporterUID`: `kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system` —— 报告 pod 的 UID，在本例中为 `istio-egressgateway-747b6764b8-44rrh`，位于 `istio-system` 命名空间中

### 路由访问控制

启用对 _edition.cnn.com_ 的访问进行日志记录之后，自动执行访问策略，即只允许访问 _/health_ 和 _/sport_ URL 路径。这样一个简单的策略控制可以通过 Istio 路由实现。

1.  为 _edition.cnn.com_ 重定义 `VirtualService` ：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          uri:
            regex: "/health|/sport"
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

    注意，您通过 `url` 添加添加了一个 `match`，该条件检查 URL 路径是 _/health_ 还是 _/sport_ 。还要注意，此条件已添加到 `VirtualService` 的 `istio-egressgateway` 部分，因为就安全性而言，egress 网关是一个经过加固的组件（请参阅 [egress 网关安全性注意事项](/zh/docs/examples/advanced-gateways/egress-gateway/#额外的安全考量)）。您一定不希望您的任何策略被篡改。

1.  发送之前的三个 HTTP 请求到 _cnn.com_ ：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    {{< /text >}}

    向 [edition.cnn.com/politics](https://edition.cnn.com/politics) 发送请求会返回 _404 Not Found_ ， 然而向
      [edition.cnn.com/sport](https://edition.cnn.com/sport) 和
     [edition.cnn.com/health](https://edition.cnn.com/health) 发送请求，会像我们预想的那样返回 _200 OK_ 。

    {{< tip >}}
    您可能需要等待几秒钟，等待 `VirtualService` 的更新传播到 egress 网关。
    {{< /tip >}}

1.  查询 Mixer 日志，可以看到关于请求的信息再次出现在日志中：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2019-01-29T07:55:59.686082Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":404,"responseSize":0,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"info","time":"2019-01-29T07:55:59.697565Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2094561,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"info","time":"2019-01-29T07:56:00.264498Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2157009,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {"level":"error","time":"2019-01-29T07:55:59.686082Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":404,"responseSize":0,"sourcePrincipal":"cluster.local/ns/default/sa/sleep"}
    {{< /text >}}

    你依然会得到关于访问[edition.cnn.com/politics](https://edition.cnn.com/politics)的信息和错误消息，然而这次 `responseCode` 会像我们预想的那样返回 `404` 。

虽然在这个简单的例子中使用 Istio 路由实现访问控制是可行的，但是在更复杂的例子中就不够了。例如，组织可能希望在某些条件下允许访问[edition.cnn.com/politics](https://edition.cnn.com/politics)，因此需要比仅通过 URL 路径过滤更复杂的策略逻辑。您可能想要应用 Istio Mixer 适配器，例如允许/禁止 URL 路径的[白名单或黑名单](/docs/tasks/policy-enforcement/denial-and-list/#attribute-based-whitelists-or-blacklists)。策略规则允许指定复杂的条件，用丰富的表达式语言指定，其中包括与和或逻辑运算符。这些规则可用于日志记录和策略检查。更高级的用户可能希望应用基于 [Istio 角色访问控制](/docs/concepts/security/#authorization)。

另一方面是与远程访问策略系统的集成。如果在我们的用例中组织操作一些[标识和访问管理](https://en.wikipedia.org/wiki/Identity_management)系统，您可能希望配置 Istio 来使用来自这样一个系统的访问策略信息。您可以通过应用 [Istio Mixer 适配器](/blog/2017/adapter-model/)来实现这种集成。

现在您移除在本节中使用的路由取消访问控制，在下一节将向您演示通过 Mixer 策略检查实现访问控制。

1.  用之前[配置 Egress 网关](/docs/examples/advanced-gateways/egress-gateway-tls-origination/#perform-tls-origination-with-an-egress-gateway)示例中的版本替换 _edition.cnn.com_ 的 `VirtualService`：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  发送之前的三个 HTTP 请求到 _cnn.com_ ， 这一次您应该会收到三个 _200 OK_ 的响应：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    {{< /text >}}

{{< tip >}}
您可能需要等待几秒钟，等待 `VirtualService` 的更新传播到 egress 网关。
{{< /tip >}}

### Mixer 策略检查访问控制

 在该步骤中，您使用 Mixer [`Listchecker` 适配器](/docs/reference/config/policy-and-telemetry/adapters/list/)，它是一种白名单。您可以使用请求的 URL 路径定义一个 `listentry`，并使用一个 `listchecker` 由 `overrides` 字段指定的允许 URL 路径的静态列表检查 `listentry`。对于[外部标识和访问管理](https://en.wikipedia.org/wiki/Identity_management)系统，请使用 `providerurl` 字段。实例、规则和处理程序的更新图如下所示。注意，您重用相同的策略规则 `handle-cn-access` 来进行日志记录和访问策略检查。

{{< image width="80%"
    link="egress-adapters-monitoring-policy.svg"
    caption="用于 egress 监视和访问策略的实例、规则和处理程序"
    >}}

1.  定义 `path-checker` 和 `request-path`：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: path-checker
      namespace: istio-system
    spec:
      overrides: ["/health", "/sport"]  # overrides provide a static list
      blacklist: false
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: request-path
      namespace: istio-system
    spec:
      value: request.path
    EOF
    {{< /text >}}

1.  修改 `handle-cnn-access` 策略规则并发送 `request-path` 实例到 `path-checker`：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    # Rule handle egress access to cnn.com
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-cnn-access
      namespace: istio-system
    spec:
      match: request.host.endsWith(".cnn.com") && context.reporter.uid.startsWith("kubernetes://istio-egressgateway")
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
      - handler: path-checker.listchecker
        instances:
          - request-path.listentry
    EOF
    {{< /text >}}

1.  执行常规测试，将 HTTP 请求发送到[edition.cnn.com/politics](https://edition.cnn.com/politics)， [edition.cnn.com/sport](https://edition.cnn.com/sport) 和 [edition.cnn.com/health](https://edition.cnn.com/health)。正如所料，对 [edition.cnn.com/politics](https://edition.cnn.com/politics) 的请求返回 _403_ （禁止）。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    403
    200
    200
    {{< /text >}}

### Mixer 策略检查访问控制，第二部分

在我们用例中的组织设法配置日志和访问控制之后，它决定扩展它的访问策略，允许具有特殊[服务帐户](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)的应用程序访问 _cnn.com_ 的任何主题，而不受监控。您将看到如何在 Istio 中配置此需求。

1.  使用 `politics` 服务账户开启[sleep]({{< github_tree >}}/samples/sleep) 示例程序。

    {{< text bash >}}
    $  sed 's/: sleep/: politics/g' samples/sleep/sleep.yaml | kubectl create -f -
    serviceaccount "politics" created
    service "politics" created
    deployment "politics" created
    {{< /text >}}

1.  定义 `SOURCE_POD_POLITICS` shell 变量来保存带有 `politics` 服务帐户的源 pod 的名称，以便向外部服务发送请求。

    {{< text bash >}}
    $ export SOURCE_POD_POLITICS=$(kubectl get pod -l app=politics -o jsonpath={.items..metadata.name})
    {{< /text >}}

1.  执行常规测试，这次从 `SOURCE_POD_POLITICS` 发送三个 HTTP 请求。对 [edition.cnn.com/politics](https://edition.cnn.com/politics) 的请求返回 _403_ ，因为您没有为 _politics_ 命名空间配置异常。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD_POLITICS -c politics -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    403
    200
    200
    {{< /text >}}

1.  查询 Mixer 日志，可以看到来自 _politics_ 命名空间的请求信息出现在日志中：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2019-01-29T08:04:42.559812Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":403,"responseSize":84,"sourcePrincipal":"cluster.local/ns/default/sa/politics"}
    {"level":"info","time":"2019-01-29T08:04:42.568424Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2094561,"sourcePrincipal":"cluster.local/ns/default/sa/politics"}
    {"level":"error","time":"2019-01-29T08:04:42.559812Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":403,"responseSize":84,"sourcePrincipal":"cluster.local/ns/default/sa/politics"}
    {"level":"info","time":"2019-01-29T08:04:42.615641Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","reporterUID":"kubernetes://istio-egressgateway-747b6764b8-44rrh.istio-system","responseCode":200,"responseSize":2157009,"sourcePrincipal":"cluster.local/ns/default/sa/politics"}
    {{< /text >}}

    注意 `sourcePrincipal` 是 `cluster.local/ns/default/sa/politics`，表示 `default` 命名空间中的 `politics` 服务帐户。

1.  重新定义 `handle-cn-access` 和 `handl-politics` 策略规则，使 _politics_ 命名空间中的应用程序免受监控和策略强制。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    # Rule to handle access to *.cnn.com/politics
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-politics
      namespace: istio-system
    spec:
      match: request.host.endsWith("cnn.com") && context.reporter.uid.startsWith("kubernetes://istio-egressgateway") && request.path.startsWith("/politics") && source.principal != "cluster.local/ns/default/sa/politics"
      actions:
      - handler: egress-error-logger.stdio
        instances:
        - egress-access.logentry
    ---
    # Rule handle egress access to cnn.com
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-cnn-access
      namespace: istio-system
    spec:
      match: request.host.endsWith(".cnn.com") && context.reporter.uid.startsWith("kubernetes://istio-egressgateway") && source.principal != "cluster.local/ns/default/sa/politics"
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
      - handler: path-checker.listchecker
        instances:
          - request-path.listentry
    EOF
    {{< /text >}}

1.  从 `SOURCE_POD` 中执行常规测试：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    403
    200
    200
    {{< /text >}}

    由于 `SOURCE_POD` 没有 `politics` 服务帐户，所以像以前一样访问[edition.cnn.com/politics](https://edition.cnn.com/politics) 会被禁止。

1.  从 `SOURCE_POD_POLITICS` 中执行之前的测试：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD_POLITICS -c politics -- sh -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    {{< /text >}}

    访问 _edition.cnn.com_ 的所有话题都是被允许的。

1.  检查 Mixer 日志，查看是否有更多使用 `sourcePrincipal` 请求，能够匹配 `cluster.local/ns/default/sa/politics` 的内容出现在日志中。

    {{< text bash >}}
    $  kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep egress-access | grep cnn | tail -4
    {{< /text >}}

## 与 HTTPS egress 流量控制进行比较

在这个用例中，应用程序使用 HTTP 和 Istio Egress 网关为它们执行 TLS 初始化。或者，应用程序可以通过向 _edition.cnn.com_ 发出 HTTPS 请求来发起 TLS 本身。在本节中，我们将描述这两种方法及其优缺点。

在 HTTP 方法中，请求在本地主机上不加密地发送，由 Istio sidecar 代理拦截并转发到 egress 网关。由于您将 Istio 配置为在 sidecar 代理和 egress 网关之间使用相互的 TLS，因此流量会使 pod 加密。egress 网关解密流量，检查 URL 路径、 HTTP 方法和报头，报告遥测数据并执行策略检查。如果请求没有被某些策略检查阻止，那么 egress 网关将执行 TLS 发起到外部目的地（在我们的示例中是 _cnn.com_ ），因此请求将再次加密并发送到外部目的地。下图演示了这种方法的流程。网关内的 HTTP 协议根据解密后网关看到的协议来指定协议。

{{< image width="80%"
link="http-to-gateway.svg"
caption="HTTP egress 流量通过 egress 网关"
>}}

这种方法的缺点是请求在 pod 中发送时没有加密，这可能违反某些组织的安全策略。此外，一些 SDK 具有硬编码的外部服务 URL，包括协议，因此不可能发送 HTTP 请求。这种方法的优点是能够检查 HTTP 方法、头和 URL 路径，并基于它们应用策略。

在 HTTPS 方法中，从应用程序到外部目的地的请求是端到端加密的。下图演示了这种方法的流程。网关中的 HTTPS 协议指定网关所看到的协议。

{{< image width="80%"
link="https-to-gateway.svg"
caption="HTTPS egress 流量通过 egress 网关"
>}}

从安全的角度来看，端到端 HTTPS 被认为是一种更好的方法。然而，由于流量是加密的，Istio 代理和出口网关只能看到源和目标 IP 以及目标的 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)。由于您将 Istio 配置为在 sidecar 代理和 egress 网关之间使用相互的 TLS ，所以[源标识](/zh/docs/concepts/security/#Istio-身份)也是已知的。网关无法检查 URL 路径、HTTP 方法和请求的头，因此无法基于 HTTP 信息进行监控和策略。在我们的用例中，组织将能够允许访问 _edition.cnn.com_ 并指定允许哪些应用程序访问 _edition.cnn.com_ 。但是，将不可能允许或阻止对 _edition.cnn.com_ 的特定URL路径的访问。使用HTTPS方法既不能阻止对 [edition.cnn.com/politics](https://edition.cnn.com/politics) 的访问，也不能监控此类访问。

我们认为，每个组织都应充分考虑这两种方法的优缺点，并选择最适合其需要的方法。

## 总结

 在这篇博客文章中，我们展示了如何将 Istio 的不同监控和策略机制应用于 HTTP egress 流量。可以通过配置日志适配器来实现监控。访问策略可以通过配置 `VirtualServices` 或配置各种策略检查适配器来实现。向您演示了一个只允许特定 URL 路径的简单策略。还向您展示了一个更复杂的策略，通过对具有特定服务帐户的应用程序进行豁免，扩展了简单策略。最后，比较了 HTTP-with-TLS-origination egress 流量与 HTTPS egress 流量，以及通过 Istio 进行控制的可能性。

## 清理

1.  执行[配置 Egress 网关](/zh/docs/examples/advanced-gateways/egress-gateway//)示例的[清理](/zh/docs/examples/advanced-gateways/egress-gateway//#清理)部分中的说明。

1.  删除日志和策略检查配置：

    {{< text bash >}}
    $ kubectl delete logentry egress-access -n istio-system
    $ kubectl delete stdio egress-error-logger -n istio-system
    $ kubectl delete stdio egress-access-logger -n istio-system
    $ kubectl delete rule handle-politics -n istio-system
    $ kubectl delete rule handle-cnn-access -n istio-system
    $ kubectl delete -n istio-system listchecker path-checker
    $ kubectl delete -n istio-system listentry request-path
    {{< /text >}}

1.  删除 _politics_ 源 pod：

    {{< text bash >}}
    $ sed 's/: sleep/: politics/g' samples/sleep/sleep.yaml | kubectl delete -f -
    serviceaccount "politics" deleted
    service "politics" deleted
    deployment "politics" deleted
    {{< /text >}}
