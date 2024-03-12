---
title: ExternalControlPlaneAddressIsNotAHostname
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当为外部控制平面上的入口网关提供的地址是 IP 地址而不是主机名时，会出现此消息。

## 示例  {#example}

当您的集群具有以下 `ValidatingWebhookConfiguration` 和
`MutatingWebhookConfiguration`（为清楚起见而缩短）时：

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
    url: https://test.com:15017/validate
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
    url: https://999.999.999.999:5100/inject/cluster/your-cluster-name/net/network1
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
Info [IST0164] (MutatingWebhookConfiguration istio-sidecar-injector-external-istiod testing.yml:28) The address (https://999.999.999.999:5100/inject/cluster/your-cluster-name/net/network1) that was provided for the webhook (rev.namespace.sidecar-injector.istio.io) to reach the ingress gateway on the external control plane cluster is an IP address. This is not recommended for a production environment.
{{< /text >}}

## 如何修复 {#how-to-resolve}

不建议在生产环境中为在外部控制平面中运行的入口网关使用
IP 地址而不是主机名。

如果您使用的是生产环境，修复这条信息类消息的方式为：将此地址更改为一个有效的主机名，
将其解析为入口网关的 IP 地址。

有关使用带有 TLS 的公共主机名公开入口网关服务的说明，
请参阅[此处](/zh/docs/setup/install/external-controlplane/#set-up-a-gateway-in-the-external-cluster)。
