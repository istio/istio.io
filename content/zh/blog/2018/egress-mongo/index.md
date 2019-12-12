---
title: 使用外部 MongoDB 服务
description: 描述了一个基于 Istio 的 Bookinfo 示例的简单场景。
publishdate: 2018-11-16
last_update: 2019-11-12
subtitle: Istio Egress Control Options for MongoDB traffic
attribution: Vadim Eisenberg
keywords: [traffic-management,egress,tcp,mongo]
target_release: 1.1
---

在[使用外部 TCP 服务](/zh/blog/2018/egress-tcp/)博文中，我描述了网格内的 Istio 应用程序如何通过 TCP 使用外部服务。在本文中，我将演示如何使用外部 MongoDB
服务。您将使用 [Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)，它的书籍评级数据保存在 MongoDB 数据库中。您会将此数据库部署在集群外部，并配置 `ratings`
微服务使用它。您将学习控制到外部 MongoDB 服务流量的多种选择及其利弊。

## 使用外部 ratings 数据库的 Bookinfo {#Bookinfo-with-external-ratings-database}

首先，在您的 Kubernetes 集群外部建立一个 MongoDB 数据库实例以保存书籍评级数据。然后修改 [Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)使用该数据库。

### 建立 ratings 数据库{#setting-up-the-ratings-database}

在这个任务中您将建立一个 [MongoDB](https://www.mongodb.com) 实例。您可以使用任何 MongoDB 实例；我使用 [Compose for MongoDB](https://www.ibm.com/cloud/compose/mongodb)。

1. 为 `admin` 用户的密码设置一个环境变量。为了避免密码被保存在 Bash 历史记录中，在运行命令之后，请立即使用 [history -d](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins) 将其从历史记录中删除。

    {{< text bash >}}
    $ export MONGO_ADMIN_PASSWORD=<your MongoDB admin password>
    {{< /text >}}

1. 为需要创建的新用户（即 `bookinfo`）的密码设置环境变量，并使用 [history -d](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins) 将其从历史记录中删除。

    {{< text bash >}}
    $ export BOOKINFO_PASSWORD=<password>
    {{< /text >}}

1. 为您的 MongoDB 服务设置环境变量 `MONGODB_HOST` 和 `MONGODB_PORT`。

1. 创建 `bookinfo` 用户：

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.createUser(
       {
         user: "bookinfo",
         pwd: "$BOOKINFO_PASSWORD",
         roles: [ "read"]
       }
    );
    EOF
    {{< /text >}}

1. 创建一个 _collection_  来保存评级数据。以下命令将两个评级都设置为 `1`，以便在 Bookinfo _ratings_ service 使用数据库时提供视觉验证（默认 Bookinfo _ratings_
   为 `4` 和 `5`）

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.createCollection("ratings");
    db.ratings.insert(
      [{rating: 1},
       {rating: 1}]
    );
    EOF
    {{< /text >}}

1. 检查 `bookinfo` 用户是否可以获取评级数据:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u bookinfo -p $BOOKINFO_PASSWORD --authenticationDatabase test
    use test
    db.ratings.find({});
    EOF
    {{< /text >}}

   输出应该类似于:

    {{< text plain >}}
    MongoDB server version: 3.4.10
    switched to db test
    { "_id" : ObjectId("5b7c29efd7596e65b6ed2572"), "rating" : 1 }
    { "_id" : ObjectId("5b7c29efd7596e65b6ed2573"), "rating" : 1 }
    bye
    {{< /text >}}

### Bookinfo 应用程序的初始设置{#Initial-setting-of-Bookinfo-application}

为了演示使用外部数据库的场景，请首先运行一个[安装了 Istio](/zh/docs/setup/getting-started/) 的 Kubernetes 集群。然后部署
[Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)并[应用默认 destination rules](/zh/docs/examples/bookinfo/#apply-default-destination-rules)和[改变 Istio 到  blocking-egress-by-default 策略](/zh/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy)。

此应用程序从 `ratings` 微服务获取书籍评级（1 到 5 的数字）。评级以星标形式显示每条评论。`ratings` 微服务有几个版本。在下一小节中，请部署使用 [MongoDB](https://www.mongodb.com)
作为 ratings 数据库的版本。

本博文中的示例命令适用于 Istio 1.0。

作为提醒，这是 [Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/) 的端到端架构。

{{< image width="80%" link="/zh/docs/examples/bookinfo/withistio.svg" caption="The original Bookinfo application" >}}

### 在 Bookinfo 应用程序中使用外部数据库{#use-the-external-database-in-Bookinfo-application}

1.部署使用 MongoDB 数据库的 _ratings_ 微服务（_ratings v2_）：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    serviceaccount "bookinfo-ratings-v2" created
    deployment "ratings-v2" created
    {{< /text >}}

1.  为你的 MongoDB 设置 `MONGO_DB_URL` 环境变量：

    {{< text bash >}}
    $ kubectl set env deployment/ratings-v2 "MONGO_DB_URL=mongodb://bookinfo:$BOOKINFO_PASSWORD@$MONGODB_HOST:$MONGODB_PORT/test?authSource=test&ssl=true"
    deployment.extensions/ratings-v2 env updated
    {{< /text >}}

1. 将所有到 _reviews_ service 的流量路由到它的 _v3_ 版本，以确保 _reviews_ service 总是调用 _ratings_ service。此外，将所有到 `ratings` service
   的流量路由到使用外部数据库的 _ratings v2_。

   通过添加两个 [virtual services](/zh/docs/reference/config/networking/virtual-service/) 来为以上两个 services 指定路由。这些 virtual service
   在 Istio 发布包中 `samples/bookinfo/networking/virtual-service-ratings-mongodb.yaml` 有指定 。
   ***重要：*** 请确保在运行以下命令之前[应用了默认的 destination rules](/zh/docs/examples/bookinfo/#apply-default-destination-rules)。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

更新的架构如下所示。请注意，网格内的蓝色箭头标记对应于我们添加的 virtual service。根据 virtual service，流量将被发送到 `reviews v3` 和 `ratings v2`。

{{< image width="80%" link="./bookinfo-ratings-v2-mongodb-external.svg" caption="The Bookinfo application with ratings v2 and an external MongoDB database" >}}

请注意，MongoDB 数据库位于 Istio 服务网格之外，或者更确切地说是在 Kubernetes 集群之外。服务网格的边界使用虚线标记。

### 访问网页{#access-the-webpage}

[确认 ingress IP 和端口之后](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)，访问应用程序的网页。

由于您尚未配置 egress 流量控制，所以 Istio 会阻止到 MongoDB 服务的访问。这就是为什么您当前不能看到评级的星标，只能看到 _"Ratings service is currently unavailable"_ 的信息：

{{< image width="80%" link="./errorFetchingBookRating.png" caption="The Ratings service error messages" >}}

在以下部分中，您将使用不同的 Istio egress 控制选项，配置对外部 MongoDB 服务的访问。

## TCP 的 egress 控制{#egress-control-for-TCP}

由于 [MongoDB 协议](https://zh/docs.mongodb.com/manual/reference/mongodb-wire-protocol/)运行在 TCP 之上，您可以像控制到[其余 TCP 服务](/zh/blog/2018/egress-tcp/)的流量一样控制到 MongoDB 的 egress 流量。为了控制 TCP 流量，您必须指定一个 [CIDR](https://tools.ietf.org/html/rfc2317) 表示的 IP 块，该 IP 块包含 MongoDB 的地址。需要注意的是，有时候 MongoDB 主机的 IP 并不稳定或无法事先得知。

在 MongoDB IP 不稳定的情况下，可以以 [TLS 方式控制](#egress-control-for-TLS) egress 流量，或绕过 Istio sidecar [直接](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)路由流量。

获取 MongoDB 数据库实例的 IP 地址。一种选择是使用 [host](https://linux.die.net/man/1/host) 命令。

{{< text bash >}}
$ export MONGODB_IP=$(host $MONGODB_HOST | grep " has address " | cut -d" " -f4)
{{< /text >}}

### 在没有 gateway 的情况下控制 TCP egress 流量{#control-TCP-egress-traffic-without-a-gateway}

如果您不用通过 [egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#use-case) 定向流量，例如不要求所有流量都通过 gateway 流出网格时，请遵循以下部分的说明。或者，如果您确实希望通过 egress gateway 定向流量，请继续阅读[通过 egress gateway 定向 TCP egress 流量](#direct-tcp-egress-traffic-through-an-egress-gateway)。

1. 定义一个网格外 TCP service entry：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - my-mongo.tcp.svc
      addresses:
      - $MONGODB_IP/32
      ports:
      - number: $MONGODB_PORT
        name: tcp
        protocol: TCP
      location: MESH_EXTERNAL
      resolution: STATIC
      endpoints:
      - address: $MONGODB_IP
    EOF
    {{< /text >}}

   请注意，protocol 被指定为 `TCP` 而不是 `MONGO`，因为如果 [MongoDB 协议运行在 TLS 之上时](https://zh/docs.mongodb.com/manual/tutorial/configure-ssl/)，流量可以加密。如果加密了流量，该加密的 MongoDB 协议就不能被 Istio 代理解析。

   如果您知道使用的是未加密的 MongoDB 协议，可以指定 protocol 为 `MONGO`，从而使 Istio 代理产生 [MongoDB 相关的统计数据](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/mongo_proxy_filter#statistics)。还要注意，当指定 protocol `TCP` 时，配置不是特定于 MongoDB 的，对于其余使用基于 TCP 协议的数据库同样适用。

1. 刷新应用程序的网页。应用程序现在应该显示评级数据而非错误：

    {{< image width="80%" link="./externalDBRatings.png" caption="Book Ratings Displayed Correctly" >}}

请注意，和预期的一样，您会看到两个显示评论的一星评级。您将评级设置为一星，以作为外部数据库确实被使用了的视觉证据。

1.  如果要通过出口网关引导流量，请继续下一节。否则，请执行 [cleanup](#cleanup-of-TCP-egress-traffic-control).

### 通过 egress gateway 定向 TCP Egress 流量{#direct-TCP-egress-traffic-through-an-egress-gateway}

在本节中，您将处理通过 [egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#use-case) 定向流量的情况。Sidecar 代理通过匹配 MongoDB 主机的 IP 地址（一个 32 位长度的 CIDR 块），将 TCP 连接从 MongoDB 客户端路由到 egress gateway。Egress gateway 按照其 hostname，转发流量到 MongoDB 主机。

1.  [部署 Istio egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway).

1. 如果您未执行 [上一节](#control-TCP-egress-traffic-without-a-gateway) 中的步骤，则立即执行这些步骤。

1. 您可能希望启用 sidecar 代理和 MongoDB 客户端之间以及 egress gateway 的 {{< gloss >}}mutual TLS Authentication{{< /gloss >}}，以使 egress gateway 监控来源 pod 的身份并基于该 identity     启用 Mixer 策略。启用双向 TLS 时同样对流量进行了加密。
   如果你不想开启双向 TLS，参考 [Mutual TLS between the sidecar proxies and the egress gateway](#mutual-TLS-between-the-sidecar-proxies-and-the-egress-gateway) 小节
  否则，请继续以下部分。

#### 配置从 sidecar 到 egress gateway 的 TCP 流量{#configure-TCP-traffic-from-sidecars-to-the-egress-gateway}

1. 定义 `EGRESS_GATEWAY_MONGODB_PORT` 环境变量来保存用于通过 egress gateway 定向流量的端口，例如 `7777`。必须选择没有被网格中其余 service 使用的端口。

    {{< text bash >}}
    $ export EGRESS_GATEWAY_MONGODB_PORT=7777
    {{< /text >}}

1. 添加选择的端口到 `istio-egressgateway` service。您需要使用和安装 Istio 时一样的端口，特别是必须指定前面配置 `istio-egressgateway` 的所有端口。

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio-egressgateway --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml --set gateways.istio-ingressgateway.enabled=false --set gateways.istio-egressgateway.enabled=true --set gateways.istio-egressgateway.ports[0].port=80 --set gateways.istio-egressgateway.ports[0].name=http --set gateways.istio-egressgateway.ports[1].port=443 --set gateways.istio-egressgateway.ports[1].name=https --set gateways.istio-egressgateway.ports[2].port=$EGRESS_GATEWAY_MONGODB_PORT --set gateways.istio-egressgateway.ports[2].name=mongo | kubectl apply -f -
    {{< /text >}}

1. 检查 `istio-egressgateway` service 确实有选择的端口：

    {{< text bash >}}
    $ kubectl get svc istio-egressgateway -n istio-system
    NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
    istio-egressgateway   ClusterIP   172.21.202.204   <none>        80/TCP,443/TCP,7777/TCP   34d
    {{< /text >}}

1. 为 `istio-egressgateway` 服务 关闭双向 TLS 认证

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: istio-egressgateway
      namespace: istio-system
    spec:
      targets:
      - name: istio-egressgateway
    EOF
    {{< /text >}}

1. 为您的 MongoDB service 创建一个 egress `Gateway`、一个 destination rules 和 virtual services，以定向流量到 egress gateway，并从 egress gateway 发送到外部服务。

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
          number: $EGRESS_GATEWAY_MONGODB_PORT
          name: tcp
          protocol: TCP
        hosts:
        - my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mongo
    spec:
      host: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - my-mongo.tcp.svc
      gateways:
      - mesh
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - mesh
          destinationSubnets:
          - $MONGODB_IP/32
          port: $MONGODB_PORT
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: $EGRESS_GATEWAY_MONGODB_PORT
      - match:
        - gateways:
          - istio-egressgateway
          port: $EGRESS_GATEWAY_MONGODB_PORT
        route:
        - destination:
            host: my-mongo.tcp.svc
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1. [验证 TCP egress 流量是否被定向到 egress gateway](#verify-that-egress-traffic-is-directed-through-the-egress-gateway).

#### Sidecar 代理和 egress gateway 之间的双向 TLS{#mutual-TLS-between-the-sidecar-proxies-and-the-egress-gateway}

1. 删除前面小节中的配置：

    {{< text bash >}}
    $ kubectl delete gateway istio-egressgateway --ignore-not-found=true
    $ kubectl delete virtualservice direct-mongo-through-egress-gateway --ignore-not-found=true
    $ kubectl delete destinationrule egressgateway-for-mongo mongo --ignore-not-found=true
    $ kubectl delete policy istio-egressgateway -n istio-system --ignore-not-found=true
    {{< /text >}}

1.  Enforce mutual TLS authentication for the `istio-egressgateway` service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: authentication.istio.io/v1alpha1
    kind: Policy
    metadata:
      name: istio-egressgateway
      namespace: istio-system
    spec:
      targets:
      - name: istio-egressgateway
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. 为您的 MongoDB service 创建一个 egress `Gateway`、一个 destination rules 和 virtual services，以定向流量到 egress gateway，并从 egress gateway 发送到外部服务。

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
        - my-mongo.tcp.svc
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mongo
    spec:
      host: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - my-mongo.tcp.svc
      gateways:
      - mesh
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - mesh
          destinationSubnets:
          - $MONGODB_IP/32
          port: $MONGODB_PORT
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: my-mongo.tcp.svc
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1. 继续下一节。

#### 验证 TCP egress 流量是否通过 egress gateway 定向{#verify-that-egress-traffic-is-directed-through-the-egress-gateway}

1.  再次刷新应用程序的网页，并验证等级是否仍正确显示。

1.  [开启 Envoy访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

1. 检查 egress gateway 的 Envoy 的统计数据，找到对应请求 MongoDB service 的 counter。如果 Istio 步骤在 `istio-system` namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    [2019-04-14T06:12:07.636Z] "- - -" 0 - "-" 1591 4393 94 - "-" "-" "-" "-" "<Your MongoDB IP>:<your MongoDB port>" outbound|<your MongoDB port>||my-mongo.tcp.svc 172.30.146.119:59924 172.30.146.119:443 172.30.230.1:59206 -
    {{< /text >}}

### 清理通过 egress gateway 定向 TCP egress 流量的配置{#cleanup-of-TCP-egress-traffic-control}

{{< text bash >}}
$ kubectl delete serviceentry mongo
$ kubectl delete gateway istio-egressgateway --ignore-not-found=true
$ kubectl delete virtualservice direct-mongo-through-egress-gateway --ignore-not-found=true
$ kubectl delete destinationrule egressgateway-for-mongo mongo --ignore-not-found=true
$ kubectl delete policy istio-egressgateway -n istio-system --ignore-not-found=true
{{< /text >}}

## TLS egress 控制{#egress-control-for-TLS}

在现实生活中，绝大多数到外部服务的通信都必须被加密，而 [MongoDB 协议在 TLS 之上运行](https://zh/docs.mongodb.com/manual/tutorial/configure-ssl/)。
并且，TLS 客户端经常发送[服务器名称指示](https://en.wikipedia.org/wiki/Server_Name_Indication)，SNI，作为握手的一部分。
如果您的 MongoDB 服务器运行 TLS 且 MongoDB 客户端发送 SNI 作为握手的一部分，您就可以像任何其余带有 SNI 的 TLS 流量一样控制 MongoDB egress 流量。
您不需要指定 MongoDB 服务器的 IP 地址，而只需指定他们的主机名称，这样会更加方便，因为您无需依赖 IP 地址的稳定性。
您还可以指定通配符为主机名的前缀，例如允许从 `*.com` 域访问任意服务器。

要想检查您的 MongoDB 服务器是否支持 TLS，请运行：

{{< text bash >}}
$ openssl s_client -connect $MONGODB_HOST:$MONGODB_PORT -servername $MONGODB_HOST
{{< /text >}}

如果上述命令打印了一个服务器返回的证书，说明该服务器支持 TLS。如果没有，您就需要像前面小节描述的一样在 TCP 层面控制 MongoDB egress 流量。

### 无 gateway 情况下控制 TLS egress 流量{#control-TLS-egress-traffic-without-a-gateway}

如果您[不需要 egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#use-case)，请遵循本小节中的说明。
如果您需要通过 egress gateway 定向流量，请继续阅读[通过 egress gateway 定向 TCP Egress 流量](#direct-tcp-egress-traffic-through-an-egress-gateway)。

1. 为 MongoDB service 创建一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - $MONGODB_HOST
      ports:
      - number: $MONGODB_PORT
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1. 刷新应用程序的网页。应用程序应该正确显示评级数据。

#### 清理 TLS 的 egress 配置{#cleanup-of-the-egress-configuration-for-TLS}

{{< text bash >}}
$ kubectl delete serviceentry mongo
{{< /text >}}

### 通过 egress gateway 定向 TLS Egress 流量{#direct-tcp-egress-traffic-through-an-egress-gateway}

在本小节中，您将处理通过 [egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#use-case) 定向流量的情况。
Sidecar 代理通过匹配 MongoDB 主机的 SNI，将 TLS 连接从 MongoDB 客户端路由到 egress gateway。
Egress gateway 再将流量转发到 MongoDB 主机。请注意，sidecar 代理会将目的端口重写为 443。
Egress gateway 在 443 端口上接受 MongoDB 流量，按照 SNI 匹配 MongoDB 主机，并再次将端口重写为 MongoDB 服务器的端口。

1.  [部署 Istio egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway).

1. 为 MongoDB service 创建一个 `ServiceEntry`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - $MONGODB_HOST
      ports:
      - number: $MONGODB_PORT
        name: tls
        protocol: TLS
      - number: 443
        name: tls-port-for-egress-gateway
        protocol: TLS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1. 刷新应用程序的网页并验证评级数据是否显示正常。

1. 为您的 MongoDB service 创建一个 egress `Gateway`、一个 destination rules 和 virtual services，以将流量定向到 egress gateway，并从 egress gateway 发送到外部服务。

   如果您希望启用 sidecar 代理和应用程序 pod 以及 egress gateway 之间的[双向 TLS 认证](/zh/docs/tasks/security/authentication/mutual-tls/)，可以使用下面的命令。（您可能希望启用双向 TLS 以使 egress gateway 监控来源 pod 的身份并基于该 identity 启用 Mixer 策略。）

    {{< tabset category-name="mtls" >}}

    {{< tab name="mutual TLS enabled" category-value="enabled" >}}

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
        - $MONGODB_HOST
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: $MONGODB_HOST
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - $MONGODB_HOST
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: $MONGODB_HOST
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" category-value="disabled" >}}

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
        - $MONGODB_HOST
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - $MONGODB_HOST
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: $MONGODB_HOST
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. [验证 TCP egress 流量是否通过 egress gateway 定向](#verify-that-egress-traffic-is-directed-through-the-egress-gateway)

#### 清除通过 egress gateway 定向 TLS Egress 流量的配置{#cleanup-directing-TLS-Egress-traffic-through-an-egress-gateway}

{{< text bash >}}
$ kubectl delete serviceentry mongo
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-mongo-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-mongo
{{< /text >}}

### 启用到任意通配符域名的 MongoDB TLS egress 流量{#enable-MongoDB-TLS-egress-traffic-to-arbitrary-wildcarded-domains}

有时，您希望将 egress 流量配置为来自同一域的多个主机名，例如到 `*.<your company domain>.com` 中的所有 MongoDB service。
您不希望创建多个配置项，而是一个用于公司中所有 MongoDB service 的通用配置项。
要想通过一个配置来控制到所有相同域中的外部服务的访问，您需要使用*通配符*主机。

在本节中，您将为通配符域名配置 egress gateway。我在 `composedb.com` 处使用了 MongoDB instance，
因此为 `*.com` 配置出口流量对我有效（我也可以使用`*.composedb.com`）。
您可以根据 MongoDB 主机选择通配符域名。

要为通配符域名配置 egress gateway 流量，
您需要使用[一个额外的 SNI 代理](/zh/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)来部署一个自定义的 egress gateway。由于 Envoy（Istio egress gateway 使用的标准代理）目前的限制，这是必须的。

#### 准备一个 SNI 代理使用新的 egress gateway{#prepare-a-new-egress-gateway-with-an-SNI-proxy}

在本节中，除了标准的 Istio Envoy 代理之外，您还将部署具有 SNI 代理的 egress gateway。您可以使用任何能够根据任意未预先配置的 SNI 值路由流量的 SNI 代理；我们使用 [Nginx](http://nginx.org) 来实现这一功能。

1. 为 Nginx SNI 代理创建配置文件。如果需要，您可以编辑该文件以指定其他 Nginx 设置。

    {{< text bash >}}
    $ cat <<EOF > ./sni-proxy.conf
    user www-data;

    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # tcp forward proxy by SNI
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:$MONGODB_PORT;
        proxy_pass   \$ssl_preread_server_name:$MONGODB_PORT;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1. 创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) 来保存 Nginx SNI 代理的配置：

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1. 下面的命令将产生用于编辑和部署的 `istio-egressgateway-with-sni-proxy.yaml` 文件。

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/role.yaml -x charts/gateways/templates/rolebindings.yaml --set global.mtls.enabled=true --set global.istioNamespace=istio-system -f - > ./istio-egressgateway-with-sni-proxy.yaml
    gateways:
      enabled: true
      istio-ingressgateway:
        enabled: false
      istio-egressgateway:
        enabled: false
      istio-egressgateway-with-sni-proxy:
        enabled: true
        labels:
          app: istio-egressgateway-with-sni-proxy
          istio: egressgateway-with-sni-proxy
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        cpu:
          targetAverageUtilization: 80
        serviceAnnotations: {}
        type: ClusterIP
        ports:
          - port: 443
            name: https
        secretVolumes:
          - name: egressgateway-certs
            secretName: istio-egressgateway-certs
            mountPath: /etc/istio/egressgateway-certs
          - name: egressgateway-ca-certs
            secretName: istio-egressgateway-ca-certs
            mountPath: /etc/istio/egressgateway-ca-certs
        configVolumes:
          - name: sni-proxy-config
            configMapName: egress-sni-proxy-configmap
        additionalContainers:
        - name: sni-proxy
          image: nginx
          volumeMounts:
          - name: sni-proxy-config
            mountPath: /etc/nginx
            readOnly: true
    EOF
    {{< /text >}}

1. 部署新的 egress gateway：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway-with-sni-proxy.yaml
    serviceaccount "istio-egressgateway-with-sni-proxy-service-account" created
    role "istio-egressgateway-with-sni-proxy-istio-system" created
    rolebinding "istio-egressgateway-with-sni-proxy-istio-system" created
    service "istio-egressgateway-with-sni-proxy" created
    deployment "istio-egressgateway-with-sni-proxy" created
    horizontalpodautoscaler "istio-egressgateway-with-sni-proxy" created
    {{< /text >}}

1. 验证新 egress gateway 是否工作正常。请注意 pod 有两个容器（一个是 Envoy 代理，另一个是 SNI 代理）。

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1. 创建一个使用静态地址 127.0.0.1 (`localhost`) 的 service entry，并对定向到新 service entry 的流量禁用双向 TLS：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: sni-proxy
    spec:
      hosts:
      - sni-proxy.local
      location: MESH_EXTERNAL
      ports:
      - number: $MONGODB_PORT
        name: tcp
        protocol: TCP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: disable-mtls-for-sni-proxy
    spec:
      host: sni-proxy.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

#### 使用新 egress gateway 配置到 `*.com` 的访问{#configure-access-to-com-using-the-new-egress-gateway}

1. 为 `*.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - "*.com"
      ports:
      - number: 443
        name: tls
        protocol: TLS
      - number: $MONGODB_PORT
        name: tls-mongodb
        protocol: TLS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1. 为 *.com 创建一个 egress Gateway，使用 443 端口和 TLS 协议。创建一个 destination rule 来为 gateway 设置 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)。
以及为 Envoy 过滤器，以防止恶意应用程序篡改SNI (过滤器验证这个应用程序发布的 SNI与报告给 Mixer 的 SNI是否相同)

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway-with-sni-proxy
    spec:
      selector:
        istio: egressgateway-with-sni-proxy
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - "*.com"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mtls-for-egress-gateway
    spec:
      host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
      subsets:
        - name: mongo
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: ISTIO_MUTUAL
    ---
    # The following filter is used to forward the original SNI (sent by the application) as the SNI of the mutual TLS
    # connection.
    # The forwarded SNI will be reported to Mixer so that policies will be enforced based on the original SNI value.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: forward-downstream-sni
    spec:
      filters:
      - listenerMatch:
          portNumber: $MONGODB_PORT
          listenerType: SIDECAR_OUTBOUND
        filterName: forward_downstream_sni
        filterType: NETWORK
        filterConfig: {}
    ---
    # The following filter verifies that the SNI of the mutual TLS connection (the SNI reported to Mixer) is
    # identical to the original SNI issued by the application (the SNI used for routing by the SNI proxy).
    # The filter prevents Mixer from being deceived by a malicious application: routing to one SNI while
    # reporting some other value of SNI. If the original SNI does not match the SNI of the mutual TLS connection, the
    # filter will block the connection to the external service.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: egress-gateway-sni-verifier
    spec:
      workloadLabels:
        app: istio-egressgateway-with-sni-proxy
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: GATEWAY
        filterName: sni_verifier
        filterType: NETWORK
        filterConfig: {}
    EOF
    {{< /text >}}

1.  将目的为 _*.com_ 的流量路由到 egress gateway，并从 egress gateway 路由到 SNI 代理.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - "*.com"
      gateways:
      - mesh
      - istio-egressgateway-with-sni-proxy
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - "*.com"
        route:
        - destination:
            host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
          weight: 100
      tcp:
      - match:
        - gateways:
          - istio-egressgateway-with-sni-proxy
          port: 443
        route:
        - destination:
            host: sni-proxy.local
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1. 再次刷新应用程序的网页，验证评级数据仍然显示正确。

1.  [开启 Envoy 访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

1. 检查 egress gateway 的 Envoy 的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
    {{< /text >}}

    You should see lines similar to the following:

    {{< text plain >}}
    [2019-01-02T17:22:04.602Z] "- - -" 0 - 768 1863 88 - "-" "-" "-" "-" "127.0.0.1:28543" outbound|28543||sni-proxy.local 127.0.0.1:49976 172.30.146.115:443 172.30.146.118:58510 <your MongoDB host>
    [2019-01-02T17:22:04.713Z] "- - -" 0 - 1534 2590 85 - "-" "-" "-" "-" "127.0.0.1:28543" outbound|28543||sni-proxy.local 127.0.0.1:49988 172.30.146.115:443 172.30.146.118:58522 <your MongoDB host>
    {{< /text >}}

1. 检查 SNI 代理的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [23/Aug/2018:03:28:18 +0000] TCP [<your MongoDB host>]200 1863 482 0.089
    127.0.0.1 [23/Aug/2018:03:28:18 +0000] TCP [<your MongoDB host>]200 2590 1248 0.095
    {{< /text >}}

#### 理解原理{#understanding-what-happened}

在本节中，您使用通配符域名为您的 MongoDB 主机配置了 egress 流量。对于单个 MongoDB 主机使用通配符域名没有任何好处（可以指定确切的主机名），
而当集群中的应用程序需要访问多个匹配某个通配符域名的 MongoDB 主机时可能有用。
例如，如果应用程序需要访问 `mongodb1.composedb.com`、`mongodb2.composedb.com` 和 `mongodb3.composedb.com` 时，
egress 流量可以使用针对泛域名 `*.composedb.com` 的单个配置实现。

当配置一个应用使用另一个主机名匹配本小节中的通配符域名的 MongoDB 实例时，不需要额外的 Istio 配置。
我将这留作一个练习，让读者自行验证。

#### 清理到任意通配符域名的 MongoDB TLS egress 流量的配置{#cleanup-of-configuration-for-MongoDB-TLS-egress-traffic-to-arbitrary-wildcarded-domains}

1. 删除针对 `*.com` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry mongo
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-mongo-through-egress-gateway
    $ kubectl delete destinationrule mtls-for-egress-gateway
    $ kubectl delete envoyfilter forward-downstream-sni egress-gateway-sni-verifier
    {{< /text >}}

1. 删除 `egressgateway-with-sni-proxy` `Deployment` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f ./istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1. 删除您创建的配置文件：

    {{< text bash >}}
    $ rm ./istio-egressgateway-with-sni-proxy.yaml
    $ rm ./nginx-sni-proxy.conf
    {{< /text >}}

## 清理{#cleanup}

1. 删除`bookinfo`用户：

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.dropUser("bookinfo");
    EOF
    {{< /text >}}

1. 删除 `ratings` 集合：

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.ratings.drop();
    EOF
    {{< /text >}}

1. 取消您使用的环境变量：

    {{< text bash >}}
    $ unset MONGO_ADMIN_PASSWORD BOOKINFO_PASSWORD MONGODB_HOST MONGODB_PORT MONGODB_IP
    {{< /text >}}

1. 删除 virtual services：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    Deleted config: virtual-service/default/reviews
    Deleted config: virtual-service/default/ratings
    {{< /text >}}

1. 删除 `ratings v2-mongodb` deployment：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    deployment "ratings-v2" deleted
    {{< /text >}}

## 总结{#conclusion}

在这篇博文中，我演示了 MongoDB egress 流量控制的各种选项。您可以在 TCP 或 TLS 层面上控制 MongoDB egress 流量。
根据您的组织的安全需求，在 TCP 和 TLS 场景下您都可以将流量从 sidecar 代理定向到外部 MongoDB 主机
，或者通过一个 egress gateway 进行转发。在后面一种场景中，您还可以决定是否禁用 sidecar 代理到 egress gateway 的双向 TLS 认证。
如果您想要通过指定类似 `*.com` 的通配符域名来从 TLS 层面控制 MongoDB 的 egress 流量，并且通过 egress gateway 定向流量时，
您必须部署一个使用 SNI 代理的自定义 egress gateway。

请注意，本博客文章中描述的 MongoDB 配置和注意事项与 TCP/TLS 之上的其他非 HTTP 协议相同。
