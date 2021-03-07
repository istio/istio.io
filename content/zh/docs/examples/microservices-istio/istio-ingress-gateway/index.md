---
title: 配置 Istio Ingress Gateway
overview: 从 Ingress 开始控制流量。
weight: 71

owner: istio/wg-docs-maintainers
test: no
---

到目前为止，你可以通过 Kubernetes Ingress 在外部去访问你的应用。在本模块，你可以通过 Istio
Ingress Gateway 配置流量，以便在微服务中通过使用 Istio 控制流量。

1.  在环境变量中存储你的命名空间 `NAMESPACE`。你需要通过它在日志中辨别你的微服务。

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

2.  为 Istio Ingress Gateway 的主机名创建一个环境变量。

    {{< text bash >}}
    $ export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
    $ echo $MY_INGRESS_GATEWAY_HOST
    istio.tutorial.bookinfo.com
    {{< /text >}}

3.  配置 Istio Ingress Gateway：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: bookinfo-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - $MY_INGRESS_GATEWAY_HOST
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      hosts:
      - $MY_INGRESS_GATEWAY_HOST
      gateways:
      - bookinfo-gateway.$NAMESPACE.svc.cluster.local
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /static
        route:
        - destination:
            host: productpage
            port:
              number: 9080
    EOF
    {{< /text >}}

4.  在 [确定 Ingress IP 和 Port](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) 部分可以使用指令设置 `INGRESS_HOST` 和 `INGRESS_PORT`。 

5.  将该命令的输出添加到你的 `/etc/hosts` 文件中。

    {{< text bash >}}
    $ echo $INGRESS_HOST $MY_INGRESS_GATEWAY_HOST
    {{< /text >}}

6.  从命令行访问应用的首页:

    {{< text bash >}}
    $ curl -s $MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

7.  将以下命令的输出粘贴在你的浏览器地址栏中：

    {{< text bash >}}
    $ echo http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage
    {{< /text >}}

8.  在一个新的终端窗口设置一个无限循环来模拟现实世界的用户流量去访问你的应用。

    {{< text bash >}}
    $ while :; do curl -s <output of the previous command> | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

9.  在 Kiali 控制台 `my-kiali.io/kiali/console` 通过 Graph 检查你的命名空间。（这个 `my-kiali.io` URL 设置在你[之前配置](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file) 的 `/etc/hosts` 文件中）。

    在这，你可以看到有两个来源的流量，一个是 `unknown`（Kubernetes Ingress），一个是`istio-ingressgateway istio-system`（Istio Ingress Gateway）。

    {{< image width="80%"
        link="kiali-ingress-gateway.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway"
        >}}

10. 此时你可以停止发送 Kubernetes Ingress 请求，只使用Istio Ingress Gateway。停止你之前设置的无限循环（在终端窗口使用 `Ctrl-C`）。在真实的生产环境中，你需要更新应用的 DNS 条目，使其包含 Istio ingress gateway 的 IP，或者配置你的外部负载均衡器。

11. 删除Kubernetes Ingress 资源：

    {{< text bash >}}
    $ kubectl delete ingress bookinfo
    ingress.extensions "bookinfo" deleted
    {{< /text >}}

12. 在一个新的终端窗口，按照前面的步骤，重启模拟真实世界的用户流量。

13. 在 Kiali 控制台检查你的 Graph。Istio Ingress Gateway 是你应用的唯一流量来源。

    {{< image width="80%"
        link="kiali-ingress-gateway-only.png"
        caption="Kiali Graph Tab with Istio Ingress Gateway as a single source of traffic"
        >}}

您已经准备好去配置 [Istio 日志](/zh/docs/examples/microservices-istio/logs-istio).
