---
title: 网络问题排查
description: 常见网络相关问题的识别和处理。
weight: 30
---

本节将介绍一些常用的工具和技能，用于解决流量管理方面的问题。

## 请求被 Envoy 拒绝

要了解拒绝请求的原因，最佳方式是检查 Envoy 的访问日志。默认情况下，访问日志输出到容器的标准输出。
运行以下命令以查看日志：

{{< text bash >}}
$ kubectl logs -it PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

在默认访问日志格式中，Envoy响应标志和 Mixer 策略状态位于响应代码之后，
如果您使用的是自定义日志格式，请确保包含`％RESPONSE_FLAGS％`和`％DYNAMIC_METADATA（istio.mixer：status）％`。

详细的响应标志请参考 [Envoy 响应标志](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#config-access-log-format-response-flags)

常见的响应标志是：

- `NR`: 没有配置路由， 检查你的 `DestinationRule` 或 `VirtualService`。
- `UO`: 上游溢出，熔断， 在 `DestinationRule` 中检查你的熔断器配置。
- `UF`: 无法连接到上游， 如果你正在使用Istio身份验证，请检查
[双向 TLS 配置冲突](#设置目标规则后出现-503-错误)。

如果响应标志为 `UAEX` 且 Mixer 策略状态不是 `-`，则 Mixer 拒绝请求。

通用 Mixer 策略状态为：

- `UNAVAILABLE`: Envoy 无法连接到 Mixer，策略配置为关闭失败。
- `UNAUTHENTICATED`: Mixer 身份验证拒绝该请求。
- `PERMISSION_DENIED`: Mixer 授权拒绝该请求。
- `RESOURCE_EXHAUSTED`: Mixer 配额拒绝该请求。
- `INTERNAL`: 由于 Mixer 内部错误，请求被拒绝。

## 路由规则好像没有生效

在当前版本的 Envoy Sidecar 实现中，可能要 100 个请求才能观察到有权重版本的路由分发过程。

如果一组路由规则能够完美的和 [Bookinfo](/zh/docs/examples/bookinfo/) 配合，但是类似的版本路由功能在其它应用上无法生效，一个可能的解决方法就是对 Kubernetes Service 进行一点改动。Kubernetes Service 的定义必须符合一定规范，才能享受到 Istio 的七层路由特性。应该根据 [Istio 对 Pod 和服务的要求](/zh/docs/setup/kubernetes/additional-setup/requirements)对服务进行调整。

还有个潜在问题就是路由的生效速度很慢。Istio 在 Kubernetes 上实现了一种最终一致性算法，这个算法用于保障所有 Envoy Sidecar 都能够获得正确的配置信息，其中就包含所有的路由规则。配置的变化需要一些时间来传递给所有的 Sidecar。在部署规模很大的情况下，这一传播过程会更长，可能会有数秒的延迟。

## 设置目标规则后出现 503 错误

在应用一个 `DestinationRule` 之后，如果对服务的请求突然开始生成 HTTP 503 错误，并且该错误会一直持续到删除或回滚 `DestinationRule` 为止，那么这个 `DestinationRule` 可能引起了服务的 TLS 冲突。

举个例子来说，如果在集群上启用了全局的双向 TLS，那么 `DestinationRule` 必须包含下面的 `trafficPolicy` 定义：

{{< text yaml >}}
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
{{< /text >}}

这一模式的缺省值是 `DISABLE`，会导致客户端 Sidecar 使用明文 HTTP 请求，而不是 TLS 加密请求；而服务端却又要求接收加密请求，因此就产生了冲突。

可以执行 `istioctl authn tls-check` 命令来检查这一问题，查看该命令的返回内容中的 `STATUS` 字段是否为 `CONFLICT`，例如：

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY     DESTINATION RULE
httpbin.default.svc.cluster.local:8000     CONFLICT     mTLS       HTTP       default/         httpbin/default
{{< /text >}}

不论何时，在应用 `DestinationRule` 时都应该确认 `trafficPolicy` TLS 模式是否符合全局设置的要求。

## 路由规则在 Ingress Gateway 请求中无效

假设要使用 Ingress Gateway，结合 `VirtualService` 来访问一个内部服务。`VirtualService` 看起来大概是这样：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 如果在没有 DNS 的确情况下进行测试，使用 IP 来访问网关，也可以使用“*”
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

另外还有一个 `VirtualService` ，会把发往 `helloworld` 服务的请求路由到某个 `subset`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

这种情况下会注意到，通过 Ingress 网关发出的对 `helloworld` 服务的请求并没有被重定向到 `v1`，而是继续使用缺省的轮询路由。

Ingress 请求使用的是网关定义的主机（例如 `myapp.com`）进行访问的，因此会使用 `myapp` 这个 `VirtualService`，结果就是路由到 `helloworld` 服务的任意端点；只有在网格内部发往主机 `helloworld.default.svc.cluster.local` 的请求才会使用 `helloworld` 这个 `VirtualService`，这个配置的目的就是将流量分配到 `v1`。

要控制来自网关的流量，就需要把引流到 `subset` 的配置写入到 `myapp` 中：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 如果在没有 DNS 的确情况下进行测试，使用 IP 来访问网关，也可以使用“*” (例如 http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

还有一个方式就是把两个 `VirtualService` 合而为一：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # 因为有了网格内的服务主机的定义，这里就不能用 * 了
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # 对内部网关也生效
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway # 限制只对 Ingress 网关的流量有效
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # 对所有网格内服务有效
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## Headless TCP 服务连接丢失

如果部署了 `istio-citadel`，Envoy 会每隔 15 分钟重启一次，来完成证书的刷新任务。这就造成了服务间的长连接以及 TCP 流的中断。

建议提高应用的适应能力，来应对这种断流情况。如果要阻止这种情况的发生，就要禁止双向 TLS 和 `istio-citadel` 的部署。

首先编辑 `istio` 配置来禁止双向 TLS：

{{< text bash >}}
$ kubectl edit configmap -n istio-system istio
$ kubectl delete pods -n istio-system -l istio=pilot
{{< /text >}}

接下来对 `istio-citadel` 进行缩容，来阻止 Envoy 的重启：

{{< text bash >}}
$ kubectl scale --replicas=0 deploy/istio-citadel -n istio-system
{{< /text >}}

这样应该就能阻止 Istio 重启 Envoy，从而防止 TCP 连接的中断。

## Envoy 在高压情况下会崩溃

检查一下 `ulimit -a`，很多系统缺省设置打开文件描述符数量上限为 1024，会导致 Envoy 断言失败引发崩溃：

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

确认提高 ulimit 上限，例如 `ulimit -n 16384`。

## Envoy 无法连接 HTTP/1.0 服务

Envoy 要求上游服务提供 `HTTP/1.1` 或者 `HTTP/2`。例如当使用 [NGINX](https://www.nginx.com/) 在 Envoy 之后提供服务时，就需要在 NGINX 配置文件中设置 [`proxy_http_version`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) 为 `1.1`，否则就会使用缺省值 `1.0`。

配置样例：

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}
