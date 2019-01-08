---
标题: 连接到外部HTTPS代理
描述: 描述如何配置Istio以允许应用程序使用外部HTTPS代理。
权重: 60
关键词: [traffic-management,egress]
---
[配置Egress Gateway]（/docs/examples/advanced gateways/egress gateway/）示例显示如何通过名为“Egress Gateway”的istio组件将流量从网格引导到外部服务。但是，有些情况下需要一个外部的传统（非ISTIO）HTTPS代理来访问外部服务。例如，您的公司可能已经有了这样的代理，并且可能需要所有应用程序通过代理来引导其流量。

此示例演示如何启用对外部HTTPS代理的访问。由于应用程序使用http[connect](https://tools.ietf.org/html/rfc7231#section-4.3.6)方法与https代理建立连接，因此配置流量到外部HTTPS代理不同于将流量配置为外部HTTP和HTTPS服务。

{{< boilerplate before-you-begin-egress >}}

## 部署HTTPS代理

本例中为了模拟传统代理，请在集群内部署了一个HTTPS代理。此外，为了模拟在集群外运行的更真实的代理，您将通过代理的IP地址而不是Kubernetes服务的域名来寻址代理的pod。本例使用的是[squid]（http://www.squid-cache.org），但是您可以使用任何支持HTTP CONNECT连接的HTTPS代理。

1.为HTTPS代理创建一个名称空间，而不标记为用于SideCar注入。如果没有标签，则在新名称空间中SideCar注入是不可用的，因此Istio将无法控制那里的流量。您需要在集群之外通过这种行为来模拟代理。

    {{< text bash >}}
    $ kubectl create namespace external
    {{< /text >}}

1.  为Squid代理创建配置文件。

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

1.  创建Kubernetes[configmap](https://kubernetes.io/docs/tasks/configure-pod-ontainer/configure-pod-configmap/)以保存代理的配置:

    {{< text bash >}}
    $ kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
    {{< /text >}}

1.  使用Squid部署容器:

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

1.  在“external”名称空间中部署[sleep]({{<github_tree>}}/samples/sleep)示例，以测试到代理的通信量，而不进行ISIO流量控制。

    {{< text bash >}}
    $ kubectl apply -n external -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  获取代理pod的IP地址并定义“PROXY_IP”环境变量来存储它:

    {{< text bash >}}
    $ export PROXY_IP=$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})
    {{< /text >}}

1.  定义'PROXY_PORT'环境变量以存储代理的端口。本例中，Squid使用 3128 端口。

    {{< text bash >}}
    $ export PROXY_PORT=3128
    {{< /text >}}

1.  从“external”命名空间中的“sleep”pod通过代理向外部服务发送请求:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=sleep -o jsonpath={.items..metadata.name}) -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  检查您请求的代理的访问日志:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

现在，您在没有Istio的情况下完成了以下任务:

* 您部署了HTTPS代理。
* 您使用“curl”通过代理访问“wikipedia.org”外部服务。

下一步，您必须配置来自Istio-enabled的pods的流量以使用HTTPS代理。

## 配置流量到外部HTTPS代理

1.  为HTTPS代理定义TCP（不是HTTP！）服务实体。尽管应用程序使用HTTP CONNECT方法与HTTPS代理建立连接，但必须为TCP通信而不是HTTP通信配置代理。一旦建立了连接，代理就简单地充当TCP隧道。

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

1.  从“default”命名空间中的“sleep”pod发送请求。因为“sleep” pod有sidecar，Istio控制着它的流量。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  查看您的请求的Istio sidecar代理的日志:

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

1.  查看您请求的代理的访问日志:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

## 了解发生的事情

在本例中，您采取了以下步骤:

1. 部署了一个HTTPS代理来模拟外部代理。
1. 创建了一个TCP服务实体，以启用到外部代理的ISIO控制流量。

请注意，您不能为通过外部代理访问的外部服务创建服务实体，例如`wikipedia.org`。这是因为从istio的角度来看，请求只发送到外部代理；istio并不知道外部代理进一步转发请求。

## 清除

1.  关闭[sleep]({{<github_tree>}}/samples/sleep)服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  关闭“external”命名空间中的[sleep]({{<github_tree>}}/samples/sleep)服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n external
    {{< /text >}}

1.  关闭Squid代理，删除“ConfigMap”和配置文件:

    {{< text bash >}}
    $ kubectl delete -n external deployment squid
    $ kubectl delete -n external configmap proxy-configmap
    $ rm ./proxy.conf
    {{< /text >}}

1.  删除“external”命名空间:

    {{< text bash >}}
    $ kubectl delete namespace external
    {{< /text >}}

1.  删除“external”命名空间:

    {{< text bash >}}
    $ kubectl delete serviceentry proxy
    {{< /text >}}

	