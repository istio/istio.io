---
title: 双向 TLS 迁移
description: 阐述如何将 Istio 服务逐步迁移至双向 TLS 通信模式。
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /zh/docs/tasks/security/mtls-migration/
owner: istio/wg-security-maintainers
test: yes
---

本任务阐述如何将 Istio 服务的请求从明文模式平滑过渡至双向
TLS 模式，并确保在整个迁移过程中不干扰在线流量的正常通信。

在调用其他工作负载时，Istio 会自动配置工作负载 sidecar
以使用[双向 TLS](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls)。
默认情况下，Istio 使用 `PERMISSIVE` 模式配置目标工作负载。
当启用 `PERMISSIVE` 模式时，服务可以接受明文和双向 TLS 流量。
为了只允许双向 TLS 流量，需要将配置更改为 `STRICT` 模式。

您可以使用
[Grafana dashboard](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
检查哪些服务仍然向 `PERMISSIVE` 模式的服务发送明文请求，
然后选择在这些服务迁移结束后，将其锁定为只接收双向 TLS 请求。

## 开始之前{#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies)以及相关的[双向 TLS 认证](/zh/docs/concepts/security/#mutual-tls-authentication)概念。

* 阅读[认证策略任务](/zh/docs/tasks/security/authentication/authn-policy)，
  了解如何配置认证策略。

* 有一个安装了 Istio 的 Kubernetes 集群，但没有启用全局双向
  TLS（例如，使用[安装步骤](/zh/docs/setup/getting-started)中描述的 `default` 配置文件）。

在此任务中，您可以通过创建示例工作负载并修改策略以在工作负载之间强制执行
STRICT 双向 TLS 来尝试迁移过程。

## 设置集群{#set-up-the-cluster}

* 创建两个命名空间：`foo` 和 `bar`，并在这两个命名空间上部署
  [httpbin]({{< github_tree >}}/samples/httpbin)、
  [sleep]({{< github_tree >}}/samples/sleep) 和 Sidecar。

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    {{< /text >}}

* 创建另一个命名空间 `legacy`，并在没有 Sidecar 的情况下部署
  [sleep]({{< github_tree >}}/samples/sleep)：

    {{< text bash >}}
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    {{< /text >}}

* （使用 curl 命令）从每个 Sleep Pod（命名空间为 `foo`、`bar` 或 `legacy`）分别向
  `httpbin.foo` 发送 http 请求。所有请求都应成功响应，返回 HTTP code 200。

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
    sleep.foo to httpbin.foo: 200
    sleep.foo to httpbin.bar: 200
    sleep.bar to httpbin.foo: 200
    sleep.bar to httpbin.bar: 200
    sleep.legacy to httpbin.foo: 200
    sleep.legacy to httpbin.bar: 200
    {{< /text >}}

    {{< tip >}}

    如果任何 curl 命令失败，请确保可能干扰 httpbin
    服务请求的现有身份验证策略或目标规则。

    {{< text bash >}}
    $ kubectl get peerauthentication --all-namespaces
    No resources found
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    No resources found
    {{< /text >}}

    {{< /tip >}}

## 通过命名空间锁定到双向 TLS{#lock-down-to-mutual-tls-by-namespace}

当所有客户端服务都成功迁移至 Istio 之后，注入 Envoy sidecar，
便可以锁定 `httpbin.foo` 只接收双向 TLS 请求。

{{< text bash >}}
$ kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

此时，源自 `sleep.legacy` 的请求将响应失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
{{< /text >}}

如果您安装 Istio 时带有参数 `values.global.proxy.privileged=true`，
那么您可以使用 `tcpdump` 来验证流量是否被加密。

{{< text bash >}}
$ kubectl exec -nfoo "$(kubectl get pod -nfoo -lapp=httpbin -ojsonpath={.items..metadata.name})" -c istio-proxy -- sudo tcpdump dst port 80  -A
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
{{< /text >}}

当分别从 `sleep.legacy` 和 `sleep.foo` 发送请求时，
您将在输出中看到纯文本和加密文本。

若无法将所有服务迁移至 Istio （注入 Envoy sidecar），则必须开启 `PERMISSIVE` 模式。
然而，开启 `PERMISSIVE` 模式时，系统默认不对明文请求进行认证或授权检查。
推荐使用 [Istio 授权](/zh/docs/tasks/security/authorization/authz-http/)来为不同的请求路径配置不同的授权策略。

## 锁定整个网格的 mTLS{#lock-down-mutual-TLS-for-the-entire-mesh}

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

现在，`foo` 和 `bar` 命名空间都强制执行仅双向 TLS 流量，
因此您应该会看到来自 `sleep.legacy` 的请求访问两个命名空间的服务都失败了。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
{{< /text >}}

## 清除{#clean-up-the-example}

1. 删除网格范围的身份验证策略。

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    $ kubectl delete peerauthentication -n istio-system default
    {{< /text >}}

1. 删除用于测试的命名空间。

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    Namespaces foo bar legacy deleted.
    {{< /text >}}
