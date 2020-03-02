---
title: 术语标准
description: 解释 Istio 文档中使用的术语标准。
weight: 11
aliases:
    - /zh/docs/welcome/contribute/style-guide.html
    - /zh/docs/reference/contribute/style-guide.html
keywords: [contribute, documentation, guide, code-block]
---

为了给我们的用户提供清晰的信息，请在文档中都使用本节中定义的标准术语。

## Service {#service}

避免使用 **service** 这个说法。调查显示不同人对这个词的理解是不一样的。下面的表格展示了对读者更明确和清晰的说法：

| 应该使用                                    | 不要使用
|--------------------------------------------|-----------------------------------------
| Workload A 发送一个请求到 Workload B.         | Service A 发送一个请求到 Service B.
| 当 。。。。。。的时候，新 workload 实例启动了    | 当 。。。。。。的时候，新 service 实例启动了
| 这个应用程序包含 2 个 workload。              | 这个服务包含了 2 个 service。

我们的术语表建立了商定的术语，并给出了避免混淆的定义。

## Envoy {#envoy}

相比 “proxy” 我们更喜欢使用 “Envoy” 这个词，因为它更具体，并且如果在整个文档中都使用一致的术语，更容易让大家理解。

同义词：

- “Envoy sidecar” - 这样说没问题
- “Envoy proxy” - 这样说没问题
- “The Istio proxy” -- 最好避免这样说，除非说的是另外一个可能使用其它代理的高级场景。
- “Sidecar”  -- 大多时候仅限于概念文档中使用
- “Proxy” -- 只有在上下文非常容易理解的时候

相关术语：

- Proxy agent  - 这是一个较小的基础设施组件，应该只出现在低层的详细文档中。它不是专有名词。

## 其它 {#miscellaneous}

|应该使用         | 不要使用
|----------------|------
| addon          | `add-on`
| Bookinfo       | `BookInfo`, `bookinfo`
| certificate    | `cert`
| colocate       | `co-locate`
| configuration  | `config`
| delete         | `kill`
| Kubernetes     | `kubernetes`, `k8s`
| load balancing | `load-balancing`
| Mixer          | `mixer`
| multicluster   | `multi-cluster`
| mutual TLS     | `mtls`
| service mesh   | `Service Mesh`
| sidecar        | `side-car`, `Sidecar`
