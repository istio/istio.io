---
title: 双向 TLS 的迁移
description: 如何渐进式的为现有 Istio 服务添加双向 TLS 支持。
weight: 80
keywords: [security,authentication,migration]
---

本文任务展示了如何在不中断通信的情况下，把现存 Istio 服务的流量从明文升级为双向 TLS

在实际情况中，集群中可能包含 Istio 服务（注入了 Envoy sidecar）以及非 Istio 服务（没有注入 Envoy sidecar 的服务，下文简称为存量服务）。存量服务无法使用 Istio 签发的密钥/证书来进行双向 TLS 通信。我们希望安全的、渐进的启用双向 TLS。

## 开始之前

* 理解 Istio [认证策略](/zh/docs/concepts/security/#认证策略)以及相关的[双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)概念。

* 已成功在 Kubernetes 集群中部署 Istio，并且没有启用双向 TLS 支持（也就是使用[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)中所说的 `install/kubernetes/istio-demo.yaml` 进行部署，或者在 [Helm 安装](/zh/docs/setup/kubernetes/install/helm/)时设置 `global.mtls.enabled` 的值为 false）。

* 为了演示目的，创建三个命名空间，分别是 `foo`、`bar` 以及 `legacy`，然后在 `foo`、`bar` 中分别部署注入 Istio sidecar 的 [httpbin]({{< github_tree >}}/samples/httpbin) 以及 [sleep]({{< github_tree >}}/samples/sleep) 应用，最后在 `legacy` 命名空间中运行未经注入的 sleep 应用。

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

* 检查部署情况：从任意一个命名空间选一个 sleep pod，发送 http 请求到 `httpbin.foo`。所有的请求都应该能返回 HTTP 200。

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
    sleep.foo to httpbin.foo: 200
    sleep.bar to httpbin.foo: 200
    sleep.legacy to httpbin.foo: 200
    {{< /text >}}

* 确认系统中不存在认证策略和目标规则：

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    No resources found.
    $ kubectl get destinationrule --all-namespaces
    No resources found.
    {{< /text >}}

## 配置服务器使其同时能接收双向 TLS 以及明文流量

在认证策略中有一个 `PERMISSIVE` 模式，这种模式让服务器能够同时接收明文和双向 TLS 流量。下面就把服务器设置为这种模式：

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-permissive"
  namespace: foo
spec:
  targets:
  - name: httpbin
    peers:
  - mtls:
      mode: PERMISSIVE
EOF
{{< /text >}}

接下来再次发送流量到 `httpbin.foo`，确认所有请求依旧成功。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
{{< /text >}}

## 配置客户端进行双向 TLS 通信

利用设置 `DestinationRule` 的方式，让 Istio 服务进行双向 TLS 通信。

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
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

这样一来，`sleep.foo` 和 `sleep.bar` 就会开始使用双向 TLS 和 `httpbin.foo` 进行通信了。而 `sleep.legacy` 因为没有进行 sidecar 注入，因此不受 `DestinationRule` 配置影响，还是会使用明文和 `httpbin.foo` 通信。

现在复查一下，所有到 `httpbin.foo` 的通信是否依旧成功：

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
{{< /text >}}

还可以在 [`DestinationRule`](/zh/docs/reference/config/istio.networking.v1alpha3/#destinationrule) 中指定一个客户端的子集所发出的请求来是用双向 TLS 通信，然后使用 [Grafana](/zh/docs/tasks/telemetry/metrics/using-istio-dashboard/) 验证配置执行情况，确认通过之后，将策略的应用范围扩大到该服务的所有子集。

## 锁定使用双向 TLS (可选)

把所有进行过 sidecar 注入的客户端到服务器流量都迁移到双向 TLS 之后，就可以设置 `httpbin.foo` 只支持双向 TLS 流量了。

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-permissive"
  namespace: foo
spec:
  targets:
  - name: httpbin
    peers:
  - mtls:
      mode: STRICT
EOF
{{< /text >}}

这样设置之后，`sleep.legacy` 的请求就会失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
503
{{< /text >}}

也就是说，如果不能把所有服务都迁移到 Istio (进行 Sidecar 注入)的话，就只能使用 `PERMISSIVE` 模式了。然而在配置为 `PERMISSIVE` 的时候，是不会对明文流量进行授权和鉴权方面的检查的。我们推荐使用 [RBAC](/zh/docs/tasks/security/authz-http/) 来给不同的路径配置不同的授权策略。

## 清理

移除所有资源

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}
