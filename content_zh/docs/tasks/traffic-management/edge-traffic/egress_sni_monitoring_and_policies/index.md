---
title: Egress TLS 流量中的 SNI 监控及策略
description: 如何为 Egress TLS 流量配置 SNI 监控并应用策略。
keywords: [traffic-management,egress,telemetry,policies]
weight: 51
aliases:
  - /zh/docs/examples/advanced-gateways/egress_sni_monitoring_and_policies/
---

在[使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/edge-traffic/wildcard-egress-hosts/)示例中描述了为 `*.wikipedia.org` 这样的域名启用 Egress 流量 TLS 支持的方法。本示例中将演示的是如何为 Egress TLS 流量配置 SNI 监控并应用策略。

{{< boilerplate before-you-begin-egress >}}

* [在 Istio 中部署 Egress 网关](/zh/docs/tasks/traffic-management/edge-traffic/egress-gateway/#定义-egress-gateway-并引导-http-流量通过这一网关)

* 根据[使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/edge-traffic/wildcard-egress-hosts/)示例中的[步骤](/zh/docs/tasks/traffic-management/edge-traffic/wildcard-egress-hosts/#任意域名的通配符配置) 为流向 `*.wikipedia.org` 的流量进行配置，启用 TLS 支持。

## SNI 监控和访问策略

通过配置，让 Egress 流量流入 Egress 网关之后，就可以对其实施**安全的**监控和策略管理了。在本节中，会为 `*.wikipedia.org` 定义一个 `LogEntry` 以及访问策略。

1. 创建 `logentry`、`rules` 和 `handlers`：

    {{< text yaml>}}
    $ kubectl apply -f - <<EOF
    # Egress 访问的日志定义
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: egress-access
      namespace: istio-system
    spec:
      severity: '"info"'
      timestamp: context.time | timestamp("2017-01-01T00:00:00Z")
      variables:
        connectionEvent: connection.event | ""
        source: source.labels["app"] | "unknown"
        sourceNamespace: source.namespace | "unknown"
        sourceWorkload: source.workload.name | ""
        sourcePrincipal: source.principal | "unknown"
        requestedServerName: connection.requested_server_name | "unknown"
        destinationApp: destination.labels["app"] | ""
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # 用于访问日志记录的 Handler
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
    # 处理对 *.wikipedia.org 访问的 Rule
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && connection.event == "open"
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
    EOF
    {{< /text >}}

1. 向 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org) 发起 HTTPS 访问：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间，可以用如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'
    {{< /text >}}

1. 定义一条策略，允许访问主机名符合 `*.wikipedia.org` 规则的主机，但是排除英文版：

    {{< text yaml >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org"]  # 用静态列表作为黑名单
      blacklist: true
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: requested-server-name
      namespace: istio-system
    spec:
      value: connection.requested_server_name
    ---
    # 检查对 *.wikipedia.org 的访问
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == ""
      actions:
      - handler: wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    EOF
    {{< /text >}}

1. 向黑名单中的[英文版 Wikipedia](https://en.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

    对英文版 Wikipedia 的访问会被策略拒绝。

1. 向其它 Wikipedia 站点发送 HTTPS 请求，例如 [https://es.wikipedia.org](https://es.wikipedia.org) 或 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

    和我们计划的一样，其它语言的 Wikipedia 站点是可以访问的。

### 清理监控和策略定义

{{< text bash >}}
$ kubectl delete rule handle-wikipedia-access check-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker wikipedia-checker -n istio-system
{{< /text >}}

## 监控 SNI 和源身份，并据此作出访问控制

因为已经在 Sidecar 之间、Sidecar 和 Egress 网关之间启用了双向 TLS，所以就有办法对访问外部的应用的[服务身份](/zh/docs/concepts/what-is-istio/#citadel)进行监控和策略控制了。在 Kubernetes 上运行的 Istio，其身份是建立在 [Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 基础之上的。这一节中将会部署两个 `sleep` 容器，`sleep-us` 和 `sleep-canada`，各自用不同的 Service account 运行。然后定义一个策略，允许 `sleep-us` 的身份访问英文和西班牙文版本的维基百科，而 `sleep-canada` 身份的应用可以访问英文和法文版。

1. 部署两个 `sleep` 容器，`sleep-us` 和 `sleep-canada`，各自使用各自的同名 Service account 运行：

    {{< text bash >}}
    $ sed 's/: sleep/: sleep-us/g' @samples/sleep/sleep.yaml@ | kubectl apply -f -
    $ sed 's/: sleep/: sleep-canada/g' @samples/sleep/sleep.yaml@ | kubectl apply -f -
    serviceaccount "sleep-us" created
    service "sleep-us" created
    deployment "sleep-us" created
    serviceaccount "sleep-canada" created
    service "sleep-canada" created
    deployment "sleep-canada" created
    {{< /text >}}

1. 创建 `logentry`、`rules` 和 `handlers`：

    {{< text yaml >}}
    $ kubectl apply -f - <<EOF
    # Egress 访问的日志定义
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: egress-access
      namespace: istio-system
    spec:
      severity: '"info"'
      timestamp: context.time | timestamp("2017-01-01T00:00:00Z")
      variables:
        connectionEvent: connection.event | ""
        source: source.labels["app"] | "unknown"
        sourceNamespace: source.namespace | "unknown"
        sourceWorkload: source.workload.name | ""
        sourcePrincipal: source.principal | "unknown"
        requestedServerName: connection.requested_server_name | "unknown"
        destinationApp: destination.labels["app"] | ""
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Egress 访问日志的 Handler
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
    # 访问 *.wikipedia.org 时应用的 Rule
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && connection.event == "open"
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
    EOF
    {{< /text >}}

1. 从 `sleep-us` 向英文、德文、西班牙文和法文版本的维基百科分别发送 HTTPS 请求：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

1. 查看 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间，可以使用如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'
    {"level":"info","time":"2019-01-10T17:33:55.559093Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"en.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.166227Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"de.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.779842Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"es.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:57.413908Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"fr.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {{< /text >}}

    注意 `requestedServerName` 属性，以及 `sourcePrincipal`，应取值为 `cluster.local/ns/default/sa/sleep-us`。

1. 定义一条策略，允许 `sleep-us` Service account 访问英文和西班牙版本的维基百科；而 `sleep-canada` 则可以访问英文和法文版本的维基百科。对其它语言的访问会被拦截。

    {{< text yaml >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: requested-server-name
      namespace: istio-system
    spec:
      value: connection.requested_server_name
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: us-wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org", "es.wikipedia.org"]
      blacklist: false
    ---
    # 访问 *.wikipedia.org 时应用的 Rule
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-us-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && source.principal == "cluster.local/ns/default/sa/sleep-us"
      actions:
      - handler: us-wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: canada-wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org", "fr.wikipedia.org"]
      blacklist: false
    ---
    #  访问 *.wikipedia.org 时应用的 Rule
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-canada-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && source.principal == "cluster.local/ns/default/sa/sleep-canada"
      actions:
      - handler: canada-wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    EOF
    {{< /text >}}

1. 从 `sleep-us` 发送 HTTPS 流量到英文、德文、西班牙文和法文版本的维基百科：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

    会看到 `sleep-us` 身份允许访问英文和西班牙版本。

    {{< tip >}}
    Mixer 策略的同步可能会花几分钟，如果想要快速演示新的策略，可以删除 Mixer Policy Pod：
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio-mixer-type=policy
    {{< /text >}}

1. 从 `sleep-canada` 发送 HTTPS 流量到英文、德文、西班牙文和法文版本的维基百科：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-canada -o jsonpath='{.items[0].metadata.name}') -c sleep-canada -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

    会看到 `sleep-us` 身份允许访问英文和法文版本。

### 清理基于 SNI 和源身份的监控和访问策略对象

{{< text bash >}}
$ kubectl delete serviceaccount sleep-us sleep-canada
$ kubectl delete service sleep-us sleep-canada
$ kubectl delete deployment sleep-us sleep-canada
$ kubectl delete rule handle-wikipedia-access check-us-wikipedia-access check-canada-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker us-wikipedia-checker canada-wikipedia-checker -n istio-system
{{< /text >}}

## 清理

1. 执行 [使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/edge-traffic/wildcard-egress-hosts/)例子中的[清理任意域名的通配符配置](/zh/docs/tasks/traffic-management/edge-traffic/wildcard-egress-hosts/#清理任意域名的通配符配置)步骤。

1. 停止 [sleep]({{<github_tree>}}/samples/sleep) 服务：
