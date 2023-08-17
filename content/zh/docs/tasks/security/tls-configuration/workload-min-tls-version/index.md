---
title: Istio 工作负载的最低 TLS 版本配置
description: 演示如何为 Istio 工作负载配置最低版本的 TLS。
weight: 90
keywords: [安全,TLS]
aliases:
- /zh/docs/tasks/security/workload-min-tls-version/
owner: istio/wg-security-maintainers
test: yes
---

此任务展示了如何为 Istio 工作负载配置最低版本的 TLS。
Istio 工作负载当前支持的最高 TLS 版本为 1.3。

## 为 Istio 工作负载配置最低版本的 TLS{#configuration-of-minimum-tls-version-for-Istio-workloads}

* 通过 `istioctl` 安装 Istio ，并配置最低版本的 TLS。
  在 `istioctl install` 命令中用于配置 Istio 的 `IstioOperator` 自定义资源的 YAML 配置内，
  包含配置 Istio 工作负载最低 TLS 版本的字段。
  其中的 `minProtocolVersion` 字段用于指定 Istio 工作负载之间 TLS 连接的最低版本。
  在下面的例子中，Istio 工作负载的最低 TLS 版本配置为 1.3。

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        meshMTLS:
          minProtocolVersion: TLSV1_3
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

## 检查 Istio 工作负载的 TLS 配置{#check-the-tls-configuration-of-Istio-workloads}

配置完 Istio 工作负载的最低 TLS 版本后，
您可以验证最低版本的 TLS 是否已配置，并是否按预期工作。

* 部署两个工作负载：`httpbin` 和 `sleep`。并将它们部署到单个的命名空间中，
  例如 `foo`，两个工作负载都在各自服务的前面使用 Envoy 作为流量代理运行。

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* 使用以下命令验证 `sleep` 是否成功地与 `httpbin` 建立通信：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果没有看到预期的输出，请在几秒钟后重试。
缓存和传播可能会导致延迟。
{{< /warning >}}

在示例中，最低 TLS 版本被配置为 1.3。
您可以使用以下命令查看 TLS 1.3 协议是否被允许使用：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_3 -connect httpbin.foo:8000 | grep "TLSv1.3"
{{< /text >}}

文本输出应该包括如下内容:

{{< text plain >}}
TLSv1.3
{{< /text >}}

要检查是否允许 TLS 的 1.2 版本，您可以运行以下命令：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_2 -connect httpbin.foo:8000 | grep "Cipher is (NONE)"
{{< /text >}}

文本输出应该包括如下内容：

{{< text plain >}}
Cipher is (NONE)
{{< /text >}}

## 清理{#cleanup}

从 `foo` 命名空间中删除样例应用 `sleep` 和 `httpbin`：

{{< text bash >}}
$ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
$ kubectl delete -f samples/sleep/sleep.yaml -n foo
{{< /text >}}

从集群中卸载 Istio：

{{< text bash >}}
$ istioctl uninstall --purge -y
{{< /text >}}

移除 `foo` 和 `istio-system` 这两个命名空间：

{{< text bash >}}
$ kubectl delete ns foo istio-system
{{< /text >}}
