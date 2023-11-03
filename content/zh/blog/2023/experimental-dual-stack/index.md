---
title: "支持双栈 Kubernetes 集群"
description: "对双栈 Kubernetes 集群的实验性支持。"
publishdate: 2023-03-10
attribution: "张怀龙 (Intel)、徐贺杰 (Intel)、丁少君 (Intel)、Jacob Delgado (F5)、蔡迎春 (前 F5)"
keywords: [dual-stack]
---

在过去的一年里，英特尔和 F5 在为 Istio 提供
[Kubernetes 双栈网络](https://kubernetes.io/zh-cn/docs/concepts/services-networking/dual-stack/)的支持中通力合作。

## 背景{#background}

对于 Istio 双栈特性支持的工作花费了比预期更长的时间，而我们也还有很多关于双栈的工作需要继续。
最初这项工作基于 F5 的设计实现展开，由此我们创建了 [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing)，
值得注意的是，在与社区基于此设计文档展开的讨论中，社区表示对此方案在内存和性能方面存在顾虑，
并且希望这些问题能够在 Istio 双栈实现之前解决掉，这也引起了我们对最初设计方案的反思。
最初的设计为了支持双栈特性不得不为 listeners、clusters、routes 和 endpoints 增加重复的 Envoy 配置。
鉴于许多人已经遇到 Envoy 内存和 CPU 消耗问题，社区早期反馈希望我们完全重新评估此方案。
而且许多代理透明地处理出站双栈流量，而不管流量是如何产生的，因此许多社区早期的反馈建议是在
Istio 和 Envoy 中实现相同的行为。

## 重新定义双栈特性的支持{#redefining-dual-stack-support}

社区为原始 RFC 提供的大部分反馈是更改 Envoy 以更好地支持双栈用例，
在 Envoy 内部而不仅仅是在 Istio 中修改。
我们吸取了经验教训和反馈并将其应用到简化的设计中，由此我们创建了一个新的
[RFC](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing)。

## 双栈特性在 Istio 1.17 中的支持{#support-dual-stack-in-istio-1.17}

我们与 Envoy 社区合作解决了众多问题，这也是对 Istio 双栈特性的支持花费了一些时间的原因。
这些问题有：
[matched IP Family for outbound listener](https://github.com/envoyproxy/envoy/issues/16804) 和
[supported multiple addresses per listener](https://github.com/envoyproxy/envoy/issues/11184)。

其中徐贺杰也一直在积极地帮助解决一些悬而未决的问题，此后 Envoy 就能够以一种更聪明的方式选择 endpoints
（参考 Issue：[smarter way to pick endpoints for dual-stack](https://github.com/envoyproxy/envoy/issues/21640)）。
诸如 [enable socket options on multiple addresses](https://github.com/envoyproxy/envoy/pull/23496)
针对 Envoy 的这些改进使得即将到来的 Istio 1.17 中对双栈特性的支持能够落地
（Istio 中对应的修改比如：[extra source addresses on inbound clusters](https://github.com/istio/istio/pull/41618)）。

我们团队所做的关于 Envoy 接口定义更改如下：

1. [Listener addresses](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses)

1. [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig)

对于 Istio 双栈特性支持的实现，这些修改是很重要的，它确保我们能够在 Envoy 的下游和上游连接上得到适当的支持。

我们团队总共已向 Envoy 提交了十多个 PR，其中有多半数 PR 的目的是在 Istio 环境中更容易让 Envoy 采用双栈。

同时，在 Istio 方面，也可以在
[Issue #40394](https://github.com/istio/istio/issues/40394) 中跟踪进度。
因为我们在与 Envoy 社区解决各种双栈支持遇到的问题，所以 Istio 社区方面的进展有所放缓。
尽管如此，我们很高兴地宣布 Istio 1.17 中实现了对双栈特性的实验性支持！

## 使用双栈的快速实验{#a-quick-experiment-using-dual-stack}

{{< tip >}}
如果您想使用 KinD 进行测试，可以使用以下命令设置双栈集群：

{{< text bash >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

{{< /tip >}}
1. 通过以下方式对 Istio 1.17.0+ 启用双栈实验性支持：

    {{< text bash >}}
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_DUAL_STACK: "true"
      values:
        pilot:
          env:
            ISTIO_DUAL_STACK: "true"
    EOF
    {{< /text >}}

1. 创建 3 个命名空间：

    - `dual-stack`：`tcp-echo` 将同时监听 IPv4 和 IPv6 地址。
    - `ipv4`：`tcp-echo` 将仅监听 IPv4 地址。
    - `ipv6`：`tcp-echo` 将仅监听 IPv6 地址。

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. 在所有这些命名空间以及默认命名空间上启用 Sidecar 注入：

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. 在命名空间中创建 `tcp-echo` Deployment：

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f {{< github_file >}}/samples/tcp-echo/tcp-echo-dual-stack.yaml
    $ kubectl apply --namespace ipv4 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv4.yaml
    $ kubectl apply --namespace ipv6 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv6.yaml
    {{< /text >}}

1. 在默认命名空间中创建 `sleep` Deployment：

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

1. 校验流量：

    {{< text bash >}}
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
    hello dualstack
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

现在您可以在自己的环境中试验双栈服务了！

## 监听器和端点的重要变化{#important-changes-to-listeners-and-endpoints}

对于上述实验，您会注意到监听器和路由发生了变化：

{{< text bash >}}
$ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
{{< /text >}}

您会看到监听器现在绑定到多个地址，但仅限于双栈服务。
其他服务只会监听单个 IP 地址。

{{< text json >}}
        "name": "fd00:10:96::f9fc_9000",
        "address": {
            "socketAddress": {
                "address": "fd00:10:96::f9fc",
                "portValue": 9000
            }
        },
        "additionalAddresses": [
            {
                "address": {
                    "socketAddress": {
                        "address": "10.96.106.11",
                        "portValue": 9000
                    }
                }
            }
        ],
{{< /text >}}

虚拟入站地址现在也被配置为监听 `0.0.0.0` 和 `[::]`。

{{< text json >}}
    "name": "virtualInbound",
    "address": {
        "socketAddress": {
            "address": "0.0.0.0",
            "portValue": 15006
        }
    },
    "additionalAddresses": [
        {
            "address": {
                "socketAddress": {
                    "address": "::",
                    "portValue": 15006
                }
            }
        }
    ],
{{< /text >}}

Envoy 的 endpoints 现在配置为同时路由到 IPv4 和 IPv6：

{{< text bash >}}
$ istioctl proxy-config endpoints "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" --port 9000
ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
{{< /text >}}

## 参与其中{#get-involved}

接下来还有很多工作要做，欢迎各位与我们一起完成双栈特性到达 Alpha 状态所需的其他任务。
[详情请看这里](https://github.com/istio/enhancements/blob/master/features/dual-stack-support.md)。

比如，来自英特尔的丁少君和李纯已经就 Ambient 的网络流量重定向功能与社区一起展开工作。
我们希望在后面的 Istio 1.18 Alpha 双栈特性的版本中，Ambient 也能够支持双栈特性。

我们非常欢迎您提出宝贵意见，如果您期待与我们合作请访问我们在
[Istio Slack](https://slack.istio.io/) 中的 **#dual-stack-support** 频道。

感谢为 Istio 双栈特性工作的团队！

- 英特尔：[张怀龙](https://github.com/zhlsunshine)、
  [徐贺杰](https://github.com/soulxu)、
  [丁少君](https://github.com/irisdingbj)
- F5：[Jacob Delgado](https://github.com/jacob-delgado)
- [蔡迎春](https://github.com/ycai-aspen)（前 F5 员工）
