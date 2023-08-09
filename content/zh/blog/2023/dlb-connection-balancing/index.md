---
title: "在 Istio 中使用硬件卸载加速连接负载均衡"
description: "在 Istio 网关中使用 DLB 加速连接负载均衡。"
publishdate: 2023-08-08
attribution: "Loong Dai (Intel); Translated by Michael Yao (DaoCloud)"
keywords: [Istio, DLB, gateways]
---

## 什么是连接负载均衡？ {#what-is-connection-load-balancing}

负载均衡是一种核心网络解决方案，用于在服务器群中分配流量到多台服务器上。
负载均衡器提高了应用程序的可用性和响应性，并防止服务器超载。
每个负载均衡器位于客户设备和后端服务器之间，接收并将传入的请求分发给任何可满足这些请求的可用服务器。

对于一个常见的 Web 服务器，通常会有多个工作进程（处理器或线程）。
如果许多客户端连接到单个工作进程，该工作进程将变得繁忙，并带来长尾延迟，
而其他空闲状态的工作进程则无法运行，影响了 Web 服务器的性能。
连接负载均衡是解决这种情况的方法，也被称为连接均衡。

## Istio 为连接负载均衡做了什么？ {#what-does-istio-do-for-connection-load-balancing}

Istio 使用 Envoy 作为数据平面。

Envoy 提供了一个名为 Exact 连接均衡的连接负载均衡实现。
顾名思义，它在均衡期间会持有一个锁，以使连接计数在工作进程之间几乎完全均衡。
在某种程度上，这个均衡是“几乎”精确的，因为连接可能会并行关闭，从而使计数不正确，
但这应该在下一次接收时得到纠正。这种负载均衡器在接受吞吐量上牺牲了一些精度，
应该在服务网格 gRPC Egress 这类连接数较少且很少循环的情况下使用。

显然，它不适用于入口网关，因为入口网关在短时间内接受数千个连接，锁带来的资源成本会导致吞吐量大幅下降。

现在，Envoy 已经集成了 Intel® Dynamic Load Balancing (Intel®DLB) 连接负载均衡，
以加速在入口网关等高连接数场景中的负载均衡。

## Intel® Dynamic Load Balancing 如何加速 Envoy 中的连接负载均衡 {#how-intel-dlb-accelerate-in-envoy}

Intel DLB 是一个硬件管理的队列和仲裁器系统，连接生产者和消费者。
它是一个 PCI 设备，预期安装在服务器 CPU 的 [Uncore](https://zh.wikipedia.org/wiki/Uncore) 中，
并且可以与运行在核心上的软件交互，也可以与其他设备交互。

Intel DLB 实现了以下负载均衡功能：

- 从软件中卸载队列管理 —— 在存在重要的基于排队成本的情况下有用。
    - 特别适用于多生产者/多消费者场景和将任务批量排队到多个目的地的情况。
    - 在软件中访问共享队列需要使用锁。Intel DLB 实现了无锁访问共享队列。
- 动态的、流感知的负载均衡和重新排序。
    - 确保任务均匀分配并更好地利用 CPU 核心。可以在需要的情况下提供基于流的原子性。
    - 在不丢失报文顺序的情况下，将高带宽流量分布到多个核心中。
    - 更好的确定性，避免过多的排队延迟。
    - 使用更少的 IO 内存占用和节省 DDR 带宽。
- 优先级排队（最多 8 个级别）—— 允许 QOS。
    - 对于延迟敏感的流量，可以实现较低的延迟。
    - 报文中可选的延迟测量。
- 可扩展性
    - 允许动态调整应用程序的大小，无缝缩放。
    - 功耗感知；应用程序可以在负载较轻的情况下将工作进程降低到较低功耗状态。

负载均衡队列有三种类型：

- 无序：适用于多个生产者和消费者。任务的顺序不重要，
  每个任务都分配给负载最小的处理器核心。
- 有序：适用于多个生产者和消费者，任务的顺序很重要。
  当多个任务由多个处理器核心处理时，它们必须按照原始顺序重新排列。
- 原子：适用于多个生产者和消费者，任务按照一定的规则分组。
  这些任务使用相同的资源集进行处理，并且组内任务的顺序很重要。

入口网关被期望尽快地处理尽可能多的数据，因此 Intel DLB 连接负载均衡使用无序队列。

## 如何在 Istio 中使用 Intel DLB 连接负载均衡 {#how-to-use-intel-dlb-in-istio}

在 1.17 版本发布中，Istio 正式支持 Intel DLB 连接负载均衡。

以下步骤展示了如何在 Istio
[入口网关](/zh/docs/tasks/traffic-management/ingress/ingress-control/)中使用
Intel DLB 连接负载均衡，在一个 Kubernetes 集群正常运行的 SPR（Sapphire Rapids）机器上。

### 第 1 步：准备 DLB 环境 {#prepare-dlb-env}

按照 [Intel DLB 驱动程序官网的指示说明](https://www.intel.com/content/www/us/en/download/686372/intel-dynamic-load-balancer.html)安装 Intel DLB 驱动程序。

使用以下命令安装 Intel DLB 设备插件：

{{< text bash >}}
$ kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/dlb_plugin?ref=v0.26.0
{{< /text >}}

有关 Intel DLB 设备插件的更多细节，请参阅
[Intel DLB 设备插件主页](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/dlb#config-connection-balance-dlb)。

您可以查看 Intel DLB 设备资源：

{{< text bash >}}
$ kubectl describe nodes | grep dlb.intel.com/pf
  dlb.intel.com/pf:   2
  dlb.intel.com/pf:   2
...
{{< /text >}}

### 第 2 步：下载 Istio {#download-istio}

在这篇博文中，我们使用 Istio 1.17.2。先下载安装包：

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.17.2 TARGET_ARCH=x86_64 sh -
$ cd istio-1.17.2
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

{{< tip >}}
以下所有操作都将在此目录内进行。
{{< /tip >}}

您可以看到版本是 1.17.2：

{{< text bash >}}
$ istioctl version
no running Istio pods in "istio-system"
1.17.2
{{< /text >}}

### 第 3 步：安装 Istio {#install-istio}

为 Istio 创建一个安装配置，注意我们为入口网关分配了 4 个 CPU 和 1 个 DLB 设备，
并将并发数设置为与 CPU 数量相等的 4。

{{< text bash >}}
$ cat > config.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        overlays:
          - kind: Deployment
            name: istio-ingressgateway
        podAnnotations:
          proxy.istio.io/config: |
            concurrency: 4
        resources:
          requests:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
          limits:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
        hpaSpec:
          maxReplicas: 1
          minReplicas: 1
  values:
    telemetry:
      enabled: false
EOF
{{< /text >}}

使用 `istioctl` 安装：

{{< text bash >}}
$ istioctl install -f config.yaml --set values.gateways.istio-ingressgateway.runAsRoot=true -y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete                                                                                                                                                                                                                                                                       Making this installation the default for injection and validation.

Thank you for installing Istio 1.17.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/hMHGiwZHPU7UQRWe9
{{< /text >}}

### 第 4 步：设置后端服务 {#setup-backend-service}

因为我们想在 Istio 入口网关中使用 DLB 连接负载均衡，所以需要先创建一个后端服务。

我们将使用 Istio 附带的样例 [httpbin]({{< github_tree >}}/release-1.17/samples/httpbin) 进行测试。

{{< text bash >}}
$ kubectl apply -f samples/httpbin/httpbin.yaml
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # 选择器与入口网关 Pod 标签进行匹配。
  # 如果您参照标准文档已使用 Helm 安装了 Istio，此项将为 "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

您现在已经为 httpbin 服务创建了一个包含两个路由规则的虚拟服务配置，
这些路由规则允许针对路径 /status 和 /delay 的流量通过。

gateways 列表指定只有通过 httpbin-gateway 的请求才被允许。
所有其他外部请求将会被拒绝，并返回 404 响应。

### 第 5 步：启用 DLB 连接负载均衡 {#enable-dlb-connection-load-balancing}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: dlb
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: MERGE
      value:
        connection_balance_config:
            extend_balance:
              name: envoy.network.connection_balance.dlb
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.network.connection_balance.dlb.v3alpha.Dlb
EOF
{{< /text >}}

如果您检查入口网关 Pod `istio-ingressgateway-xxxx` 的日志，您将看到类似以下的日志条目：

{{< text bash >}}
$ export POD="$(kubectl get pods -n istio-system | grep gateway | awk '{print $1}')"
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
{{< /text >}}

Envoy 将自动检测并选择 DLB 设备。

### 第 6 步：测试 {#test}

{{< text bash >}}
$ export HOST="<YOUR-HOST-IP>"
$ export PORT="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')"
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

请注意，您可以使用 `-H` 标志将 Host HTTP 头设置为 `httpbin.example.com`，
因为现在您还没有为该主机绑定 DNS，所以只是将请求发送到入口 IP。

您也可以在 `/etc/hosts` 中添加 DNS 绑定并移除 `-H` 标志：

{{< text bash >}}
$ echo "$HOST httpbin.example.com" >> /etc/hosts
$ curl -s -I "http://httpbin.example.com:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

访问还未显式暴露的任何其他 URL，您应看到一个 HTTP 404 错误：

{{< text bash >}}
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/headers"
HTTP/1.1 404 Not Found
...
{{< /text >}}

您可以打开调试日志级别以查看更多 DLB 相关的日志：

{{< text bash >}}
$ istioctl pc log ${POD}.istio-system --level debug
istio-ingressgateway-665fdfbf95-2j8px.istio-system:
active loggers:
  admin: debug
  alternate_protocols_cache: debug
  aws: debug
  assert: debug
  backtrace: debug
...
{{< /text >}}

运行 `curl` 发送一个请求，您将看到类似以下的信息：

{{< text bash >}}
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
2023-05-05T06:37:45.974241Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:269   worker_3 dlb send fd 45 thread=47
2023-05-05T06:37:45.974427Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:286   worker_0 get dlb event 1        thread=46
2023-05-05T06:37:45.974453Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:303   worker_0 dlb recv 45    thread=46
2023-05-05T06:37:45.975215Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:283   worker_0 dlb receive none, skip thread=46
{{< /text >}}

有关 Istio 入口网关的更多细节，请访问
[Istio 入口网关官方文档](/zh/docs/tasks/traffic-management/ingress/ingress-control/)。
