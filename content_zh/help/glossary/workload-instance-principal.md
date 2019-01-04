---
title: 工作负载实例主体
---
工作负载实例名是[工作负载实例](#%E5%B7%A5%E4%BD%9C%E8%B4%9F%E8%BD%BD%E5%AE%9E%E4%BE%8B)的可验证权限。Istio 的服务到服务身份验证用于生成工作负载名。在默认情况下，工作负载名符合 SPIFFE ID 格式。

通过访问 `source.principal` 和 `destination.principal` [属性](#%E5%B1%9E%E6%80%A7)，在策略和遥测配置中可以使用工作负载实例主体。
