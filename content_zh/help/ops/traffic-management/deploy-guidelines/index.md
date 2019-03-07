---
title: 部署和配置指南
description: 提供特定的部署和配置指南。
weight: 20
---

本节提供了特定的部署或配置指南，以避免网络或流量管理出现问题。

## 在网关中配置多个 TLS 主机

如果您要创建一个 `Gateway`，新的 `Gateway` 与另一个现有 `Gateway` 具备相同 `selector` 配置，并且它们还开放了相同的 HTTPS 端口，这种情况下必须确保它们具有唯一的端口名称。否则，提交时候虽然不会立即看到错误提示，但运行时网关配置中会忽略该配置（重名端口的配置将被忽略）。例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # 使用 istio 默认 ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost.com"
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway2
spec:
  selector:
    istio: ingressgateway # 使用 istio 默认 ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost2.com"
{{< /text >}}

使用此配置，对第二个主机 `myhost2.com` 的请求将失败，因为两个网关端口都具有 `name: https`。
例如，`curl` 请求将产生如下错误消息：

{{< text plain >}}
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to myhost2.com:443
{{< /text >}}

您可以通过检查 Pilot 的日志以查找类似于以下内容的消息来确认是否发生了这种情况：

{{< text bash >}}
$ kubectl logs -n istio-system $(kubectl get pod -l istio=pilot -n istio-system -o jsonpath={.items..metadata.name}) -c discovery | grep "non unique port"
2018-09-14T19:02:31.916960Z info    model   skipping server on gateway mygateway2 port https.443.HTTPS: non unique port name for HTTPS port
{{< /text >}}

要避免此问题，请确保对同一 `protocol: HTTPS` 端口的每次使用都进行唯一命名。
例如，将第二个更改为 `https2`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway2
spec:
  selector:
    istio: ingressgateway # 使用 istio 默认 ingress gateway
  servers:
  - port:
      number: 443
      name: https2
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "myhost2.com"
{{< /text >}}

## 为同一主机名配置多个 `VirtualService` 和 `DestinationRule`

有的情况下可能不方便在单一的 `VirtualService` 或者 `DestinationRule` 资源中定义完整的策略或路由规则。如果能够用渐进的方式，在多个资源中为一个主机名完成定义配置，可能会很有帮助。

从 Istio 1.0.1 开始，添加了一个实验性功能，在**绑定到网关时**对 `VirtualService` 或 `DestinationRule` 进行合并。

例如一个绑定到 Ingress网关的 `VirtualService`，它用主机名对外提供服务，使用基于路径的路由来为多个应用来提供转发服务：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

这种配置的缺点是，任何底层微服务的其他配置（例如路由规则）也需要包含在该配置文件中，
而不是包含在与之相关联并且可能由各个服务团队拥有的单独配置文件中。有关详细信息，
在运维指南中的[“路由规则对 Ingress网关请求中无效”](/zh/help/ops/traffic-management/troubleshooting/#路由规则在-ingress-gateway-请求中无效)一节中提供了介绍。

为了避免这个问题，可能最好将 `myapp.com` 的配置分解为几个 `VirtualService` 片段，每个后端服务一个。例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service1
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service2
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-...
{{< /text >}}

当把第二个和后续的 `VirtualService` 应用到现有主机名上的时候，`istio-pilot` 会将其他路由规则合并到主机的现有配置中。但是，有一些注意事项，使用时必须仔细考虑。

1. 单一 `VirtualService` 中的规则评估顺序是固定的，然而跨资源的情况下就不可预料了。换句话说，在这种碎片化的配置之中，规则的评估顺序是没有保障的，因此应该对分片资源进行预测，防止其中出现冲突或者顺序依赖，这样才能保障工作正常进行。

1. 多个配置片段中，应该只有一个“全部捕获”规则（即，匹配任何请求路径或 Header 的规则）。配置合并时，所有这些“全部捕获”规则会被移动到列表的末尾。（如果这类规则不止一个）由于它们会匹配所有请求，所以最先应用的规则会覆盖和禁用其它所有的同类规则

1. Sidecar 不支持主机合并，只有绑定到网关支持 `VirtualService` 分段方式。

`DestinationRule` 也可以使用类似的合并语义和限制进行分段。

1. 对于同一主机，跨多个目标规则应该只有一个给定子集的定义。如果存在多个具有相同名称的定义，则使用第一个定义，其他重复项将失效。不支持合并子集内容。

1. 对于同一主机，应该只有一个顶级的 `trafficPolicy`。在多个目标规则中定义顶级流量策略时，将使用第一个。任何其它的顶级 `trafficPolicy` 配置都将失效。

1. 不同于 `VirtualService` 的合并，目标规则合并在 Sidecar 和网关中都有效。

## 重新配置服务路由后，如何避免 503 错误

为了将流量转发到服务的特定版本（子集），在配置对应的路由规则时，必须注意在路由投入使用之前，确保子集已经可用。否则对服务的调用就会返回 503 错误。

使用 `kubectl` 命令一次性的创建 `VirtualService` 和 `DestinationRule` 的方式（例如 `kubectl apply -f myVirtualServiceAndDestinationRule.yaml`）无法避免这类错误，这是因为资源对象的传播（从配置服务器，例如 Kubernetes API Server）过程是最终一致的方式。如果引用子集的 `VirtualService`，先于 `DestinationRule` 完成传播，那么 Pilot 生成的 Envoy 配置中，就会出现上游服务不存在的故障。因此会出现 503 错误，直到所有配置对象都成功完成传播。

在配置引用子集的 `VirtualService` 时，如果想要避免发生服务中断，应遵循下列流程，保证中断之前完成配置即可：

- 在加入新的子集时：

    1. 在更新相关的 `VirtualService` 之前，首先更新 `DestinationRules`，在其中加入新的子集。用 `kubectl` 或其他平台的特定方式来应用规则。

    1. 等候几秒钟，让 `DestinationRule` 配置传播给 Envoy sidecar。

    1. 更新 `VirtualService`，允许其引用新加入的子集。

- 删除子集时：

    1. 在从 `DestinationRule` 中删除子集之前，首先要更新 `VirtualServices`，移除其中对待删除子集的引用。

    1. 等待几秒钟，以便 `VirtualService` 配置传播至 Envoy sidecar。

    1. 在 `DestinationRule` 中删除无用的子集。

## 多个网关共用同一个 TLS 证书时引起浏览器问题

使用同一个 TLS 证书配置多于一个网关时，如果使用支持 [HTTP/2 连接复用](https://httpwg.org/specs/rfc7540.html#reuse)的浏览器（多数浏览器都支持这一能力）来进行访问，在和第一个主机名建立连接之后，如果继续访问另一个主机名，就会出现 404 错误。

举个例子，假设有两个主机用这种方式来共享同样的 TLS 证书：

- 安装在 `istio-ingressgateway` 上的通配符证书：`*.test.com`

- 一个命名为 `gw1` 的 `Gateway` 对象，其主机名是 `service1.test.com`，`selector` 定义为 `istio: ingressgateway`，使用网关加载的证书来进行 TLS 认证

- 一个命名为 `gw2` 的 `Gateway` 对象，其主机名是 `service2.test.com`，`selector` 定义为 `istio: ingressgateway`，使用网关加载的证书来进行 TLS 认证

- 名为 `vs1` 的 `VirtaulService` 对象，主机名为 `service1.test.com`，网关设置为 `gw1`

- 名为 `vs2` 的 `VirtaulService` 对象，主机名为 `service2.test.com`，网关设置为 `gw2`

两个网关对象使用的是一组工作负载（`istio: ingressgateway`），用同样的 IP 为两个服务提供网关支持。如果首先访问了 `service1.test.com`，会返回通配符证书 `*.test.com`，这一证书是可以用于连接 `service2.test.com` 的。Chrome 或者 Firefox 这样的浏览器会复用这已经存在的连接，来发起对 `service2.test.com` 的访问，但是 `gw1` 没有到 `service2.test.com` 的路由，所以就会返回 404 错误。

要解决这一问题，可以配置一个通用的 `Gateway` 对象，而不是分别配置两个 `gw1` 和 `gw2`。例如下面的配置：

- 创建一个名为 `gw` 的 `Gateway`，对应主机为 `*.test.com`，selector 仍然是 `istio: ingressgateway`，TLS 还是使用网关加载的证书。

- `VirtualService` 对象 `vs1` 配置主机名为 `service1.test.com`，网关设置为 `gw`

- `VirtualService` 对象 `vs2` 配置主机名为 `service2.test.com`，网关设置为 `gw`
