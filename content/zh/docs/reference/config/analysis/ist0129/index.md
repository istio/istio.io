---
title: NoServerCertificateVerificationPortLevel
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当流量策略需要 `caCertificates` 时，但目标规则（Destination Rule）中没有设置相关信息时会出现该错误。

## 示例{#example}

当您的集群中具有以下目标规则（Destination Rule）时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: db-tls
spec:
  host: mydbserver.prod.svc.cluster.local
  trafficPolicy:
    portLevelSettings:
      - port:
          number: 443
        tls:
          mode: SIMPLE
          clientCertificate: /etc/certs/myclientcert.pem
          privateKey: /etc/certs/client_private_key.pem
          sni: my-nginx.mesh-external.svc.cluster.local
          # caCertificates not set
{{< /text >}}

您将会收到以下信息：

{{< text plain >}}
Error [IST0129] (DestinationRule db-tls.default) DestinationRule default/db-tls in namespace default has TLS mode set to SIMPLE but no caCertificates are set to validate server identity for host: mydbserver.prod.svc.cluster.local at port number:443
{{< /text >}}

在这个示例中，目标规则 `db-tls` 被指定为 TLS ，但是没有提供相关 CA 证书。

## 解决方案{#how-to-resolve}

- 提供 CA 证书的文件名
- 修改流量策略为不需要证书的类型
