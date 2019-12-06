---
title: Egress Gateway
description: 描述如何配置 Istio 通过专用网关服务将流量定向到外部服务。
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway/
---

{{<warning>}}
此例子对 Minikube 无效。
{{</warning>}}

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务显示了如何配置 Istio 允许从网格内部的应用程序访问外部 HTTP 和 HTTPS 服务，实际上是 Sidecar 直接调用外部服务。此示例还显示了如何配置 Istio 通过专用的 _Egress gateway_ 服务间接调用外部服务。

Istio 使用 [Ingress and Egress gateways](/zh/docs/reference/config/networking/gateway/) 配置在服务网格边缘执行的负载均衡器。
Ingress gateway 使您可以定义所有输入流量流经的网格的入口点。Egress gateway 是一个对称的概念，它定义了网格的出口点。Egress gateway 允许您可以将 Istio 功能（例如，监视和路由规则）应用于离开网格的流量。

## 用例{#use-case}

设想一个对安全有严格要求的组织。要求服务网格的所有出口流量必须流经一组专用节点。这些节点将在专用机器上运行，并与在集群中运行应用程序的其余节点分隔开。这些专用的节点将用于 Egress 流量的策略实施，并且将受到比其余节点更详细地监控。

另一个用例是应用程序节点没有公共 IP 的集群，因此在其上运行的网格内服务无法访问 Internet。定义 Egress gateway，通过它引导所有出口流量并将公共 IP 分配给 Egress gateway 节点，允许应用节点以受控的方式访问外部服务。

{{< boilerplate before-you-begin-egress >}}

*   [启用 Envoy 访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## 部署 Istio egress gateway{#deploy-Istio-egress-gateway}

1.  检查 Istio egress gateway 是否已布署：

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    如果没有 pod 返回，通过接下来的步骤来部署 Istio egress gateway。

1.  执行以下命令：

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.istioNamespace=istio-system \
        --set values.gateways.istio-ingressgateway.enabled=false \
        --set values.gateways.istio-egressgateway.enabled=true
    {{< /text >}}

{{< warning >}}
以下说明在 `default` 命名空间中为 Egress gateway 创建 destination rule 并假设客户端 `SOURCE_POD` 也在 `default` 命名空间中运行。
如果没有，则 destination rule 将不会在 [destination rule 查找路径](/zh/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)，客户端请求将失败。

{{< /warning >}}

## 定义 Egress gateway 并引导 HTTP 流量{#egress-gateway-for-http-traffic}

首先创建一个 `ServiceEntry` 引导流和到一个外部服务。

1.  为 `edition.cnn.com` 定义一个 `ServiceEntry`：

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

1.  发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，验证 `ServiceEntry` 是否已正确应用。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
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

    不带 TLS 的输出应与 [Egress 流量的 TLS](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/) 任务中的输出相同。

1.  为 `edition.cnn.com` 端口 80 创建 Egress gateway。除此之外还要创建一个 destination rule 来引导流量通过 Egress gateway 与外部服务通信。

    根据在 Istio 中是否启用了[双向 TLS 认证](/zh/docs/tasks/security/authentication/mutual-tls/)，选择相应的说明。

    {{< tabset category-name="mtls" >}}

    {{< tab name="mutual TLS enabled" category-value="enabled" >}}

    {{< text_hack bash >}}
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
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 80
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" category-value="disabled" >}}

    {{< text_hack bash >}}
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
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  定义 `VirtualService` 来引导流量，从 Sidecar 到 Egress gateway 和 从 Egress gateway 到外部服务：

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

1.  将 HTTP 请求重新发送到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
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

1.  检查  `istio-egressgateway` pod 的日志，并查看与我们的请求对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain >}}
    [2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
    {{< /text >}}

    Note that you only redirected the traffic from port 80 to the egress gateway. The HTTPS traffic to port 443
    went directly to _edition.cnn.com_.

### 清除 HTTP gateway{#cleanup-http-gateway}

在继续下一步之前删除先前的定义：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 用 Egress gateway 发起 HTTPS 请求{#egress-gateway-for-https-traffic}

接下来尝试使用 Egress Gateway 发起 HTTPS 请求（TLS 由应用程序发起）。您需要在相应的 `ServiceEntry` 中使用 `TLS` 协议指定的端口 443、egress `Gateway` 、`VirtualService`。

1.  为 `edition.cnn.com` 定义 `ServiceEntry`：

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

1.  发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，验证您的 `ServiceEntry` 是否已正确生效。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  为 `edition.cnn.com` 创建 Egress Gateway。除此之外还创建了一个 destination rule 和一个 virtual service，这两个对象用来引导流量通过 Egress gateway 与外部服务通信。

    根据在 Istio 中是否启用了[双向 TLS](/zh/docs/tasks/security/authentication/mutual-tls/)，选择相应的说明。

    {{< tabset category-name="mtls" >}}

    {{< tab name="mutual TLS enabled" category-value="enabled" >}}

    {{< text_hack bash >}}
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
          name: tls-cnn
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
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
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" category-value="disabled" >}}

    {{< text_hack bash >}}
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
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出应用和之前一样。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  检查 `istio-egressgateway` pod 的日志，并查看与我们的请求相对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    {{< /text >}}

    这里会看到与之前请求相关的行，类似于以下内容：

    {{< text plain >}}
    [2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
    {{< /text >}}

### 清除 HTTPS gateway{#cleanup-https-gateway}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 其他安全注意事项{#additional-security-considerations}

在 Istio 中定义的 Egress gateway，本身并不会对运行 Egress gateway 服务的节点进行任何特殊处理。集群管理员或云提供商可以在专用节点上部署 Egress gateway，并引入额外的安全措施，使这些节点比网格的其余部分更安全。

另外要注意的是，实际上 Istio 本身无法安全地强制将所有 Egress 流量流经 Egress gateway，Istio 仅通过其 Sidecar 代理启用此类流量。攻击者只要绕过 Sidecar 代理，就可以不经 Egress gateway 直接与网格外面的服务进行通信，从而避免了 Istio 的控制和监控。集群管理员或云供应商必须确保所有外发流量都从 Egress gateway 途径发起。需要用 Istio 之外的机制来满足这一需求，例如以下几种做法：

* 使用防火墙拒绝所有来自 Egress gateway 以外的流量。
* [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)也能禁止所有不是从 Egress gateway 发起的 Egress 流量（[下一节](#apply-Kubernetes-network-policies)中举出了这样的例子）。
* 管理员或者云供应商还可以对网络进行限制，让运行应用的节点只能通过 Gateway 来访问外部网络。要完成这一限制，可以只给 Gateway Pod 分配公网 IP，或者可以配置 NAT 设备，丢弃来自 Egress gateway 以外 Pod 的流量。

## 应用 Kubernetes 网络策略{#apply-Kubernetes-network-policies}

本节中展示了如何创建 [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)来阻止绕过 Egress gateway 的外发流量。为了测试网络策略，首先创建一个 `test-egress` 命名空间，并在其中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，然后尝试发送请求到一个网关安全的外部服务。

1.  重复执行[通过 Egress gateway 进行 HTTPS 流量透传](#egress-gateway-for-http-traffic)一节的内容。

1.  创建`test-egress` 命名空间：

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

1.  在 `test-egress` 命名空间中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用：

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  检查生成的 Pod，其中应该只有一个容器，也就是说没有注入 Istio Sidecar：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

1.  从 `test-egress` 命名空间的 `sleep` Pod 中向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics) 发送 HTTPS 请求。因为没有任何限制，所以这一请求应该会成功：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

1.  给 Istio 组件（控制平面和 Gateway）所在的命名空间打上标签，例如 `istio-system`：

    {{< text bash >}}
    $ kubectl label namespace istio-system istio=system
    {{< /text >}}

1.  给 `kube-system` 命名空间打标签：

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

1.  创建一个 `NetworkPolicy`，来限制 `test-egress` 命名空间的流量，只允许目标为 `kube-system` 的 DNS（端口 53）请求，以及目标为 `istio-system` 命名空间的所有请求：

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

1.  重新发送前面的 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。这次请求就不会成功了，这是因为流量被网络策略拦截了。测试 Pod 无法越过 `istio-egressgateway`。要访问 `edition.cnn.com`，只能通过 Istio Sidecar 将流量转给 `istio-egressgateway` 才能完成。这一设置演示了即使绕过了 Sidecar，也会被网络策略拦截，而无法访问到外部站点。

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

1.  接下来在 `test-egress` 命名空间的 `sleep` Pod 上注入 Sidecar，启用 `test-egress` 命名空间的自动注入：

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

1.  重新部署 `sleep`：

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

1.  检查生成的 Pod，其中应该有了两个容器，其中包含了注入的 Sidecar（`istio-proxy`）：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -o jsonpath='{.spec.containers[*].name}'
    sleep istio-proxy
    {{< /text >}}

1.  为 `default` 命名空间中为 `sleep` pod 创建一个相同的 destination rule 用来引导流量到 Egress gateway：

    根据在 Istio 中是否启用了[双向 TLS](/zh/docs/tasks/security/authentication/mutual-tls/)，选择相应的说明。

    {{< tabset category-name="mtls" >}}

    {{< tab name="mutual TLS enabled" category-value="enabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -n test-egress -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" category-value="disabled" >}}

    {{< text_hack bash >}}
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
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics) 发送 HTTP 请求，这次会成功，原因是网络策略允许流量流向 `istio-system` 中的 `istio-egressgateway`，`istio-egressgateway` 最终把流量转发到 `edition.cnn.com`。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

1.  检查 Egress gateway 中的代理统计数据，查看对 `edition.cnn.com` 的请求计数。如果 Istio 部署在 `istio-system` 命名空间，那么打印计数器的命令就是：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- pilot-agent request GET stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

### 清理网络策略{#cleanup-network-policies}

1.  删除本节中建立的资源：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
    $ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
    $ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
    $ kubectl label namespace kube-system kube-system-
    $ kubectl label namespace istio-system istio-
    $ kubectl delete namespace test-egress
    {{< /text >}}

1.  执行[通过 Egress gateway 进行 HTTPS 流量透传](#egress-gateway-for-http-traffic)一节中的[清理工作](#cleanup-http-gateway)。

## 故障排除{#troubleshooting}

1.  检查是否在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/authentication/mutual-tls/)，然后执行以下步骤：[验证 Istio 的双向 TLS 认证设置](/zh/docs/tasks/security/authentication/mutual-tls/#verify-mutual-TLS-configuration)。如果启用了双向 TLS，请确保创建相应的项目配置（请注意备注**如果您在 Istio 中启用了双向 TLS 认证，则必须创建。**）。

1.  如果[双向 TLS 认证](/zh/docs/tasks/security/authentication/mutual-tls/)启用后，验证 Egress gateway 的证书：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
    {{< /text >}}

1.  HTTPS 透传流量情况，需要使用 `openssl` 命令测试流量。`openssl` 的 `-servername` 选项可以用来设置 SNI：

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

    如果在上面命令的输出中看到了类似的证书信息，就表明路由是正确的。接下来检查 Egress gateway 代理，查找对应请求的计数器（由 `openssl` 和 `curl` 发送，目标是 `edition.cnn.com`）：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- pilot-agent request GET stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

## 清理{#cleanup}

关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
