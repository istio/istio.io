---
title: Workload Instance Principal
---
工作负载实例主体是[工作负载实例](#workload-instance)的可验证权限。Istio 的服务到服务身份验证用于生成工作负载实例主体。默认情况下，工作负载实例主体与 SPIFFE ID 格式兼容。

在 `policy` 和 `telemetry` 中用到了工作负载实例主体，可以使用 `source.principal` 和 `destination.principal` [属性](#attribute) 查看。
