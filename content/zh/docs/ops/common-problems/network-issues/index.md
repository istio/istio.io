---
title: 流量管理问题
description: 定位常见的 Istio 流量管理和网络问题的技术。
force_inline_toc: true
weight: 10
aliases:
  - /zh/help/ops/traffic-management/troubleshooting
  - /zh/help/ops/troubleshooting/network-issues
  - /zh/docs/ops/troubleshooting/network-issues
owner: istio/wg-networking-maintainers
test: no
---

<!--
title: Traffic Management Problems
description: Techniques to address common Istio traffic management and network problems.
force_inline_toc: true
weight: 10
aliases:
  - /help/ops/traffic-management/troubleshooting
  - /help/ops/troubleshooting/network-issues
  - /docs/ops/troubleshooting/network-issues
owner: istio/wg-networking-maintainers
test: n/a
-->

<!--
## Requests are rejected by Envoy

Requests may be rejected for various reasons. The best way to understand why requests are being rejected is
by inspecting Envoy's access logs. By default, access logs are output to the standard output of the container.
Run the following command to see the log:
-->
## 请求被 Envoy 拒绝{#requests-are-rejected-by-envoy}

请求被拒绝有许多原因。弄明白为什么请求被拒绝的最好方式是检查 Envoy 的访问日志。
默认情况下，访问日志被输出到容器的标准输出中。运行下列命令可以查看日志：

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

<!--
In the default access log format, Envoy response flags are located after the response code,
if you are using a custom log format, make sure to include `%RESPONSE_FLAGS%`.

Refer to the [Envoy response flags](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)
for details of response flags.
-->
在默认的访问日志输出格式中，Envoy 响应标志位于响应状态码之后，
如果您使用自定义日志输出格式，请确保包含 `%RESPONSE_FLAGS%`。

参考 [Envoy 响应标志](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)查看更多有关响应标志的细节。

<!--
Common response flags are:

- `NR`: No route configured, check your `DestinationRule` or `VirtualService`.
- `UO`: Upstream overflow with circuit breaking, check your circuit breaker configuration in `DestinationRule`.
- `UF`: Failed to connect to upstream, if you're using Istio authentication, check for a
[mutual TLS configuration conflict](#503-errors-after-setting-destination-rule).
-->
通用响应标志如下：

- `NR`：没有配置路由，请检查您的 `DestinationRule` 或者 `VirtualService` 配置。
- `UO`：上游溢出导致断路，请在 `DestinationRule` 检查您的熔断器配置。
- `UF`：未能连接到上游，如果您正在使用 Istio 认证，
  请检查[双向 TLS 配置冲突](#service-unavailable-errors-after-setting-destination-rule)。

<!--
## Route rules don't seem to affect traffic flow

With the current Envoy sidecar implementation, up to 100 requests may be required for weighted
version distribution to be observed.
-->
## 路由规则似乎没有对流量生效{#route-rules-dont-seem-to-affect-traffic-flow}

在当前版本的 Envoy Sidecar 实现中，加权版本分发被观测到至少需要 100 个请求。

<!--
If route rules are working perfectly for the [Bookinfo](/docs/examples/bookinfo/) sample,
but similar version routing rules have no effect on your own application, it may be that
your Kubernetes services need to be changed slightly.
Kubernetes services must adhere to certain restrictions in order to take advantage of
Istio's L7 routing features.
Refer to the [Requirements for Pods and Services](/docs/ops/deployment/requirements/)
for details.
-->
如果路由规则在 [Bookinfo](/zh/docs/examples/bookinfo/) 这个例子中完美地运行，
但类似的路由规则在您自己的应用中却没有生效，可能因为您的 Kubernetes Service
需要被稍微地修改。为了利用 Istio 的七层路由特性 Kubernetes Service 必须严格遵守某些限制。
参考 [Pod 和 Service 的要求](/zh/docs/ops/deployment/requirements/)查看详细信息。

<!--
Another potential issue is that the route rules may simply be slow to take effect.
The Istio implementation on Kubernetes utilizes an eventually consistent
algorithm to ensure all Envoy sidecars have the correct configuration
including all route rules. A configuration change will take some time
to propagate to all the sidecars.  With large deployments the
propagation will take longer and there may be a lag time on the
order of seconds.
-->
另一个潜在的问题是路由规则可能只是生效比较慢。在 Kubernetes 上实现的 Istio
利用一个最终一致性算法来保证所有的 Envoy Sidecar 有正确的配置包括所有的路由规则。
一个配置变更需要花一些时间来传播到所有的 Sidecar。
在大型的集群部署中传播将会耗时更长并且可能有几秒钟的延迟时间。

<!--
## 503 errors after setting destination rule
-->
## 设置 destination rule 之后出现 503 异常{#service-unavailable-errors-after-setting-destination-rule}

{{< tip >}}
<!--
You should only see this error if you disabled [automatic mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) during install.
-->
只有在安装期间禁用了 [自动双向 TLS](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-TLS)
时，才会看到此错误。
{{< /tip >}}

<!--
If requests to a service immediately start generating HTTP 503 errors after you applied a `DestinationRule`
and the errors continue until you remove or revert the `DestinationRule`, then the `DestinationRule` is probably
causing a TLS conflict for the service.
-->
如果在您应用了一个 `DestinationRule` 之后请求一个服务立即发生了 HTTP 503
异常，并且这个异常状态一直持续到您移除或回滚了这个 `DestinationRule`，
那么这个 `DestinationRule` 可能导致服务引起了一个 TLS 冲突。

<!--
For example, if you configure mutual TLS in the cluster globally, the `DestinationRule` must include the following `trafficPolicy`:
-->
举个例子，如果在您的集群里配置了全局的 mutual TLS，这个 `DestinationRule`
肯定包含下列的 `trafficPolicy`：

{{< text yaml >}}
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
{{< /text >}}

<!--
Otherwise, the mode defaults to `DISABLE` causing client proxy sidecars to make plain HTTP requests
instead of TLS encrypted requests. Thus, the requests conflict with the server proxy because the server proxy expects
encrypted requests.
-->
否则，这个 TLS mode 默认被设置成 `DISABLE` 会使客户端 Sidecar
代理发起明文 HTTP 请求而不是 TLS 加密了的请求。因此，请求和服务端代理冲突，
因为服务端代理期望的是加密了的请求。

<!--
Whenever you apply a `DestinationRule`, ensure the `trafficPolicy` TLS mode matches the global server configuration.
-->
任何时候您应用一个 `DestinationRule`，请确保 `trafficPolicy` TLS
mode 和全局的配置一致。

<!--
## Route rules have no effect on ingress gateway requests

Let's assume you are using an ingress `Gateway` and corresponding `VirtualService` to access an internal service.
For example, your `VirtualService` looks something like this:
-->
## 路由规则没有对 ingress gateway 请求生效 {#route-rules-have-no-effect-on-ingress-gateway-requests}

假设您正在使用一个 Ingress `Gateway` 和相应的 `VirtualService`
来访问一个内部的服务。举个例子，您的 `VirtualService` 配置可能和如下配置类似：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 或者您正在通过 IP 而不是 DNS 测试 ingress-gateway（例如 http://1.2.3.4/hello），也可以配置成 "*"
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

<!--
You also have a `VirtualService` which routes traffic for the helloworld service to a particular subset:
-->
您还有一个 `VirtualService` 将访问 helloworld 服务的流量路由至该服务的一个特定子集：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
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

<!--
In this situation you will notice that requests to the helloworld service via the ingress gateway will
not be directed to subset v1 but instead will continue to use default round-robin routing.
-->
此时您会发现，通过 ingress 网关访问 helloworld 服务的请求没有直接路由到服务实例子集
v1，而是仍然使用默认的轮询调度路由。

<!--
The ingress requests are using the gateway host (e.g., `myapp.com`)
which will activate the rules in the myapp `VirtualService` that routes to any endpoint of the helloworld service.
Only internal requests with the host `helloworld.default.svc.cluster.local` will use the
helloworld `VirtualService` which directs traffic exclusively to subset v1.

To control the traffic from the gateway, you need to also include the subset rule in the myapp `VirtualService`:
-->
Ingress 请求经由网关主机（如：`myapp.com`）进行路由，网关主机将激活
myapp `VirtualService` 中的规则，将请求路由至 helloworld 服务的任何一个实例端点。
只有通过主机 `helloworld.default.svc.cluster.local` 访问的内部请求才会使用
helloworld `VirtualService`，其中的规则直接将流量路由至服务实例子集 v1。

为了控制从 gateway 过来的流量，您需要在 myapp `VirtualService`
的配置中包含 subset 规则配置：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 或者您正在通过 IP 而不是 DNS 测试 ingress-gateway（例如 http://1.2.3.4/hello），也可以配置成 "*"
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

<!--
Alternatively, you can combine both `VirtualServices` into one unit if possible:
-->
或者，您可以尽可能地将两个 `VirtualService` 配置合并成一个：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # 这里不能使用“*”，因为这是与网格服务关联在一起的。
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # 内部和外部都可以应用
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway # 只对 ingress gateway 严格应用这条规则
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # 应用到网格中的所有服务
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

<!--
## Envoy is crashing under load

Check your `ulimit -a`. Many systems have a 1024 open file descriptor limit by default which will cause Envoy to assert and crash with:
-->
## Envoy 在负载下崩溃{#envoy-is-crashing-under-load}

检查您的 `ulimit -a`。许多系统有一个默认只能有打开 1024 个文件描述符的限制，
它将导致 Envoy 断言失败并崩溃：

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

<!--
Make sure to raise your ulimit. Example: `ulimit -n 16384`

## Envoy won't connect to my HTTP/1.0 service

Envoy requires `HTTP/1.1` or `HTTP/2` traffic for upstream services. For example, when using [NGINX](https://www.nginx.com/) for serving traffic behind Envoy, you
will need to set the [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) directive in your NGINX configuration to be "1.1", since the NGINX default is 1.0.

Example configuration:
-->

请确保增大您的 ulimit。例如: `ulimit -n 16384`

## Envoy 不能连接到 HTTP/1.0 服务{#envoy-wont-connect-to-my-http10-service}

Envoy 要求上游服务使用 `HTTP/1.1` 或者 `HTTP/2` 协议流量。举个例子，当在
Envoy 之后使用 [NGINX](https://www.nginx.com/) 来代理您的流量，您需要在您的 NGINX
配置里将 [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version)
设置为 "1.1"，因为 NGINX 默认的设置是 1.0。

示例配置为：

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

<!--
## 503 error while accessing headless services

Assume Istio is installed with the following configuration:

- `mTLS mode` set to `STRICT` within the mesh
- `meshConfig.outboundTrafficPolicy.mode` set to `ALLOW_ANY`

Consider `nginx` is deployed as a `StatefulSet` in the default namespace and a corresponding `Headless Service` is defined as shown below:
-->
## 访问 Headless Service 时 503 错误{#503-error-while-accessing-headless-services}

假设用以下配置安装 Istio：

- 在网格内 `mTLS mode` 设置为 `STRICT`
- `meshConfig.outboundTrafficPolicy.mode` 设置为 `ALLOW_ANY`

考虑将 `nginx` 部署为 default 命名空间中的一个 `StatefulSet`，
并且参照以下示例来定义相应的 `Headless Service`：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: http-web  # 显式定义一个 http 端口
  clusterIP: None   # 创建一个 Headless Service
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  serviceName: "nginx"
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
{{< /text >}}

<!--
The port name `http-web` in the Service definition explicitly specifies the http protocol for that port.

Let us assume we have a [sleep]({{< github_tree >}}/samples/sleep) pod `Deployment` as well in the default namespace.
When `nginx` is accessed from this `sleep` pod using its Pod IP (this is one of the common ways to access a headless service), the request goes via the `PassthroughCluster` to the server-side, but the sidecar proxy on the server-side fails to find the route entry to `nginx` and fails with `HTTP 503 UC`.
-->
Service 定义中的端口名称 `http-web` 为该端口显式指定 http 协议。

假设在 default 命名空间中也有一个 [sleep]({{< github_tree >}}/samples/sleep)
Pod `Deployment`。当使用 Pod IP（这是访问 Headless Service 的一种常见方式）从这个
`sleep` Pod 访问 `nginx` 时，请求经由 `PassthroughCluster` 到达服务器侧，
但服务器侧的 Sidecar 代理找不到前往 `nginx` 的路由入口，且出现错误 `HTTP 503 UC`。

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
$ kubectl exec -it $SOURCE_POD -c sleep -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
  503
{{< /text >}}

<!--
Here are some of the ways to avoid this 503 error:

1. Specify the correct Host header:

    The Host header in the curl request above will be the Pod IP by default. Specifying the Host header as `nginx.default` in our request to `nginx` successfully returns `HTTP 200 OK`.
-->
`10.1.1.171` 是其中一个 `nginx` 副本的 Pod IP，通过 `containerPort` 80 访问此服务。

以下是避免这个 503 错误的几种方式：

1. 指定正确的 Host 头：

    上述 curl 请求中的 Host 头默认将是 Pod IP。
    在指向 `nginx` 的请求中将 Host 头指定为 `nginx.default`，成功返回 `HTTP 200 OK`。

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

<!--
1. Set port name to `tcp` or `tcp-web` or `tcp-<custom_name>`:

    Here the protocol is explicitly specified as `tcp`. In this case, only the `TCP Proxy` network filter on the sidecar proxy is used both on the client-side and server-side. HTTP Connection Manager is not used at all and therefore, any kind of header is not expected in the request.

    A request to `nginx` with or without explicitly setting the Host header successfully returns `HTTP 200 OK`.

    This is useful in certain scenarios where a client may not be able to include header information in the request.
-->
1. 端口名称设置为 `tcp`、`tcp-web` 或 `tcp-<custom_name>`：

    此例中协议被显式指定为 `tcp`。这种情况下，客户端和服务器都对 Sidecar 代理仅使用 `TCP Proxy` 网络过滤器。
    并未使用 HTTP 连接管理器，因此请求中不应包含任意类型的头。

    无论是否显式设置 Host 头，到 `nginx` 的请求都成功返回 `HTTP 200 OK`。

    这可用于客户端无法在请求中包含头信息的某些场景。

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

<!--
1. Use domain name instead of Pod IP:

    A specific instance of a headless service can also be accessed using just the domain name.
-->
1. 使用域名代替 Pod IP：

     Headless Service 的特定实例也可以仅使用域名进行访问。

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl web-0.nginx.default -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    <!--
    Here `web-0` is the pod name of one of the 3 replicas of `nginx`.
    -->
    此处 `web-0` 是 3 个 `nginx` 副本中其中一个的 Pod 名称。

<!--
Refer to this [traffic routing](/docs/ops/configuration/traffic-management/traffic-routing/) page for some additional information on headless services and traffic routing behavior for different protocols.

## TLS configuration mistakes

Many traffic management problems
are caused by incorrect [TLS configuration](/docs/ops/configuration/traffic-management/tls-configuration/).
The following sections describe some of the most common misconfigurations.
-->
有关针对不同协议的 Headless Service 和流量路由行为的更多信息，
请参阅这个[流量路由](/zh/docs/ops/configuration/traffic-management/traffic-routing/)页面。

## TLS 配置错误{#TLS-configuration-mistakes}

许多流量管理问题是由于错误的 [TLS 配置](/zh/docs/ops/configuration/traffic-management/tls-configuration/)导致的。
以下各节描述了一些最常见的错误配置。

<!--
### Sending HTTPS to an HTTP port

If your application sends an HTTPS request to a service declared to be HTTP,
the Envoy sidecar will attempt to parse the request as HTTP while forwarding the request,
which will fail because the HTTP is unexpectedly encrypted.
-->
### 将 HTTPS 流量发送到 HTTP 端口{#sending-HTTPS-to-an-HTTP-port}

如果您的应用程序向声明为 HTTP 的服务发送 HTTPS 请求，Envoy Sidecar
将在转发请求时尝试将请求解析为 HTTP，这会使 HTTP 被意外加密，从而导致失败。

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
{{< /text >}}

<!--
Although the above configuration may be correct if you are intentionally sending plaintext on port 443 (e.g., `curl http://httpbin.org:443`),
generally port 443 is dedicated for HTTPS traffic.

Sending an HTTPS request like `curl https://httpbin.org`, which defaults to port 443, will result in an error like
`curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.
The access logs may also show an error like `400 DPE`.

To fix this, you should change the port protocol to HTTPS:
-->
虽然如果您有意在端口 443 上发送明文（如，`curl http://httpbin.org:443`），
上述配置可能是正确的，但是一般情况下，443 端口专用于 HTTPS 流量。

发送像 `curl https://httpbin.org` 这样的 HTTPS 请求（默认端口为443）将导致类似于
`curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`
的错误。访问日志也可能显示如 `400 DPE` 的错误。

要解决这个问题，您应该将端口协议改为 HTTPS:

{{< text yaml >}}
spec:
  ports:
  - number: 443
    name: https
    protocol: HTTPS
{{< /text >}}

<!--
### Gateway to virtual service TLS mismatch {#gateway-mismatch}

There are two common TLS mismatches that can occur when binding a virtual service to a gateway.

1. The gateway terminates TLS while the virtual service configures TLS routing.
1. The gateway does TLS passthrough while the virtual service configures HTTP routing.

#### Gateway with TLS termination
-->
### 网关到 `VirtualService` 的 TLS 不匹配{#gateway-mismatch}

将 `VirtualService` 绑定到网关时，可能会发生两种常见的 TLS 不匹配。

1. 网关终止了 TLS，而 `VirtualService` 配置 TLS 路由。
1. 网关启用 TLS 透传，而 `VirtualService` 配置了 HTTP 路由。

#### 网关终止 TLS {#gateway-with-TLS-termination}

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
      - "*"
    tls:
      mode: SIMPLE
      credentialName: sds-credential
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*.example.com"
  gateways:
  - istio-system/gateway
  tls:
  - match:
    - sniHosts:
      - "*.example.com"
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

<!--
In this example, the gateway is terminating TLS while the virtual service is using TLS based routing.
The TLS route rules will have no effect since the TLS is already terminated when the route rules are evaluated.

With this misconfiguration, you will end up getting 404 responses because the requests will be
sent to HTTP routing but there are no HTTP routes configured.
You can confirm this using the `istioctl proxy-config routes` command.

To fix this problem, you should switch the virtual service to specify `http` routing, instead of `tls`:
-->
在此示例中，当 `VirtualService` 使用基于 TLS 的路由时，网关将终止 TLS。
因为在计算路由规则时 TLS 已经终止，所以 TLS 路由规则将无效。

使用这种错误配置，您将最终获得 404 响应，因为请求将发送到 HTTP 路由，但未配置 HTTP 路由。
您可以使用 `istioctl proxy-config routes` 命令确认这一点。

要解决这个问题，您应该将 `VirtualService` 切换为指定 `http` 路由，而不是 `tls`：

{{< text yaml >}}
spec:
  ...
  http:
  - match: ...
{{< /text >}}

<!--
#### Gateway with TLS passthrough
-->
#### 网关启用 TLS 透传 {#gateway-with-TLS-passthrough}

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: virtual-service
spec:
  gateways:
  - gateway
  hosts:
  - httpbin.example.com
  http:
  - route:
    - destination:
        host: httpbin.org
{{< /text >}}

<!--
In this configuration, the virtual service is attempting to match HTTP traffic against TLS traffic passed through the gateway.
This will result in the virtual service configuration having no effect. You can observe that the HTTP route is not applied using
the `istioctl proxy-config listener` and `istioctl proxy-config route` commands.

To fix this, you should switch the virtual service to configure `tls` routing:
-->
在此配置中，`VirtualService` 试图将 HTTP 流量与通过网关的 TLS 流量进行匹配。
这将导致 `VirtualService` 配置无效。您可以使用 `istioctl proxy-config listener`
和 `istioctl proxy-config route` 命令观察到未应用 HTTP 路由。

要解决这个问题，您应该切换 `VirtualService` 以配置 TLS 路由。

{{< text yaml >}}
spec:
  tls:
  - match:
    - sniHosts: ["httpbin.example.com"]
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

<!--
Alternatively, you could terminate TLS, rather than passing it through, by switching the `tls` configuration in the gateway:
-->
另外，您可以通过在网关中切换 `tls` 配置来终止 TLS，而不是透传 TLS：

{{< text yaml >}}
spec:
  ...
    tls:
      credentialName: sds-credential
      mode: SIMPLE
{{< /text >}}

<!--
### Double TLS (TLS origination for a TLS request) {#double-tls}

When configuring Istio to perform {{< gloss >}}TLS origination{{< /gloss >}}, you need to make sure
that the application sends plaintext requests to the sidecar, which will then originate the TLS.

The following `DestinationRule` originates TLS for requests to the `httpbin.org` service,
but the corresponding `ServiceEntry` defines the protocol as HTTPS on port 443.
-->
### 双 TLS（TLS 源发起 TLS 连接）{#double-tls}

将 Istio 配置为执行 {{< gloss >}}TLS origination{{< /gloss >}} 时，
您需要确保应用程序将纯文本请求发送到 Sidecar，Sidecar 将随后发起 TLS。

下述 `DestinationRule` 向 `httpbin.org` 服务发起 TLS 连接，但相应的
`ServiceEntry` 在端口 443 上将协议定义为 HTTPS。

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: originate-tls
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
{{< /text >}}

<!--
With this configuration, the sidecar expects the application to send TLS traffic on port 443
(e.g., `curl https://httpbin.org`), but it will also perform TLS origination before forwarding requests.
This will cause the requests to be double encrypted.

For example, sending a request like `curl https://httpbin.org` will result in an error:
`(35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.

You can fix this example by changing the port protocol in the `ServiceEntry` to HTTP:
-->
使用此配置，Sidecar 期望应用程序在端口 443 上发送 TLS 通信 (如，`curl https://httpbin.org`)，
但它也将在转发请求之前发起 TLS 连接。这将导致对请求进行双重加密。

例如，发送 `curl https://httpbin.org` 之类的请求将导致错误：
`(35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`。

您可以通过将 `ServiceEntry` 中的端口协议更改为 HTTP 来解决此示例：

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
{{< /text >}}

<!--
Note that with this configuration your application will need to send plaintext requests to port 443,
like `curl http://httpbin.org:443`, because TLS origination does not change the port.
However, starting in Istio 1.8, you can expose HTTP port 80 to the application (e.g., `curl http://httpbin.org`)
and then redirect requests to `targetPort` 443 for the TLS origination:
-->
请注意，使用此配置，您的应用程序将需要向端口 443 发送纯文本请求，例如
`curl http://httpbin.org:443`，因为 TLS 连接不会更改端口。
但是，从 Istio 1.8 开始，您可以将 HTTP 端口 80 暴露给应用程序（例如，
`curl http://httpbin.org`），然后将请求重定向到 `targetPort` 443 以用于发起 TLS：

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
{{< /text >}}

<!--
### 404 errors occur when multiple gateways configured with same TLS certificate

Configuring more than one gateway using the same TLS certificate will cause browsers
that leverage [HTTP/2 connection reuse](https://httpwg.org/specs/rfc7540.html#reuse)
(i.e., most browsers) to produce 404 errors when accessing a second host after a
connection to another host has already been established.

For example, let's say you have 2 hosts that share the same TLS certificate like this:
-->
### 当为多个 Gateway 配置了相同的 TLS 证书导致 404 异常{#not-found-errors-occur-when-multiple-gateways-configured-with-same-TLS-certificate}

多个网关配置同一 TLS 证书会导致浏览器在与第一台主机建立连接之后访问第二台主机时利用
[HTTP/2 连接复用](https://httpwg.org/specs/rfc7540.html#reuse)（例如，大部分浏览器）从而导致
404 异常产生。

举个例子，假如您有 2 个主机共用相同的 TLS 证书，如下所示：

<!--
- Wildcard certificate `*.test.com` installed in `istio-ingressgateway`
- `Gateway` configuration `gw1` with host `service1.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `Gateway` configuration `gw2` with host `service2.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw1`
- `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw2`

Since both gateways are served by the same workload (i.e., selector `istio: ingressgateway`) requests to both services
(`service1.test.com` and `service2.test.com`) will resolve to the same IP. If `service1.test.com` is accessed first, it
will return the wildcard certificate (`*.test.com`) indicating that connections to `service2.test.com` can use the same certificate.
Browsers like Chrome and Firefox will consequently reuse the existing connection for requests to `service2.test.com`.
Since the gateway (`gw1`) has no route for `service2.test.com`, it will then return a 404 (Not Found) response.
-->
- 通配证书 `*.test.com` 被安装到 `istio-ingressgateway`
- `Gateway` 将 `gw1` 配置为主机 `service1.test.com`，选择器 `istio: ingressgateway`，
  并且 TLS 使用 gateway 安装的（通配）证书
- `Gateway` 将 `gw2` 配置为主机 `service2.test.com`，选择器 `istio: ingressgateway`，
  并且 TLS 使用 gateway 安装的（通配）证书
- `VirtualService` 将 `vs1` 配置为主机 `service1.test.com` 并且 gateway 配置为 `gw1`
- `VirtualService` 将 `vs2` 配置为主机 `service2.test.com` 并且 gateway 配置为 `gw2`

因为两个网关都由相同的工作负载提供服务（例如，选择器 `istio: ingressgateway`），
到两个服务的请求（`service1.test.com` 和 `service2.test.com`）将会解析为同一 IP。
如果 `service1.test.com` 首先被接受了，它将会返回一个通配证书（`*.test.com`）使得到
`service2.test.com` 的连接也能够使用相同的证书。因此，Chrome 和 Firefox
等浏览器会自动使用已建立的连接来发送到 `service2.test.com` 的请求。因为 gateway（`gw1`）
没有到 `service2.test.com` 的路由信息，它会返回一个 404 (Not Found) 响应。

<!--
You can avoid this problem by configuring a single wildcard `Gateway`, instead of two (`gw1` and `gw2`).
Then, simply bind both `VirtualServices` to it like this:

- `Gateway` configuration `gw` with host `*.test.com`, selector `istio: ingressgateway`, and TLS using gateway's mounted (wildcard) certificate
- `VirtualService` configuration `vs1` with host `service1.test.com` and gateway `gw`
- `VirtualService` configuration `vs2` with host `service2.test.com` and gateway `gw`
-->
您可以通过配置一个单独的通用 `Gateway` 来避免这个问题，而不是两个（`gw1` 和 `gw2`）。
然后，简单地绑定两个 `VirtualService` 到这个单独的网关，比如这样：

- `Gateway` 将 `gw` 配置为主机 `*.test.com`，选择器 `istio: ingressgateway`，
  并且 TLS 使用网关挂载的（通配）证书
- `VirtualService` 将 `vs1` 配置为主机 `service1.test.com` 并且 gateway 配置为 `gw`
- `VirtualService` 将 `vs2` 配置为主机 `service2.test.com` 并且 gateway 配置为 `gw`

<!--
### Configuring SNI routing when not sending SNI

An HTTPS `Gateway` that specifies the `hosts` field will perform an [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) match on incoming requests.
For example, the following configuration would only allow requests that match `*.example.com` in the SNI:
-->
### 不发送 SNI 时配置 SNI 路由{#configuring-SNI-routing-when-not-sending-SNI}

指定 `hosts` 字段的 HTTPS `Gateway` 将对传入请求执行
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 匹配。
例如，以下配置仅允许在 SNI 中匹配 `*.example.com` 的请求：

{{< text yaml >}}
servers:
- port:
    number: 443
    name: https
    protocol: HTTPS
  hosts:
  - "*.example.com"
{{< /text >}}

<!--
This may cause certain requests to fail.

For example, if you do not have DNS set up and are instead directly setting the host header, such as `curl 1.2.3.4 -H "Host: app.example.com"`, no SNI will be set, causing the request to fail.
Instead, you can set up DNS or use the `--resolve` flag of `curl`. See the [Secure Gateways](/docs/tasks/traffic-management/ingress/secure-ingress/) task for more information.

Another common issue is load balancers in front of Istio.
Most cloud load balancers will not forward the SNI, so if you are terminating TLS in your cloud load balancer you may need to do one of the following:

- Configure the cloud load balancer to instead passthrough the TLS connection
- Disable SNI matching in the `Gateway` by setting the hosts field to `*`

A common symptom of this is for the load balancer health checks to succeed while real traffic fails.
-->
这可能会导致某些请求失败。

例如，如果您没有设置 DNS，而是直接设置主机标头，例如 `curl 1.2.3.4 -H "Host: app.example.com"`，
则 SNI 不会被设置，从而导致请求失败。相反，您可以设置 DNS 或使用 `curl` 的 `--resolve` 标志。
有关更多信息，请参见[安全网关](/zh/docs/tasks/traffic-management/ingress/secure-ingress/)。

另一个常见的问题是 Istio 前面的负载均衡器。大多数云负载均衡器不会转发
SNI，因此，如果您要终止云负载均衡器中的 TLS，则可能需要执行以下操作之一：

- 将云负载均衡器改为 TLS 连接方式
- 通过将 hosts 字段设置为 `*` 来禁用 `Gateway` 中的 SNI 匹配

常见的症状是负载均衡器运行状况检查成功，而实际流量失败。

<!--
## Unchanged Envoy filter configuration suddenly stops working

An `EnvoyFilter` configuration that specifies an insert position relative to another filter can be very
fragile because, by default, the order of evaluation is based on the creation time of the filters.
Consider a filter with the following specification:
-->
## 未改动 Envoy 过滤器配置但突然停止工作 {#unchanged-envoy-filter-config-suddently-stops-working}

如果 `EnvoyFilter` 配置指定相对于另一个过滤器的插入位置，这可能非常脆弱，
因为默认情况下评估顺序基于过滤器的创建时间。以一个具有以下 spec 的过滤器为例：

{{< text yaml >}}
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
        ...
{{< /text >}}

<!--
To work properly, this filter configuration depends on the `istio.stats` filter having an older creation time
than it. Otherwise, the `INSERT_BEFORE` operation will be silently ignored. There will be nothing in the
error log to indicate that this filter has not been added to the chain.

This is particularly problematic when matching filters, like `istio.stats`, that are version
specific (i.e., that include the `proxyVersion` field in their match criteria). Such filters may be removed
or replaced by newer ones when upgrading Istio. As a result, an `EnvoyFilter` like the one above may initially
be working perfectly but after upgrading Istio to a newer version it will no longer be included in the network
filter chain of the sidecars.
-->
为了正常工作，这个过滤器配置依赖于创建时间比它早的 `istio.stats` 过滤器。
否则，`INSERT_BEFORE` 操作将被静默忽略。错误日志中将没有任何内容表明此过滤器尚未添加到链中。

这在匹配特定版本（即在匹配条件中包含 `proxyVersion` 字段）的过滤器（例如 `istio.stats`）时尤其成问题。
在升级 Istio 时，这些过滤器可能会被移除或被替换为新的过滤器。
因此，像上面这样的 `EnvoyFilter` 最初可能运行良好，但在将 Istio 升级到新版本后，
它将不再包含在 Sidecar 的网络过滤器链中。

<!--
To avoid this issue, you can either change the operation to one that does not depend on the presence of
another filter (e.g., `INSERT_FIRST`), or set an explicit priority in the `EnvoyFilter` to override the
default creation time-based ordering. For example, adding `priority: 10` to the above filter will ensure
that it is processed after the `istio.stats` filter which has a default priority of 0.
-->
为避免此问题，您可以将操作更改为不依赖于另一个过滤器存在的操作（例如 `INSERT_FIRST`），
或者在 `EnvoyFilter` 中设置显式优先级以覆盖默认的基于创建时间的排序。例如，将 `priority: 10`
添加到上述过滤器将确保它在默认优先级为 0 的 `istio.stats` 过滤器之后被处理。

<!--
## Virtual service with fault injection and retry/timeout policies not working as expected

Currently, Istio does not support configuring fault injections and retry or timeout policies on the
same `VirtualService`. Consider the following configuration:
-->
## 配有故障注入和重试/超时策略的虚拟服务未按预期工作 {#virtual-service-with-fault-injection-and-retry-timeout-policies-not-working-as-expected}

目前，Istio 不支持在同一个 `VirtualService` 上配置故障注入和重试或超时策略。考虑以下配置：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - "*"
  gateways:
  - helloworld-gateway
  http:
  - match:
    - uri:
        exact: /hello
    fault:
      abort:
        httpStatus: 500
        percentage:
          value: 50
    retries:
      attempts: 5
      retryOn: 5xx
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
{{< /text >}}

<!--
You would expect that given the configured five retry attempts, the user would almost never see any
errors when calling the `helloworld` service. However since both fault and retries are configured on
the same `VirtualService`, the retry configuration does not take effect, resulting in a 50% failure
rate. To work around this issue, you may remove the fault config from your `VirtualService` and
inject the fault to the upstream Envoy proxy using `EnvoyFilter` instead:
-->
您期望配置了五次重试尝试时用户在调用 `helloworld` 服务时几乎不会看到任何错误。
但是由于故障和重试都配置在同一个 `VirtualService` 上，所以重试配置未生效，导致 50%
的失败率。要解决此问题，您可以从 `VirtualService` 中移除故障配置，并转为使用
`EnvoyFilter` 将故障注入上游 Envoy 代理：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: hello-world-filter
spec:
  workloadSelector:
    labels:
      app: helloworld
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND # 将匹配所有 Sidecar 中的出站监听器
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.fault
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
          abort:
            http_status: 500
            percentage:
              numerator: 50
              denominator: HUNDRED
{{< /text >}}

<!--
This works because this way the retry policy is configured for the client proxy while the fault
injection is configured for the upstream proxy.
-->
上述这种方式可行，这是因为这种方式为客户端代理配置了重试策略，而为上游代理配置了故障注入。
