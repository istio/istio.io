---
title: 连接到外部 HTTPS 代理
description: 描述如何配置 Istio 以允许应用程序使用外部 HTTPS 代理。
weight: 60
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/http-proxy/
---
[配置 Egress Gateway]（/docs/examples/advanced gateways/egress-gateway/）示例显示如何通过名为 Egress Gateway 的 Istio 组件将流量从网格引导到外部服务。但是，有些情况下需要一个外部的传统（非ISTIO）HTTPS 代理来访问外部服务。例如，您的公司可能已经有了这样的代理，并且可能需要所有应用程序通过代理来引导其流量。

此示例演示如何启用对外部HTTPS代理的访问。由于应用程序使用 http[connect](https://tools.ietf.org/html/rfc7231#section-4.3.6)方法与 https 代理建立连接，因此配置流量到外部HTTPS代理不同于将流量配置为外部 HTTP 和 HTTPS 服务。

{{< boilerplate before-you-begin-egress >}}

## 部署 HTTPS 代理

本例中为了模拟传统代理，请在集群内部署了一个 HTTPS 代理。此外，为了模拟在集群外运行的更真实的代理，您将通过代理的IP地址而不是 Kubernetes 服务的域名来寻址代理的 pod。本例使用的是[squid](http://www.squid-cache.org) ，但是您可以使用任何支持 HTTP CONNECT 连接的 HTTPS 代理。

1.为 HTTPS 代理创建一个名称空间，而不标记为用于 SideCar 注入。如果没有标签，则在新名称空间中 SideCar 注入是不可用的，因此 Istio 将无法控制那里的流量。您需要在集群之外通过这种行为来模拟代理。

    {{< text bash >}}
    $ kubectl create namespace external
    {{< /text >}}

1.  为 Squid 代理创建配置文件。

    {{< text bash >}}
    $ cat <<EOF > ./proxy.conf
    http_port 3128

    acl SSL_ports port 443
    acl CONNECT method CONNECT

    http_access deny CONNECT !SSL_ports
    http_access allow localhost manager
    http_access deny manager
    http_access allow all

    coredump_dir /var/spool/squid
    EOF
    {{< /text >}}

1.  创建 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)以保存代理的配置:

    {{< text bash >}}
    $ kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
    {{< /text >}}

1.  使用 Squid 部署容器:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: squid
      namespace: external
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: squid
        spec:
          volumes:
          - name: proxy-config
            configMap:
              name: proxy-configmap
          containers:
          - name: squid
            image: sameersbn/squid:3.5.27
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: proxy-config
              mountPath: /etc/squid
              readOnly: true
    EOF
    {{< /text >}}

1.  在 external 名称空间中部署 [sleep]({{<github_tree>}}/samples/sleep) 示例，以测试到代理的通信量，而不进行ISIO流量控制。

    {{< text bash >}}
    $ kubectl apply -n external -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  获取代理 pod 的 IP 地址并定义 `PROXY_IP` 环境变量来存储它:

    {{< text bash >}}
    $ export PROXY_IP=$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})
    {{< /text >}}

1.  定义 `PROXY_PORT` 环境变量以存储代理的端口。本例中，Squid 使用 3128 端口。

    {{< text bash >}}
    $ export PROXY_PORT=3128
    {{< /text >}}

1.  从 external 命名空间中的 sleep  pod 通过代理向外部服务发送请求:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=sleep -o jsonpath={.items..metadata.name}) -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  检查您请求的代理的访问日志:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

现在，您在没有 Istio的情况下完成了以下任务:

* 您部署了 HTTPS 代理。
* 您使用 curl 通过代理访问 wikipedia.org 外部服务。

下一步，您必须配置来自 Istio-enabled 的 pods 的流量以使用 HTTPS 代理。

## 配置流量到外部 HTTPS 代理

1.  为 HTTPS 代理定义 TCP（不是 HTTP ！）服务实体。尽管应用程序使用 HTTP CONNECT 方法与 HTTPS 代理建立连接，但必须为 TCP 通信而不是 HTTP 通信配置代理。一旦建立了连接，代理就简单地充当 TCP 隧道。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: proxy
    spec:
      hosts:
      - my-company-proxy.com # ignored
      addresses:
      - $PROXY_IP/32
      ports:
      - number: $PROXY_PORT
        name: tcp
        protocol: TCP
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  从 default 命名空间中的 sleep pod发送请求。因为 sleep  pod有 sidecar，Istio 控制着它的流量。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  查看您的请求的 Istio sidecar 代理的日志:

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

1.  查看您请求的代理的访问日志:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

## 理解原理

在本例中，您采取了以下步骤:

1. 部署了一个 HTTPS 代理来模拟外部代理。
1. 创建了一个 TCP 服务实体，以启用到外部代理的 Istio 控制流量。

请注意，您不能为通过外部代理访问的外部服务创建服务实体，例如 wikipedia.org 。这是因为从 Istio 的角度来看，请求只发送到外部代理；Istio 并不知道外部代理进一步转发请求。

## 清除

1.  关闭 [sleep]({{<github_tree>}}/samples/sleep) 服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  关闭 external 命名空间中的 [sleep]({{<github_tree>}}/samples/sleep) 服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n external
    {{< /text >}}

1.  关闭 Squid 代理，删除 ConfigMap 和配置文件:

    {{< text bash >}}
    $ kubectl delete -n external deployment squid
    $ kubectl delete -n external configmap proxy-configmap
    $ rm ./proxy.conf
    {{< /text >}}

1.  删除 external 命名空间:

    {{< text bash >}}
    $ kubectl delete namespace external
    {{< /text >}}

1.  删除 Service Entry:

    {{< text bash >}}
    $ kubectl delete serviceentry proxy
    {{< /text >}}
