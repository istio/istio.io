---
title: InvalidExternalControlPlaneConfig
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当为外部控制平面上的入口网关提供的地址无效时，会出现此消息。
该地址可能因多种原因而无效，包括：主机名地址格式错误、
主机名无法通过 DNS 查询解析为 IP 地址或者主机名解析出的 IP 地址数为零。

## 示例  {#example}

当集群的 `ValidatingWebhookConfiguration` 和 `MutatingWebhookConfiguration`
（为清楚起见而缩短）缺少 Webhook URL 时：

{{< text yaml >}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-validator-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url:
  name: rev.validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istiod-default-validator
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com:15017/validate
  failurePolicy: Ignore
  name: validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url:
  failurePolicy: Fail
  name: rev.namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: rev.object.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: object.sidecar-injector.istio.io
{{< /text >}}

您将收到此消息：

{{< text plain >}}
Warning [IST0163] (MutatingWebhookConfiguration istio-sidecar-injector-external-istiod testing.yml:28) The hostname () that was provided for the webhook (rev.namespace.sidecar-injector.istio.io) to reach the ingress gateway on the external control plane cluster is blank. Traffic may not flow properly.
Warning [IST0163] (ValidatingWebhookConfiguration istio-validator-external-istiod testing.yml:1) The hostname () that was provided for the webhook (rev.validation.istio.io) to reach the ingress gateway on the external control plane cluster is blank. Traffic may not flow properly.
{{< /text >}}

当集群的 `ValidatingWebhookConfiguration` 和 `MutatingWebhookConfiguration`
（为清楚起见而缩短）所使用的主机名在 DNS 查询期间无法被解析时：

{{< text yaml >}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-validator-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://thisisnotarealdomainname.com:15017/validate
  name: rev.validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istiod-default-validator
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com:15017/validate
  failurePolicy: Ignore
  name: validation.istio.io

---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector-external-istiod
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: rev.namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: rev.object.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: namespace.sidecar-injector.istio.io
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    url: https://test.com/inject/cluster/your-cluster-name/net/network1
  failurePolicy: Fail
  name: object.sidecar-injector.istio.io
{{< /text >}}

您将收到此消息：

{{< text plain >}}
Warning [IST0163] (ValidatingWebhookConfiguration istio-validator-external-istiod testing.yml:1) The hostname (https://thisisnotarealdomainname.com:15017/validate) that was provided for the webhook (rev.validation.istio.io) to reach the ingress gateway on the external control plane cluster cannot be resolved via a DNS lookup. Traffic may not flow properly.
{{< /text >}}

## 如何修复  {#how-to-resolve}

有多种方法可以解决这些无效配置，具体取决于配置无效的原因。

如果您的 Webhook 配置未定义 URL，
则添加使用主机名的有效 URL 将解决此警告消息。
有关如何执行此操作的说明可以在[此处](/zh/docs/setup/install/external-controlplane/#set-up-the-remote-config-cluster)找到。

如果您的主机名无法通过 DNS 查找解析为 IP 地址，
您可以尝试在本地计算机上运行 `dig <your-hostname>`
来查看是否触发 DNS 解析。如果您的本地计算机可以通过 DNS 查询来解析主机名，
那可能是您的集群不能解析此主机名。任何阻止 DNS 流量的安全规则都可能导致解析查询失败。
新的 DNS 记录可能需要长达 72 小时才能在网络上传播，
具体取决于您的 DNS 提供商和具体配置。

如果您的主机名解析为 0 个 IP 地址，请检查 Webhook URL
是否使用正确的主机名，以及您的 DNS
提供商是否正确地拥有至少一个可供您的主机名解析的 IP 地址。
