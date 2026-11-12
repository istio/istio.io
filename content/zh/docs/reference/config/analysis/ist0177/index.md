---
title: ConflictingServiceEntryProtocol
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当在同一命名空间中可见的两个或多个 `ServiceEntry` 资源定义了相同的主机和端口，
但使用了不同的协议时，会出现此消息。

对于同一主机和端口，Istio 只能使用一种协议。因此，流量可能会使用您预期之外的协议。

## 示例 {#example}

假设有以下两个 `ServiceEntry` 资源：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: api-http
spec:
  hosts:
  - api.example.com
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: api-tls
spec:
  hosts:
  - api.example.com
  ports:
  - number: 443
    name: tls
    protocol: TLS
  resolution: DNS
{{< /text >}}

每个 `ServiceEntry` 都会收到以下消息：

{{< text plain >}}
Warning [IST0177] (ServiceEntry default/api-http) Multiple ServiceEntries (default/api-http, default/api-tls) define the same host "api.example.com" and port 443 with conflicting protocols (HTTP, TLS).
{{< /text >}}

## 如何修复 {#how-to-resolve}

在所有 `ServiceEntry` 资源中为该端口使用相同的协议，或者将该主机放在同一个 `ServiceEntry` 中。
