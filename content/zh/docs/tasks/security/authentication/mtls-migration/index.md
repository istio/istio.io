---
title: 双向 TLS 迁移
description: 阐述如何将 Istio 服务逐步迁移至双向 TLS 通信模式。
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /zh/docs/tasks/security/mtls-migration/
---

本任务阐述如何将 Istio 服务的请求从明文模式平滑过渡至双向 TLS 模式，并确保在整个迁移过程中不干扰在线流量的正常通信。

针对多服务跨网络通信的应用场景，通常希望逐步将所有服务迁移到 Istio 网格中。如此一来，在迁移过程中，将出现只有部分服务注入了 Envoy sidecar 的情况。对于一个已注入 sidecar 的服务而言，一旦开启服务的双向 TLS 通信模式，那么传统客户端（即：没有 Envoy 的客户端）将无法与之通信，因为这些客户端没有注入 Envoy sidecar 和客户端证书。为了解决这个问题，Istio 认证策略提供了一种 “PERMISSIVE” 模式。当启用 “PERMISSIVE” 模式时，服务可以同时接收 HTTP 和双向 TLS 请求。

这样，便可以将 Istio 服务的通信模式配置为双向 TLS，与此同时，不干扰其与传统服务之间的通信。此外，可以使用
[Grafana dashboard](/zh/docs/tasks/observability/metrics/using-istio-dashboard/) 检查哪些服务仍然向 "PERMISSIVE" 模式的服务发送明文请求，然后选择在这些服务迁移结束后关闭目标服务的 "PERMISSIVE" 模式，将其锁定为只接收双向 TLS 请求。

## 开始之前{#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies) 以及相关的[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication) 概念。

* 准备一个 Kubernetes 集群并部署好 Istio，不要开启全局双向 TLS （如：可以使用[安装步骤](/zh/docs/setup/getting-started)中提供的 demo 配置 profile，或者将安装选项 `global.mtls.enabled` 设置为 false）。

* demo 准备
    * 创建如下命名空间并在其中都部署上 [httpbin]({{< github_tree >}}/samples/httpbin) 和 [sleep]({{< github_tree >}}/samples/sleep)，注入 sidecar。
        * `foo`
        * `bar`

    * 创建如下命名空间并在其中部署 [sleep]({{< github_tree >}}/samples/sleep)，不注入 sidecar
        * `legacy`

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    {{< /text >}}

* （使用 curl 命令）从每个 sleep pod （命名空间为 `foo`， `bar` 或 `legacy`） 分别向 `httpbin.foo` 发送 http 请求。所有请求都应成功响应，返回 HTTP code 200。

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
    sleep.foo to httpbin.foo: 200
    sleep.bar to httpbin.foo: 200
    sleep.legacy to httpbin.foo: 200
    {{< /text >}}

* 验证没有在系统中设置认证策略或目标规则（控制面板除外）：

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    NAMESPACE      NAME                          AGE
    istio-system   grafana-ports-mtls-disabled   3m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    NAMESPACE      NAME              AGE
    istio-system   istio-policy      25m
    istio-system   istio-telemetry   25m
    {{< /text >}}

## 配置客户端发送双向 TLS 请求{#configure-clients-to-send-mutual-TLS-traffic}

设置 `DestinationRule`，配置 Istio 服务发送双向 TLS 请求。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-httpbin-istio-client-mtls"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

`sleep.foo` 和 `sleep.bar` 开始向 `httpbin.foo` 发送双向 TLS 请求。因为 `sleep.legacy` 没有注入 sidecar，`DestinationRule` 不会对其起作用，所以 `sleep.legacy` 仍然向 `httpbin.foo` 发送明文请求。

现在，我们确认一下，所有发送至 `httpbin.foo` 的请求仍会响应成功。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
{{< /text >}}

也可以指定一部分客户端使用 [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/) 中设置的 `ISTIO_MUTUAL` 双向 TLS 通信模式。
检查 [Grafana to monitor](/zh/docs/tasks/observability/metrics/using-istio-dashboard/) 验证设置起效后，再扩大作用范围，最终应用到所有的 Istio 客户端服务。

## 锁定为双向 TLS （可选）{#lock-down-to-mutual-TLS-optional}

当所有客户端服务都成功迁移至 Istio 之后，注入 Envoy sidecar，便可以锁定 `httpbin.foo` 只接收双向 TLS 请求。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-strict"
  namespace: foo
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
      mode: STRICT
EOF
{{< /text >}}

此时，源自 `sleep.legacy` 的请求将响应失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
503
{{< /text >}}

若无法将所有服务迁移至 Istio （注入 Envoy sidecar），则必须开启 `PERMISSIVE` 模式。
然而，开启 `PERMISSIVE` 模式时，系统默认不对明文请求进行认证或授权检查。
推荐使用 [Istio 授权](/zh/docs/tasks/security/authorization/authz-http/) 来为不同的请求路径配置不同的授权策略。

## 清除{#cleanup}

清除所有资源。

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}
