---
title: 授权策略信任域迁移
description: 阐述如何在不更改授权策略的前提下从一个信任域迁移到另一个。
weight: 40
keywords: [security,access-control,rbac,authorization,trust domain, migration]
---

该任务阐述了如何在不更改授权策略的前提下从一个信任域迁移到另一个。

在 Istio 1.4 中，我们引入了一个 alpha 特性以支持授权策略 {{< gloss >}}trust domain migration{{</ gloss >}}。
这意味着如果一个 Istio 网格需要改变它的 {{< gloss >}}trust domain{{</ gloss >}}，其授权策略是不需要手动更新的。
在 Istio 中，如果一个 {{< gloss >}}workload{{</ gloss >}} 运行在命名空间 `foo` 中，服务账户为 `bar`，系统的信任域为 `my-td`，那么该工作负载的身份就是 `spiffe://my-td/ns/foo/sa/bar`。
默认情况下，Istio 网格的信任域是 `cluster.local`，除非您在安装时另外指定了。

## 开始之前{#before-you-begin}

1. 阅读[授权概念指南](/zh/docs/concepts/security/#authorization)。

1. 安装 Istio，自定义信任域，并启用双向 TLS。

    {{< text bash >}}
    $ cat <<EOF > ./td-installation.yaml
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          controlPlaneSecurityEnabled: false
          mtls:
            enabled: true
          trustDomain: old-td
    EOF
    $ istioctl manifest apply --set profile=demo -f td-installation.yaml
    {{< /text >}}

1. 将 [httpbin]({{< github_tree >}}/samples/httpbin) 示例部署于 `default` 命名空间中，将 [sleep]({{< github_tree >}}/samples/sleep) 示例部署于 `default` 和 `sleep-allow` 命名空间中：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl create namespace sleep-allow
    $ kubectl label namespace sleep-allow istio-injection=enabled
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n sleep-allow
    {{< /text >}}

1. 应用如下授权策略以拒绝所有到 `httpbin` 的请求，除了来自 `sleep-allow` 命名空间的 `sleep` 服务。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: service-httpbin.default.svc.cluster.local
      namespace: default
    spec:
      rules:
      - from:
        - source:
            principals:
            - old-td/ns/sleep-allow/sa/sleep
        to:
        - operation:
            methods:
            - GET
      selector:
        matchLabels:
          app: httpbin
    ---
    EOF
    {{< /text >}}

请注意授权策略传播到 sidecars 大约需要几十秒。

1. 验证从以下请求源发送至 `httpbin` 的请求：

    * 来自 `default` 命名空间的 `sleep` 服务的请求被拒绝。

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    * 来自 `sleep-allow` 命名空间的 `sleep` 服务的请求通过了。

    {{< text bash >}}
    $ kubectl exec $(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

## 迁移信任域但不使用别名{#migrate-trust-domain-without-trust-domain-aliases}

1. 使用一个新的信任域安装 Istio。

    {{< text bash >}}
    $ cat <<EOF > ./td-installation.yaml
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          controlPlaneSecurityEnabled: false
          mtls:
            enabled: true
          trustDomain: new-td
    EOF
    $ istioctl manifest apply --set profile=demo -f td-installation.yaml
    {{< /text >}}

    Istio 网格现在运行于一个新的信任域 `new-td` 了。

1. 删除 `default` 和 `sleep-allow` 命名空间中的 `sleep` 和 `httpbin` 的 secrets。请注意如果您安装 Istio 时启用了 SDS，您可以跳过这一步。了解详情请参考[通过 SDS 设置身份](/zh/docs/tasks/security/citadel-config/auth-sds/)。

    {{< text bash >}}
    $ kubectl delete secrets istio.sleep; kubectl delete secrets istio.httpbin;
    {{< /text >}}

    {{< text bash >}}
    $ kubectl delete secrets istio.sleep -n sleep-allow
    {{< /text >}}

1. 重新部署 `httpbin` 和 `sleep` 应用以从新的 Istio 控制平面获取更新。

    {{< text bash >}}
    $ kubectl delete pod --all
    {{< /text >}}

    {{< text bash >}}
    $ kubectl delete pod --all -n sleep-allow
    {{< /text >}}

1. 验证来自 `default` 和 `sleep-allow` 命名空间的 `sleep` 到 `httpbin` 的访问都被拒绝。

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec $(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    这是因为我们指定了一个授权策略，它会拒绝所有到 `httpbin` 的请求，除非请求来源的身份是 `old-td/ns/sleep-allow/sa/sleep`，而这个身份是 `sleep-allow` 命名空间的 `sleep` 的旧身份。
    当我们迁移到一个新的信任域，即 `new-td`，`sleep` 应用的身份就变成 `new-td/ns/sleep-allow/sa/sleep`，与 `old-td/ns/sleep-allow/sa/sleep` 不同。
    因此，`sleep-allow` 命名空间中的 `sleep` 应用之前的请求被放行，但现在被拒绝。
    在 Istio 1.4 之前，修复该问题的唯一方式就是手动调整授权策略。
    而在 Istio 1.4 中，我们引入了一种更简单的方法，如下所示。

## 使用别名迁移信任域{#migrate-trust-domain-with-trust-domain-aliases}

1. 使用一个新的信任域和信任域别名安装 Istio。

    {{< text bash >}}
    $ cat <<EOF > ./td-installation.yaml
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          controlPlaneSecurityEnabled: false
          mtls:
            enabled: true
          trustDomain: new-td
          trustDomainAliases:
            - old-td
    EOF
    $ istioctl manifest apply --set profile=demo -f td-installation.yaml
    {{< /text >}}

1. 不调整授权策略，验证到 `httpbin` 的请求：

    * 来自 `default` 命名空间的 `sleep` 的请求被拒绝。

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    * 来自 `sleep-allow` 命名空间的 `sleep` 通过了。

    {{< text bash >}}
    $ kubectl exec $(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

## 最佳实践{#best-practices}

从 Istio 1.4 起，在编辑授权策略时，您应该在策略中的信任域部分使用 `cluster.local`。
例如，应该是 `cluster.local/ns/sleep-allow/sa/sleep`，而不是 `old-td/ns/sleep-allow/sa/sleep`。
请注意，在这种情况下，`cluster.local` 并不是 Istio 网格的信任域（信任域依然是 `old-td`）。
在策略中，`cluster.local` 是一个指针，指向当前信任域，即 `old-td`（后来是 `new-td`）及其别名。
通过在授权策略中使用 `cluster.local`，当您迁移到新的信任域时，Istio 将检测到此情况，并将新的信任域视为旧的信任域，而无需包含别名。

## 清理{#clean-up}

{{< text bash >}}
$ kubectl delete authorizationpolicy service-httpbin.default.svc.cluster.local
$ kubectl delete deploy httpbin; k delete service httpbin; k delete serviceaccount httpbin
$ kubectl delete deploy sleep; k delete service sleep; k delete serviceaccount sleep
$ kubectl delete namespace sleep-allow
$ istioctl manifest generate --set profile=demo -f td-installation.yaml | kubectl delete -f -
{{< /text >}}
