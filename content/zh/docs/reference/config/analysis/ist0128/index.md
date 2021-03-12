---
title: NoServerCertificateVerificationDestinationLevel
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

如果流量策略需要 `caCertificates`，但是在目标规则（Destination Rule）中没有相关信息，会出现该问题。

## 示例{#example}

当您的集群中包含以下目标规则时（Destination Rule)：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: db-tls
spec:
  host: mydbserver.prod.svc.cluster.local
  trafficPolicy:
    tls:
      mode: SIMPLE
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      # caCertificates not set
{{< /text >}}

您将会收到以下信息：

{{< text plain >}}
Error [IST0128] (DestinationRule db-tls.default) DestinationRule default/db-tls in namespace default has TLS mode set to SIMPLE but no caCertificates are set to validate server identity for host: mydbserver.prod.svc.cluster.local
{{< /text >}}

在这个示例中，目标规则（Destination Rule）`db-tls` 被明确为 TLS，但是没有设置 CA 文件信息。

## 解决方案{#how-to-resolve}

- 提供 CA 证书的文件名
- 修改流量策略为不需要证书的类型
