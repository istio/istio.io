---
title: TLS Egress 监控和策略配置
description: 描述如何在 TLS Egress 上配置 SNI 监控和策略。
keywords: [traffic-management,egress,telemetry,policies]
weight: 51
aliases:
  - /zh/docs/examples/advanced-gateways/egress_sni_monitoring_and_policies/
---

前面的任务 [使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/) 描述了如何为公共域 `*.wikipedia.org` 中的一组主机启用 Egress 流量，本文基于该任务，
演示如何为 TLS Egress 配置 SNI 监控和策略。

{{< boilerplate before-you-begin-egress >}}

*  [部署 Istio egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway).

*  [开启 Envoy 的访问日志记录](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

*  参考 [使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/) 任务中的 [步骤](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)，配置流量流向 `*.wikipedia.org`，且**启用双向 TLS**。

    {{< warning >}}
    **必须** 在你的集群上启用策略检查。请按照 [启用策略检查](/zh/docs/tasks/policy-enforcement/enabling-policy/)
    中的步骤操作，以确保策略检查已启用 。
    {{< /warning >}}

## SNI 监控和访问策略{#SNI-monitoring-and-access-policies}

由于已将出口流量配置为流经 egress 网关，因此可以 **安全地** 对出口流量应用监控和访问策略检查。
本节中，您将为流向 _*.wikipedia.org_ 的出口流量定义日志条目和访问策略。

1.  创建日志记录配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/telemetry/sni-logging.yaml@
    {{< /text >}}

1.  向 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)
    发送 HTTPS 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  检查 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access'
    {{< /text >}}

1.  定义一个策略，该策略允许访问除 `en.wikipedia.org` 以外的所有 `*.wikipedia.org` 主机：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/policy/sni-wikipedia.yaml@
    {{< /text >}}

1.  向处于黑名单中的 [Wikipedia in English](https://en.wikipedia.org) 发送 https 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

    根据您定义的策略，对 `en.wikipedia.org` 的访问被禁止了。

1.  发送 HTTPS 请求到其它语言版本的 Wikipedia 站点，如 [https://es.wikipedia.org](https://es.wikipedia.org) 和
    [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

    符合预期效果，除 `en.wikipedia.org` 外的 Wikipedia 站点均可被正常访问。

### 清除监控和策略检查{#cleanup-of-monitoring-and-policy-enforcement}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/telemetry/sni-logging.yaml@
$ kubectl delete -f @samples/sleep/policy/sni-wikipedia.yaml@
{{< /text >}}

## 监控 SNI 和源身份标识，并基于它们执行访问策略{#monitor-the-SNI-and-the-source-identity-and-enforce-access-policies-based-on-them}

由于您在 sidecar 代理和 egress 网关之间启用了双向 TLS，因此您可以监控访问外部服务的应用程序的 [服务标识](/zh/docs/ops/deployment/architecture/#citadel)，并根据流量来源的身份标识执行访问策略。
在 Kubernetes 上的 Istio 中，源身份标识基于 [服务帐户](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)。
本小节中，您将在 `sleep-us` 和 `sleep-canada` 服务账户下分别部署 `sleep-us` 和 `sleep-canada` 两个容器。
然后定义一个策略，该策略允许具有 `sleep-us` 标识的应用访问 English 和 Spanish 版本的 Wikipedia 站点，并允许具有 `sleep-canada` 身份标识的应用访问 English 和 French 版本的 Wikipedia 站点。

1.  在 `sleep-us` 和 `sleep-canada` 服务账户下分别部署 `sleep-us` 和 `sleep-canada` 两个容器：

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

1.  创建日志记录配置:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/telemetry/sni-logging.yaml@
    {{< /text >}}

1.  从 `sleep-us` 发送 HTTPS 请求至 English、German、Spanish 和 French 版本的 Wikipedia 站点：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

1.  检查 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access'
    {"level":"info","time":"2019-01-10T17:33:55.559093Z","instance":"egress-access.instance.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"en.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.166227Z","instance":"egress-access.instance.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"de.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.779842Z","instance":"egress-access.instance.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"es.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:57.413908Z","instance":"egress-access.instance.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"fr.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {{< /text >}}

    注意 `requestedServerName` 属性，并且 `sourcePrincipal` 必须为 `cluster.local/ns/default/sa/sleep-us`。

1.  定义一个策略，允许使用服务帐户 `sleep-us` 的应用程序访问 English 和 Spanish 版本的 Wikipedia，
    允许使用服务帐户 `sleep-canada` 的应用程序访问访问 English 和 French 版本的 Wikipedia。
    如果这些应用尝试访问其他语种版本的 Wikipedia，访问将被阻止。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/policy/sni-serviceaccount.yaml@
    {{< /text >}}

1.  再次从 `sleep-us` 发送 HTTPS 请求到 English、German、Spanish 和 French 版本的 Wikipedia：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

    请注意，仅允许 `sleep-us` 服务帐户访问处于白名单中的 Wikipedia 站点，即 English 和 Spanish 版本的 Wikipedia。

    {{< tip >}}
    Mixer 策略组件可能需要几分钟的时间才能完成新策略的同步。如果您想在不等待同步完成的情况下快速演示新策略，请 Mixer 策略 Pod 删除：
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio-mixer-type=policy
    {{< /text >}}

1.  再次从 `sleep-canada` 发送 HTTPS 请求到 English、German、Spanish 和 French 站点：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-canada -o jsonpath='{.items[0].metadata.name}') -c sleep-canada -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

    请注意，只有 `sleep-canada` 服务帐户访问处于白名单中的 Wikipedia 站点，即 English 和 French 版本的 Wikipedia。

### 清理 SNI 及源标识的监控和策略检查{#cleanup-of-monitoring-and-policy-enforcement-of-SNI-and-source-identity}

{{< text bash >}}
$ kubectl delete service sleep-us sleep-canada
$ kubectl delete deployment sleep-us sleep-canada
$ kubectl delete serviceaccount sleep-us sleep-canada
$ kubectl delete -f @samples/sleep/telemetry/sni-logging.yaml@
$ kubectl delete -f @samples/sleep/policy/sni-serviceaccount.yaml@
{{< /text >}}

## 清除{#cleanup}

1.  执行 [使用通配符主机配置 Egress 流量](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/) 任务的 [清除步骤](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#cleanup-wildcard-configuration-for-arbitrary-domains)。

1.  关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}
