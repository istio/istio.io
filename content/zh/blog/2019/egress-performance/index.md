---
title: Egress gateway 性能测试
description: 评估加入 Egress gateway 对性能造成的影响。
publishdate: 2019-01-31
subtitle: Istio Egress gateway 性能评估
attribution: Jose Nativio, IBM
keywords: [performance,traffic-management,egress,mongo]
target_release: 1.0
---

为了从网格中访问外部服务（本例中使用的是 MongoDB），需要加入 Egress gateway，本次测试的主要目的就是调查这一行为对性能和资源使用造成的影响。在博客[使用外部 MongoDB 服务](/zh/blog/2018/egress-mongo/)中介绍了为外部 MongoDB 配置 Egress gateway 的具体步骤。

本次测试中使用的应用是 Acmeair 的 Java 版，这个应用会模拟一个航空订票系统。在 Istio 的每日构建中会使用该应用来进行性能的回归测试，但是在回归测试过程中，这些应用会使用自己的 Sidecar 来访问外部的 MongoDB，而不是 Egress gateway。

下图描述了目前的 Istio 回归测试过程中，Acmeair 应用的运行方式：

{{< image width="70%"
    link="./acmeair_regpatrol3.png"
    caption="在 Istio 性能回归测试环境中的 Acmeair 基准测试"
    >}}

还有一个差别就是，这一应用和外部数据库使用的是明文的 MongoDB 协议。本文中的第一个变化就是将应用到外部 MongoDB 之间的连接升级为 TLS 模式，以体现更贴近实际情况的场景。

下面会讲到一些从网格中访问外部数据库的具体案例。

## Egress 流量案例{#egress-traffic-cases}

### 案例 1：绕过 Sidecar{#case-1-bypassing-the-sidecar}

在这个案例中，Sidecar 对应用和外部数据库之间的通信不做拦截。这一配置是通过初始化容器中的 `-x` 参数来完成的，将其内容设置为 MongoDB 的 CIDR 即可。这种做法导致 Sidecar 忽略流入/流出指定 IP 地址的流量。举例来说：

        - -x
        - "169.47.232.211/32"

{{< image width="70%"
    link="./case1_sidecar_bypass3.png"
    caption="绕过 Sidecar 和外部 MongoDB 进行通信"
    >}}

### 案例 2：使用 Service Entry，通过 Sidecar 完成访问{#case-2-through-the-sidecar-with-service-entry}

在 Sidecar 已经注入到应用 Pod 之后，这种方式是缺省（访问外部服务）的方式。所有的流量都被 Sidecar 拦截，然后根据配置好的规则路由到目的地，这里所说的目的地也包含了外部服务。下面为 MongoDB 配置一个 `ServiceEntry`。

{{< image width="70%"
    link="./case2_sidecar_passthru3.png"
    caption="Sidecar 拦截对外部 MongoDB 的流量"
    >}}

### 案例 3: Egress gateway{#case-3-egress-gateway}

配置 Egress gateway 以及配套的 Destination rule 和 Virtual service，用于访问 MongoDB。所有进出外部数据库的流量都从 Egress gateway（Envoy）通过。

{{< image width="70%"
    link="./case3_egressgw3.png"
    caption="使用 Egress gateway 访问 MongoDB"
    >}}

### 案例 4：在 Sidecar 和 Egress gateway 之间的双向 TLS{#case-4-mutual-TLS-between-sidecars-and-the-egress-gateway}

这种方式中，在 Sidecar 和 Gateway 之中多出了一个安全层，所以会影响性能。

{{< image width="70%"
    link="./case4_egressgw_mtls3.png"
    caption="在 Sidecar 和 Egress gateway 之间启用双向 TLS"
    >}}

### 案例 5：带有 SNI proxy 的 Egress gateway{#case-5-egress-gateway-with-SNI-proxy}

这个场景中，因为 Envoy 目前存在的一些限制，需要另一个代理来访问通配符域名。这里创建了一个 Nginx 代理，在 Egress gateway Pod 中作为 Sidecar 来使用。

{{< image width="70%"
    link="./case5_egressgw_sni_proxy3.png"
    caption="带有 SNI proxy 的 Egress gateway"
    >}}

## 环境{#environment}

* Istio 版本：1.0.2
* `K8s` 版本：`1.10.5_1517`
* Acmeair 应用：4 个服务（每个服务一个实例），跨服务事务，外部 MongoDB，平均载荷：620 字节。

## 结果{#results}

使用 `Jmeter` 来生成负载，负载包含了一组持续五分钟的访问，每个阶段都会逐步提高客户端数量来发出 http 请求。客户端数量为：1、5、10、20、30、40、50 和 60。

### 吞吐量{#throughput}

下图展示了不同案例中的吞吐量：

{{< image width="75%"
    link="./throughput3.png"
    caption="不同案例中的吞吐量"
    >}}

如图可见，在应用和外部数据库中加入 Sidecar 和 Egress gateway 并没有对性能产生太大影响；但是启用双向 TLS、又加入 SNI 代理之后，吞吐量分别下降了 10% 和 24%。

### 响应时间{#response-time}

在 20 客户端的情况下，我们对不同请求的平均响应时间也进行了记录。下图展示了各个案例中平均、中位数、90%、95% 以及 99% 百分位的响应时间。

{{< image width="75%"
    link="./response_times3.png"
    caption="不同配置中的响应时间"
    >}}

跟吞吐量类似，前面三个案例的响应时间没有很大区别，但是双向 TLS 和 额外的代理造成了明显的延迟。

### CPU 用量{#CPU-utilization}

运行过程中还搜集了所有 Istio 组件以及 Sidecar 的 CPU 使用情况。为了公平起见，用吞吐量对 Istio 的 CPU 用量进行了归一化。下图中展示了这一结果：

{{< image width="75%"
    link="./cpu_usage3.png"
    caption="使用 TPS 进行归一化的 CPU 用量"
    >}}

经过归一化处理之后的 CPU 用量数据表明，Istio 在使用 Egress gateway + SNI 代理的情况下，消耗了更多的 CPU。

## 结论{#conclusion}

在这一系列的测试之中，我们用不同的方式来访问一个启用了 TLS 的 MongoDB 来进行性能对比。Egress gateway 的引用没有对性能和 CPU 消耗的显著影响。但是启用了 Sidecar 和 Egress gateway 之间的双向 TLS 或者为通配符域名使用了额外的 SNI 代理之后，会看到性能降级的现象。
