---
title: 多集群下的故障排除
description: 介绍用来诊断多集群和多网络下安装问题的工具和技术。
weight: 90
keywords: [debug,multicluster,multi-network,envoy]
owner: istio/wg-environments-maintainers
test: no
---

本页介绍如何将 Istio 部署到多个集群和/或多个网络的问题。
开始之前，请确保您已经完成了[多集群安装](/zh/docs/setup/install/multicluster/)
的要求并且已经阅读了[部署模型](/zh/docs/ops/deployment/deployment-models/)指南。

## 跨集群负载均衡  {#cross-cluster-load-balancing}

多网络安装最常见同时也是最广泛的问题是无法实现跨集群负载均衡。
通常表现为仅看到来自服务的集群本地实例（cluster-local instance）的响应：

{{< text bash >}}
$ for i in $(seq 10); do kubectl --context=$CTX_CLUSTER1 -n sample exec sleep-dd98b5f48-djwdw -c sleep -- curl -s helloworld:5000/hello; done
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
...
{{< /text >}}

按照[验证多集群安装](/zh/docs/setup/install/multicluster/verify/)指南操作完毕后，
我们期待同时看到 `v1` 和 `v2` 响应，这表示流量同时到达了两个集群。

造成响应仅来自集群本地实例的原因有很多：

### 连接和防火墙问题  {#connectivity-and-firewall-issues}

在某些环境中，防火墙阻止集群之间的流量可能并不明显。可能出现 `ICMP`（ping）流量成功，
但 HTTP 和其他类型的流量失败的情况。这可能表现为超时，或者在某些情况下表现为更令人困惑的错误，
例如：

{{< text plain >}}
upstream connect error or disconnect/reset before headers. reset reason: local reset, transport failure reason: TLS error: 268435612:SSL routines:OPENSSL_internal:HTTP_REQUEST
{{< /text >}}

虽然 Istio 提供了服务发现功能简化了这个问题，
但如果每个集群中的 Pod 位于没有 Istio 的单个网络上，跨集群流量仍然应该成功。
要排除 TLS/mTLS 问题，您可以使用不带 Istio Sidecar 的 Pod
进行手动测试连通性。

在每个集群中，为此测试创建一个新的命名空间。**不**要启用 Sidecar 注入：

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace uninjected-sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace uninjected-sample
{{< /text >}}

然后部署[验证多集群安装](/zh/docs/setup/install/multicluster/verify/)中使用的应用程序：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
{{< /text >}}

使用 `-o wide` 参数验证 `cluster2` 集群中是否有一个正在运行的 helloworld Pod，
这样我们就可以获得 Pod IP：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" -n uninjected-sample get pod -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
helloworld-v2-54df5f84b-z28p5    1/1     Running   0          43s   10.100.0.1   node-1   <none>           <none>
sleep-557747455f-jdsd8           1/1     Running   0          41s   10.100.0.2   node-2   <none>           <none>
{{< /text >}}

记下 `helloworld` 的 `IP` 地址列。在本例中，它是 `10.100.0.1`：

{{< text bash >}}
$ REMOTE_POD_IP=10.100.0.1
{{< /text >}}

接下来，尝试从 `cluster1` 中的 `sleep` Pod 直接向此 Pod IP 发送流量：

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n uninjected-sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n uninjected-sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS $REMOTE_POD_IP:5000/hello
Hello version: v2, instance: helloworld-v2-54df5f84b-z28p5
{{< /text >}}

正常的情况下，应该只有来自 `helloworld-v2` 的响应。重复这些步骤，
将流量从 `cluster2` 发送到 `cluster1`。

如果成功，则可以排除连接问题。如果失败，则问题的原因可能超出了 Istio 配置的范围。

### 地域负载均衡  {#locality-load-balancing}

[地域负载均衡](/zh/docs/tasks/traffic-management/locality-load-balancing/failover/#configure-locality-failover)
会引导客户端访问最近的服务。如果集群分布于不同地理位置（地区/区域），本地负载均衡将优先选用本地实例提供服务，
这与预期相符。而如果禁用了本地负载均衡或者是集群处于同一地理位置，那就可能还存在其他问题。

### 受信配置  {#trust-configuration}

与集群内通信一样，跨集群通信依赖于代理之间公共的且可信任的根证书颁发机构（root）。
默认情况下 Istio 使用自身单独生成的根证书颁发机构。对于多集群的情况，
我们必须手动配置公共的且可信任的根证书颁发机构。阅读下面的**插入式证书**章节或者参考
[身份和信任模型](/zh/docs/ops/deployment/deployment-models/#identity-and-trust-models)了解更多细节。

**插入式证书**：

您可以通过比较每个集群中的根证书的方式来验证受信配置是否正确：

{{< text bash >}}
$ diff \
   <(kubectl --context="${CTX_CLUSTER1}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}') \
   <(kubectl --context="${CTX_CLUSTER2}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}')
{{< /text >}}

如果根证书不匹配或 Secret 根本不存在，
您可以按照[插件 CA 证书](/zh/docs/tasks/security/cert-management/plugin-ca-cert/)指南进行操作，
确保对每个集群都执行这些步骤。

### 逐步分析  {#step-by-step-diagnosis}

如果您已经阅读了上面的章节，但问题仍没有解决，那么可能需要进行更深入的探讨。

下面这些步骤假定您已经完成了 [HelloWorld 认证](/zh/docs/setup/install/multicluster/verify/)指南，
并且确保 `helloworld` 和 `sleep` 服务已经在每个集群中被正确部署。

针对每个集群，找到 `sleep` 服务对应的 `helloworld` 的 `endpoints`：

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
{{< /text >}}

故障诊断信息因流量来源的集群不同而不同：

{{< tabset category-name="source-cluster" >}}

{{< tab name="Primary cluster" category-value="primary" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.0.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

仅显示一个 `endpoints`，表示控制平面无法从从集群读取 `endpoints`。
验证远程 Secret 是否配置正确。

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* 如果缺失 Secret，则创建一个。
* 如果存在 Secret，则：
    * 查看配置，确保使用集群名作为远程 `kubeconfig` 的数据键（data key）。
    * 如果 Secret 看起来没问题，检查 `istiod` 的日志，以确定是连接还是权限问题导致无法连接远程
      Kubernetes API。该日志可能包括 `Failed to add remote cluster from secret` 信息和对应的错误原因。

{{< /tab >}}

{{< tab name="Remote cluster" category-value="remote" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER2 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.1.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

仅显示一个 `endpoints`，表示控制平面无法从从集群读取 `endpoints`。
验证远程 Secret 是否配置正确。

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* 如果缺失 Secret，则创建一个。
* 如果存在 Secret，且 `endpoints` 是位于**主**集群中的 Pod，则：
    * 查看配置，确保使用集群名作为远程 `kubeconfig` 的数据键（data key）。
    * 如果 Secret 看起来没问题，检查 `istiod` 的日志，以确定是连接问题还是权限问题导致无法连接远程
      Kubernetes API。该日志可能包括 `Failed to add remote cluster from secret` 信息和对应的错误原因。
* 如果存在 Secret，且 `endpoints` 是位于**从**集群中的 Pod，则：
    * 代理正在从从集群 istiod 读取配置。当一个从集群有一个集群内的 istiod 时，它只作用于 Sidecar 注入和 CA 证书管理。
      您可以通过在 `istio-system` 命名空间中查找名为 `istiod-remote` 的 Service 来确认此问题。
      如果缺失，请使用 `values.global.remotePilotAddress` 重新设置。

{{< /tab >}}

{{< tab name="Multi-Network" category-value="multi-primary" >}}

主集群和从集群的步骤仍然适用于多网络，尽管多网络有其他情况：

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.5.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
10.0.6.13:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

多网络中模型中，我们期望其中一个端点 IP 与从集群的东西向网关（east-west gateway）公网
IP 匹配。看到多个 Pod IP 说明存在以下两种情况：

* 无法确定远程网络的网关地址。
* 无法确定客户端 Pod 或服务器端 Pod 的网络。

**无法确定远程网络的网关地址**：

在无法访问的从集群中，检查 Service 是否有外部 IP：

{{< text bash >}}
$ kubectl -n istio-system get service -l "istio=eastwestgateway"
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                                           AGE
istio-eastwestgateway    LoadBalancer   10.8.17.119   <PENDING>        15021:31781/TCP,15443:30498/TCP,15012:30879/TCP,15017:30336/TCP   76m
{{< /text >}}

如果 `EXTERNAL-IP` 卡在 `<PENDING>` 状态, 则说明环境可能不支持 `LoadBalancer` 类型的 Service。
在这种情况下，可能需要自定义 Service 的 `spec.exteralIPs` 部分，手动为网关提供集群外可达的 IP。

如果外部 IP 存在，请检查 `topology.istio.io/network` 标签的值是否正确。如果不正确，
请重新安装网关，并确保在生成脚本上设置 `--network` 标志。

**无法确定客户端 Pod 或服务器端 Pod 的网络**：

在源 Pod 上查看代理元数据。

{{< text bash >}}
$ kubectl get pod $SLEEP_POD_NAME \
  -o jsonpath="{.spec.containers[*].env[?(@.name=='ISTIO_META_NETWORK')].value}"
{{< /text >}}

{{< text bash >}}
$ kubectl get pod $HELLOWORLD_POD_NAME \
  -o jsonpath="{.metadata.labels.topology\.istio\.io/network}"
{{< /text >}}

如果没有设置这两个值中的任何一个，或者值不正确，istiod 可能会将源代理和客户端代理视为在同一网络上，
并发送网络本地端点。如果没有设置，请检查安装过程中是否正确设置了 `values.global.network`
或者是否正确配置了 WebHook 注入。

Istio 通过 Pod 注入的 `topology.istio.io/network` 标签来确定网络。对于没有标签的 Pod，
Istio 将根据系统命名空间的`topology.istio.io/network` 标签来确定网络。

针对每个集群检查网络情况：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get ns istio-system -ojsonpath='{.metadata.labels.topology\.istio\.io/network}'
{{< /text >}}

如果上面的命令没有输出预期的网络名称，则设置标签：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
