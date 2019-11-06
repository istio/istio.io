---
title: 迁移到双向 TLS
description: 向您展示如何将 Istio 服务逐步迁移到双向 TLS。
weight: 80
keywords: [security,authentication,migration]
---

此任务说明了如何从您已有的 Istio 服务流量中，在不中断实时流量的情况下，从明文传输迁移到双向 TLS。

当大量服务都正在通过网络进行交互通信的场景下，这些服务逐步迁移到 Istio 可能是必须且想要的。
在迁移过程中，有些服务有 Envoy sidecars，而有些则没有。对于有 sidecar 的服务，如果您启用该服务的双向 TLS，
来自遗留客户端（即没有 Envoy 的客户端）的链接将会因为没有 Envoy sidecars 和客户端证书而丢失通信。
为了解决此问题，Istio 认证策略提供了一种"PERMISSIVE"模式来解决这个问题。
一旦启用"PERMISSIVE"模式，服务可以同时使用 HTTP 和双向 TLS 流量。

您可以通过配置 Istio 服务，来发送双向 TLS 流量到遗留服务，这些遗留服务将不会丢失通信。
此外，您可以使用[Grafana仪表板](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)检查哪些服务仍以"PERMISSIVE"模式来发送明文流量，
一旦迁移完成后，可以选择锁定这些服务。

## 开始之前{#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies)和[双向TLS认证](/zh/docs/concepts/security/#mutual-tls-authentication)相关的概念。

* 有一个已经安装了 Istio 的未开启全局双向 TLS 的 Kubernetes 集群（例如，按照如下所述使用演示配置文件，如[安装步骤](/zh/docs/setup/install/kubernetes)，或将`global.mtls.enabled`安装选项设置为 false）。

* 演示
    * 创建如下命名空间，同时使用 sidecar 的方式部署[httpbin]({{< github_tree >}}/samples/httpbin)和[sleep]({{< github_tree >}}/samples/sleep)。
        * `foo`
        * `bar`
    * 创建如下命名空间，同时使用非 sidecar 的方式部署[sleep]({{< github_tree >}}/samples/sleep)。
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

* 通过从任意的 sleep pod（在命名空间`foo`、`bar`或`legacy`中的那些 pod）发送一个 http 请求（使用 curl 命令）到`httpbin.foo`来验证设置。所有请求都应有一个成功的 HTTP code 200 的状态码。

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
    sleep.foo to httpbin.foo: 200
    sleep.bar to httpbin.foo: 200
    sleep.legacy to httpbin.foo: 200
    {{< /text >}}

* 还要验证系统中是否没有身份认证策略或 destination rules （控制平面除外）：

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

## 配置客户端发送双向 TLS 流量{#configure-clients-to-send-mutual-tls-traffic}

通过设置`DestinationRule`来配置 Istio 服务以发送双向 TLS 流量。

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

`sleep.foo`和`sleep.bar`应该将开始发送双向 TLS 流量到`httpbin.foo`。
因为没有配置 sidecar 而导致`DestinationRule`没生效，所以同时`sleep.legacy`仍然发送明文流量到`httpbin.foo`。

现在我们确认所有到`httpbin.foo`的请求都成功。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
{{< /text >}}

您还可以在[`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/)中使用`ISTIO_MUTUAL`双向 TLS 来指定客户端请求的子集。

## 锁定到双向 TLS（可选）{#lock-down-to-mutual-tls-optional}

在将所有客户端迁移到 Istio 服务，注入 Envoy sidecar 之后，我们可以锁定`httpbin.foo`以仅接受双向 TLS 流量。

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

现在您应该看到来自`sleep.legacy`请求失败了。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
503
{{< /text >}}

如果您不能将您所有的服务迁移到 Istio（注入 Envoy sidecar），您不得不保持"PERMISSIVE"模式。
然而，当配置为"PERMISSIVE"模式时，默认情况下将不对明文流量执行任何认证和授权检查。
我们建议您使用[Istio授权](/zh/docs/tasks/security/authz-http/)来配置不同授权策略的不同路径。

## 清除{#cleanup}

移除所有资源。

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}
