---
title: 程序部署文件中的端口命名约定是怎么样的？
weight: 50
---

命名端口：服务端口必须进行命名。

为利用 Istio 的路由功能，端口名称必须是 `protocol-suffix` 形式，其中 `protocol` 可为 `http`、`http2`、`grpc`、`mongo` 或 `redis`。

例如，`name: http2-foo` 或 `name: http` 是有效的端口名称，但 `name:http2foo` 则不是。如果端口名称以不识别的前缀开头，或者端口未命名，则端口上的流量将被视为普通 TCP 流量（除非端口明确指定了使用协议：UDP 表示 UDP 端口）。