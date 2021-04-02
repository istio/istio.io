---
title: Egress Gateway
description: 描述如何配置 Istio 通过专用网关服务将流量定向到外部服务。
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
此例子对 Minikube 无效。
{{</warning>}}

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务展示了如何配置 Istio 以允许网格内部的应用程序访问外部 HTTP 和 HTTPS 服务，但那个任务实际上是通过 sidecar 直接调用的外部服务。而这个示例会展示如何配置 Istio 以通过专用的 _egress gateway_ 服务间接调用外部服务。

Istio 使用 [Ingress and Egress gateways](/zh/docs/reference/config/networking/gateway/) 配置运行在服务网格边缘的负载均衡。
Ingress gateway 允许您定义网格所有入站流量的入口。Egress gateway 是一个与 Ingress gateway 对称的概念，它定义了网格的出口。Egress gateway 允许您将 Istio 的功能（例如，监视和路由规则）应用于网格的出站流量。

## 使用场景{#use-case}

设想一个对安全有严格要求的组织。要求服务网格所有的出站流量必须经过一组专用节点。专用节点运行在专门的机器上，与集群中运行应用程序的其他节点隔离。这些专用节点用于实施 egress 流量的策略，并且受到比其余节点更严密地监控。

另一个使用场景是集群中的应用节点没有公有 IP，所以在该节点上运行的网格 service 无法访问互联网。通过定义 egress gateway，将公有 IP 分配给 egress gateway 节点，用它引导所有的出站流量，可以使应用节点以受控的方式访问外部服务。

{{< boilerplate before-you-begin-egress >}}

*   [启用 Envoy 访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## 部署 Istio egress gateway{#deploy-Istio-egress-gateway}

1. 检查 Istio egress gateway 是否已布署：

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    如果没有 pod 返回，通过接下来的步骤来部署 Istio egress gateway。

1. 执行以下命令：

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.istioNamespace=istio-system \
        --set values.gateways.istio-ingressgateway.enabled=false \
        --set values.gateways.istio-egressgateway.enabled=true
    {{< /text >}}

{{< warning >}}
以下说明为 `default` 命名空间中的 egress gateway 创建了一条 destination rule，并且我们假定客户端 `SOURCE_POD` 也已经运行在 `default` 命名空间中。
如果没有创建 destination rule，[destination rule 查找路径](/zh/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)会找不到这条 destination rule，客户端请求将失败。

{{< /warning >}}

## 定义 Egress gateway 并引导 HTTP 流量{#egress-gateway-for-http-traffic}

首先创建一个 `ServiceEntry`，允许流量直接访问一个外部服务。

1. 为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，验证 `ServiceEntry` 是否已正确应用。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    输出结果应该与 [发起 TLS 的 Egress 流量](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/#configuring-access-to-an-external-service) 中的 `配置对外部服务的访问` 示例相同，都还没有发起 TLS。

1. 为 `edition.cnn.com` 端口 80 创建 egress `Gateway`。并为指向 egress gateway 的流量创建一个 destination rule。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1. 定义一个 `VirtualService`，将流量从 sidecar 引导至 egress gateway，再从 egress gateway 引导至外部服务：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 80
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 80
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 80
          weight: 100
    EOF
    {{< /text >}}

1. 再次发送 HTTP 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    The output should be the same as in the step 2.

1. 检查 `istio-egressgateway` pod 的日志，并查看与我们的请求对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    你应该会看到一行类似于下面这样的内容：

    {{< text plain >}}
    [2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
    {{< /text >}}

    Note that you only redirected the traffic from port 80 to the egress gateway. The HTTPS traffic to port 443
    went directly to _edition.cnn.com_.

### 清理 HTTP gateway{#cleanup-http-gateway}

在继续下一步之前删除先前的定义：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 用 Egress gateway 发起 HTTPS 请求{#egress-gateway-for-https-traffic}

接下来尝试使用 Egress Gateway 发起 HTTPS 请求（TLS 由应用程序发起）。您需要在相应的 `ServiceEntry`、egress `Gateway` 和 `VirtualService` 中指定 `TLS` 协议的端口 443。

1. 为 `edition.cnn.com` 定义 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，验证您的 `ServiceEntry` 是否已正确生效。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1. 为 `edition.cnn.com` 创建一个 egress `Gateway`。除此之外还需要创建一个 destination rule 和一个 virtual service，用来引导流量通过 egress gateway，并通过 egress gateway 与外部服务通信。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出结果应该和之前一样。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1. 检查 egress gateway 代理的日志。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    {{< /text >}}

    你应该会看到类似于下面的内容：

    {{< text plain >}}
    [2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
    {{< /text >}}

### 清理 HTTPS gateway{#cleanup-https-gateway}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 其他安全注意事项{#additional-security-considerations}

注意，Istio 中定义的 egress `Gateway` 本身并没有为其所在的节点提供任何特殊处理。集群管理员或云提供商可以在专用节点上部署 egress gateway，并引入额外的安全措施，从而使这些节点比网格中的其他节点更安全。

另外要注意的是，Istio **无法强制** 让所有出站流量都经过 egress gateway，Istio 只是通过 sidecar 代理实现了这种流向。攻击者只要绕过 sidecar 代理，就可以不经 egress gateway 直接与网格外的服务进行通信，从而避开了 Istio 的控制和监控。出于安全考虑，集群管理员和云供应商必须确保网格所有的出站流量都要经过 egress gateway。这需要通过 Istio 之外的机制来满足这一要求。例如，集群管理员可以配置防火墙，拒绝 egress gateway 以外的所有流量。[Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)也能禁止所有不是从 egress gateway 发起的出站流量（[下一节](#apply-Kubernetes-network-policies)有一个这样的例子）。此外，集群管理员和云供应商还可以对网络进行限制，让运行应用的节点只能通过 gateway 来访问外部网络。要实现这一限制，可以只给 gateway Pod 分配公网 IP，并且可以配置 NAT 设备，丢弃来自 egress gateway pod 之外的所有流量。

## 应用 Kubernetes 网络策略{#apply-Kubernetes-network-policies}

本节中展示了如何创建 [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)来阻止绕过 egress gateway 的出站流量。为了测试网络策略，首先创建一个 `test-egress` 命名空间，并在其中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，然后尝试发送一个会通过安全网关的外部服务请求。

1. 参考[用 Egress gateway 发起 HTTPS 请求](#egress-gateway-for-http-traffic)一节中的步骤。

1. 创建 `test-egress` 命名空间：

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

1. 在 `test-egress` 命名空间中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用：

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 检查生成的 Pod，其中应该只有一个容器，也就是说没有注入 Istio Sidecar：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

1. 从 `test-egress` 命名空间的 `sleep` pod 中向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics) 发送 HTTPS 请求。因为没有任何限制，所以这一请求应该会成功：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

1. 给 Istio 组件（控制平面和 gateway）所在的命名空间打上标签。例如，你的 Istio 组件部署在 `istio-system` 命名空间中，则命令是：

    {{< text bash >}}
    $ kubectl label namespace istio-system istio=system
    {{< /text >}}

1. 给 `kube-system` 命名空间打标签：

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

1. 创建一个 `NetworkPolicy`，来限制 `test-egress` 命名空间的出站流量，只允许目标为 `kube-system` DNS（端口 53）的请求，以及目标为 `istio-system` 命名空间的所有请求：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n test-egress -f -
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-egress-to-istio-system-and-kube-dns
    spec:
      podSelector: {}
      policyTypes:
      - Egress
      egress:
      - to:
        - namespaceSelector:
            matchLabels:
              kube-system: "true"
        ports:
        - protocol: UDP
          port: 53
      - to:
        - namespaceSelector:
            matchLabels:
              istio: system
    EOF
    {{< /text >}}

1. 重新发送前面的 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。这次请求就不会成功了，这是因为流量被网络策略拦截了。`sleep` pod 无法绕过 `istio-egressgateway`。要访问 `edition.cnn.com`，只能通过 Istio sidecar 代理，让流量经过 `istio-egressgateway` 才能完成。这种配置表明，即使一些恶意的 pod 绕过了 sidecar，也会被网络策略拦截，而无法访问到外部站点。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -v https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

1. 接下来在 `test-egress` 命名空间的 `sleep` Pod 上注入 Sidecar，启用 `test-egress` 命名空间的自动注入：

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

1. 重新部署 `sleep`：

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

1. 检查生成的 Pod，其中应该有了两个容器，其中包含了注入的 sidecar（`istio-proxy`）：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -o jsonpath='{.spec.containers[*].name}'
    sleep istio-proxy
    {{< /text >}}

1. 为 `default` 命名空间中为 `sleep` pod 创建一个相同的 destination rule 用来引导流量经过 egress gateway：

    {{< text bash >}}
    $ kubectl apply -n test-egress -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1. 向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics) 发送 HTTP 请求，这次会成功，原因是网络策略允许流量流向 `istio-system` 中的 `istio-egressgateway`。`istio-egressgateway` 最终把流量转发到 `edition.cnn.com`。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

1. 检查 Egress gateway 中的代理统计数据。如果 Istio 部署在 `istio-system` 命名空间，那么打印日志的命令就是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    {{< /text >}}

    你应该会看到一行类似于下面这样的内容：

    {{< text plain >}}
    [2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
    {{< /text >}}

### 清理网络策略{#cleanup-network-policies}

1. 删除本节中建立的资源：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
    $ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
    $ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
    $ kubectl label namespace kube-system kube-system-
    $ kubectl label namespace istio-system istio-
    $ kubectl delete namespace test-egress
    {{< /text >}}

1. 请参考[清理 HTTPS gateway](#cleanup-https-gateway)一节的内容。

## 故障排除{#troubleshooting}

1. 如果启用了[双向 TLS 认证](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-TLS)，请验证 egress gateway 证书的正确性：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
    {{< /text >}}

1. HTTPS 透传流量情况（由应用而不是 egress 发起 TLS），需要使用 `openssl` 命令测试流量。`openssl` 的 `-servername` 选项可以用来设置 SNI：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- openssl s_client -connect edition.cnn.com:443 -servername edition.cnn.com
    CONNECTED(00000003)
    ...
    Certificate chain
     0 s:/C=US/ST=California/L=San Francisco/O=Fastly, Inc./CN=turner-tls.map.fastly.net
       i:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
     1 s:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
       i:/C=BE/O=GlobalSign nv-sa/OU=Root CA/CN=GlobalSign Root CA
     ---
     Server certificate
     -----BEGIN CERTIFICATE-----
    ...
    {{< /text >}}

    如果在上面命令的输出中看到了类似的证书信息，就表明路由是正确的。接下来检查 egress gateway 的代理，查找对应请求的计数器（由 `openssl` 和 `curl` 发送，目标是 `edition.cnn.com`）：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- pilot-agent request GET stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

## 清理{#cleanup}

关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
