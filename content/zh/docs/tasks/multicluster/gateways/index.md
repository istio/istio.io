---
title: 通过网关进行连接的多集群
description: 在一个使用网关进行连接的多集群网格中配置远程服务。
weight: 20
keywords: [kubernetes,multicluster]
aliases:
  - /zh/docs/examples/multicluster/gateways/
---

这个示例展示了如何在[多控制平面拓扑](/docs/concepts/deployment-models/#control-plane-models)的多集群网格中
配置和调用远程服务。为了演示跨集群访问，会在一个集群中使用 [Sleep 服务]({{<github_tree>}}/samples/sleep)调用另一个集群中的 [httpbin 服务]({{<github_tree>}}/samples/httpbin)。

## 开始之前 {#before-you-begin}

* 根据[使用网关连接多控制平面](/zh/docs/setup/kubernetes/install/multicluster/gateways/)的介绍，建立两个 Istio 网格组成的集群环境。

* 用 `kubectl` 的 `--context` 参数来访问两个不同的集群。用下面的命令列出配置文件中的 `context`（上下文）：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* 将配置文件中的上下文名称导出为环境变量：

    {{< text bash >}}
    $ export CTX_CLUSTER1=<cluster1 context name>
    $ export CTX_CLUSTER2=<cluster2 context name>
    {{< /text >}}

## 配置示例服务 {#configure-the-example-services}

1. 在 `cluster1` 中部署 `sleep` 服务：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 namespace foo
    $ kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 在 `cluster2` 中部署 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bar
    $ kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
    $ kubectl apply --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 导出 `cluster2` 的网关地址：

    {{< text bash >}}
    $ export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
        -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
    {{< /text >}}

    这个命令使用了网关的公网 IP，如果条件允许，这里使用 DNS 名称也是可以的

    {{< tip >}}
    如果 `cluster2` 正在一个不支持外部负载均衡的环境下运行，需要使用 nodePort 来完成对网关的访问。可以在[控制 Ingress 流量](/zh/docs/tasks/traffic-management/ingress/#确定使用-node-port-时的-ingress-ip-和端口)一文中，找到获取网关地址和端口的说明。还需要把服务的入口端点用下面的步骤从 15443 更换为对应的 nodePort（也就是 `kubectl --context=$CTX_CLUSTER2 get svc -n istio-system istio-ingressgateway -o=jsonpath='{.spec.ports[?(@.port==15443)].nodePort}'`）。
    {{< /tip >}}

1. 在 `cluster1` 中为 `httpbin` 服务创建 `ServiceEntry`。

    为了让 `cluster1` 中的 `sleep` 能够访问到 `cluster2` 中的 `httpbin`，需要创建一个 `ServiceEntry`。`ServiceEntry` 的主机名称应该是 `<name>.<namespace>.global` 的格式，其中的 `name` 和 `namespace` 代表的是远端服务的名称和命名空间。

    为了让 DNS 为 `*.global` 域的服务进行解析。必须给这些服务提供 IP 地址。

    {{< tip >}}
    （`.global` DNS 域）中的每个服务必须在集群内具有唯一的 IP 地址。
    {{< /tip >}}

    如果这些全局服务具有真实的 VIP，可以直接使用；否则我们推荐使用 loopback 范围内的 `127.0.0.0/8`。这些 IP 在 Pod 之外是不可路由的。在这个例子中我们会使用 `127.255.0.0/16`，这样就不会和一些知名地址例如 `127.0.0.1` 重叠了。对这些 IP 的访问会被 Sidecar 截获，并路由到对应的远程服务之中。

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-bar
    spec:
      hosts:
      # 必须是 name.namespace.global 的形式
      - httpbin.bar.global
      # 把远程集群服务作为网格的一部分。网格中的所有集群都有同样的信任关系。
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      # 在一个集群内，httpbin.bar.global 应该对应唯一的远程服务 IP 地址。
      # 这个地址不需要是可路由的。到这个 IP 的流量会被 Sidecar 截获和路由。
      - 127.255.0.2
      endpoints:
      # 对于 sleep.bar 服务来说，这是一个 Cluster2 中的 Ingress gateway 的可路由地址。
      # 从这个 Sidecar 中发出的流量会被路由到这个地址。
      - address: ${CLUSTER2_GW_ADDR}
        ports:
          http1: 15443 # 不要修改端口值
    EOF
    {{< /text >}}

    上面的配置会把 `cluster1` 中所有到 `httpbin.bar.global` 中**所有端口**的流量使用 mTLS 连接路由到 `<IPofCluster2IngressGateway>:15443`。

    端口 15443 的 Gateway 是一个定义了 SNI 感知的 Envoy，是[开始之前](#before-you-begin)一节中的多集群部署步骤中设置的。进入 15443 端口的流量在对应内部服务的 Pod 中做负载均衡（本例中就是 `cluster` 中的 `httpbin.bar`）。

    {{< warning >}}
    不要为 15443 端口创建 `Gateway` 配置。
    {{< /warning >}}

1. 从 `sleep` 服务中检查对 `httpbin` 的访问：

    {{< text bash >}}
    $ kubectl exec --context=$CTX_CLUSTER1 $(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name}) \
       -n foo -c sleep -- curl httpbin.bar.global:8000/ip
    {{< /text >}}

## 使用 Egress Gateway 向远程集群发送流量 {#send-remote-cluster-traffic-using-egress-gateway}

如果要从 `cluster1` 中使用单独的 Egress Gateway 进行流量路由，而非直接通过 Sidecar 完成。可以用下面的 `ServiceEntry` 定义来替代前一节中的定义：

{{< tip >}}
这里定义的配置不能用于其它非跨集群的 Egress 流量。
{{< /tip >}}

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # 必须是 name.namespace.global 的形式
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  - 127.255.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: 15443 # 不要修改端口值
  - address: istio-egressgateway.istio-system.svc.cluster.local
    ports:
      http1: 15443
EOF
{{< /text >}}

## 为远程服务提供分版本路由 {#version-aware-routing-to-remote-services}

如果远程服务具有多个版本，可以为 `ServiceEntry` 加入一个或多个标签，例如：

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # 必须是 name.namespace.global 这样的形式
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  # 每个服务对 httpbin.bar.global 的解析地址必须是唯一的。
  - 127.255.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    labels:
      version: beta
      some: thing
      foo: bar
    ports:
      http1: 15443 # 不要修改这个端口号
EOF
{{< /text >}}

接下来可以根据[配置请求路由任务](/zh/docs/tasks/traffic-management/request-routing/)中的说明来创建对应的 `VirtualService` 和 `DestinationRule`。`DestinationRule` 使用标签选择器来定义 `httpbin.bar.global` 服务的子集。具体步骤和本地服务是一致的。

## 清理 {#clean-up}

执行下列命令，清理示例服务。

* 清理 `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete --context=$CTX_CLUSTER1 -n foo serviceentry httpbin-bar
    $ kubectl delete --context=$CTX_CLUSTER1 ns foo
    {{< /text >}}

* 清理 `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n bar -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete --context=$CTX_CLUSTER2 ns bar
    {{< /text >}}
