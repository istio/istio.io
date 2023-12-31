---
title: ExternalNameServiceTypeInvalidPortName
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

对于 ExternalName 类型的服务，当端口不遵循 Istio 服务端口命名协议、端口未命名或端口命名为
TCP 时，会出现此消息。

## 示例 {#example}

当您的集群有以下服务时：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  externalName: nginx.example.com
  ports:
  - name: tcp
    port: 443
    protocol: TCP
    targetPort: 443
  type: ExternalName
{{< /text >}}

您将收到以下信息：

{{< text plain >}}
注意，当 [IST0150] (Service nginx.default) ExternalName 服务的端口名称无效。
将收到代理对以 TCP 命名和服务于 TCP 协议的端口中的不匹配流量的正确转发进行阻止。
{{< /text >}}

在本例中，端口名称 `tcp` 遵循以下语法： `name: <protocol>`。但是，对于
ExternalName 服务，由于没有定义服务 IP，因此需要使用 SNI 字段进行路由。

## 如何修复 {#how-to-resolve}

- 如果您有一个服务类型为 ExternalName 并且服务协议为 TCP，那么将端口重命名为
  `<protocol>[-<suffix>]` 或者 `<protocol>` ，其中协议指的是 `https` 或者 `tls`。
  更多细节请查阅[显式协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)文档。
