---
title: 使用外部 TCP 服务
description: 描述基于 Istio Bookinfo 示例的简单场景
publishdate: 2018-02-06
subtitle: Egress rules for TCP traffic
attribution: Vadim Eisenberg
weight: 92
aliases:
  - /docs/tasks/traffic-management/egress-tcp/
keywords: [traffic-management,egress,tcp]
---

在我之前的博客文章[使用外部Web服务](/blog/2018/egress-https/)中，我描述了如何通过 HTTPS 在网格 Istio 应用程序中使用外部服务, 在这篇文章中，我演示了通过 TCP 使用外部服务, 我使用[Istio Bookinfo示例应用程序](/docs/examples/bookinfo/)，这是将书籍评级数据保存在 MySQL 数据库中的版本, 我在集群外部署此数据库并配置 _ratings_ 服务以使用它, 我定义了[出口规则](https://archive.istio.io/v0.7/docs/reference/config/istio.routing.v1alpha1/#EgressRule)以允许网内应用程序访问外部数据库。

## Bookinfo 示例应用程序与外部评级数据库

首先，我在 Kubernetes 集群之外设置了一个 MySQL 数据库实例来保存 bookinfo 评级数据, 然后我修改[Bookinfo示例应用程序](/docs/examples/bookinfo/)以使用我的数据库。

### 为评级数据设置数据库

为此，我设置了 [MySQL](https://www.mysql.com) 的实例, 你可以使用任何 MySQL 实例; 我使用[Compose for MySQL](https://www.ibm.com/cloud/compose/mysql), 我使用`mysqlsh`（[MySQL Shell](https://dev.mysql.com/doc/mysql-shell/en/)）作为 MySQL 客户端来提供评级数据。

1. 要初始化数据库，我会在出现提示时运行以下命令输入密码, 该命令使用 `admin` 用户的凭据执行，默认情况下由[Compose for MySQL](https://www.ibm.com/cloud/compose/mysql)创建。

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>
    {{< /text >}}

    _**或者**_

    使用`mysql`客户端和本地MySQL数据库时，我会运行：

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysql -u root -p
    {{< /text >}}

1. 然后我创建一个名为 _bookinfo_ 的用户，并在`test.ratings` 表上授予它 _SELECT_ 权限：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>  \
    -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    _**或者**_

    对于`mysql`和本地数据库，命令将是：

    {{< text bash >}}
    $ mysql -u root -p -e \
    "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    在这里，我应用[最小特权原则](https://en.wikipedia.org/wiki/Principle_of_least_privilege), 这意味着我不在 Bookinfo 应用程序中使用我的 _admin_ 用户, 相反，我为应用程序 Bookinfo 创建了一个最小权限的特殊用户 _bookinfo_ , 在这种情况下，_bookinfo_ 用户只对单个表具有“SELECT”特权。

    在运行命令创建用户之后，我将通过检查最后一个命令的编号并运行`history -d <创建用户的命令编号>` 来清理我的bash历史记录, 我不希望新用户的密码存储在bash历史记录中, 如果我使用`mysql`，我也会删除`~/.mysql_history`文件中的最后一个命令, 在[MySQL文档](https://dev.mysql.com/doc/refman/5.5/en/create-user.html)中阅读有关新创建用户的密码保护的更多信息。

1. 我检查创建的评级，看看一切都按预期工作：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u bookinfo -p --host <the database host> --port <the database port> \
    -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

    _**或者**_

    对于`mysql`和本地数据库：

    {{< text bash >}}
    $ mysql -u bookinfo -p -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

1. 我暂时将评级设置为1，以便在 Bookinfo _ratings_ 服务使用我们的数据库时提供可视线索：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>  \
    -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    _**或**_

    对于`mysql`和本地数据库：

    {{< text bash >}}
    $ mysql -u root -p -e "update test.ratings set rating=1; select * from  test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    我在最后一个命令中使用了 _admin_ 用户（和 _root_ 用于本地数据库），因为 _bookinfo_ 用户在 `test.ratings` 表上没有 _UPDATE_ 权限。

现在我准备部署使用外部数据库的 Bookinfo 应用程序版本。

### Bookinfo 应用程序的初始设置

为了演示使用外部数据库的场景，我首先使用安装了 [Istio](/docs/setup/kubernetes/quick-start/#installation-steps) 的 Kubernetes 集群, 然后我部署 [Istio Bookinfo示例应用程序](/docs/examples/bookinfo/), 此应用程序使用 _ratings_ 服务来获取书籍评级，评分在1到5之间。评级显示为每个评论的星号, 有几个版本的 _ratings_ 微服务, 有些人使用 [MongoDB](https://www.mongodb.com)，其他人使用 [MySQL](https://www.mysql.com) 作为他们的数据库。

此博客文章中的示例命令与  Istio 0.3+ 一起使用，无论启用或不启用 [双向 TLS](/docs/concepts/security/mutual-tls/)。

提醒一下，这是 [Bookinfo 示例应用程序](/docs/examples/bookinfo/)中应用程序的原始整体架构图。

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="原始的 Bookinfo 应用程序"
    >}}

### 将数据库用于 Bookinfo 应用程序中的评级数据

1. 我修改了使用 MySQL 数据库的 _ratings_ 服务版本的 `deployment spec`，以使用我的数据库实例, 该 `spec` 位于 Istio 发行档案的`samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml`中, 我编辑以下几行：

    {{< text yaml >}}
    - name: MYSQL_DB_HOST
      value: mysqldb
    - name: MYSQL_DB_PORT
      value: "3306"
    - name: MYSQL_DB_USER
      value: root
    - name: MYSQL_DB_PASSWORD
      value: password
    {{< /text >}}

    我替换上面代码段中的值，指定数据库主机，端口，用户和密码, 请注意，在 Kubernetes 中使用容器环境变量中密码的正确方法是[使用 secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables), 仅对于此示例任务，我直接在 deployment spec 中编写密码 , **切记！ 不要在真实环境中这样做**！, 我还假设每个人都知道到“密码”不应该明文配置在配置文件中

1. 我应用修改后的 `spec` 来部署使用外部数据库的 _ratings_ 服务，_v2-mysql_ 的版本。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" created
    {{< /text >}}

1. 我将发往 _reviews_ 服务的所有流量路由到 _v3_ 版本, 我这样做是为了确保 _reviews_ 服务始终调用 _ratings_
  服务, 此外，我将发往 _ratings_ 服务的所有流量路由到使用外部数据库的 _ratings v2-mysql_, 我通过添加两个[路由规则](/docs/reference/config/istio.routing.v1alpha1/)为上述两种服务添加路由, 这些规则在 Istio 发行档案的`samples/bookinfo/networking/virtual-service-ratings-mysql.yaml`中指定。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    Created config route-rule/default/ratings-test-v2-mysql at revision 1918799
    Created config route-rule/default/reviews-test-ratings-v2 at revision 1918800
    {{< /text >}}

更新的架构如下所示, 请注意，网格内的蓝色箭头标记根据我们添加的路径规则配置的流量, 根据路由规则，流量将发送到 _reviews v3_ 和 _ratings v2-mysql_ 。

{{< image width="80%" ratio="59.31%"
    link="/blog/2018/egress-tcp/bookinfo-ratings-v2-mysql-external.svg"
    caption="Bookinfo 应用程序，其评级为 v2-mysql，外部为 MySQL 数据库"
    >}}

请注意，MySQL 数据库位于 Istio 服务网格之外，或者更准确地说是在 Kubernetes 集群之外, 服务网格的边界由虚线标记。

### 访问网页

在[确定入口IP和端口](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port)之后，让我们访问应用程序的网页。

我们遇到了问题...在每次审核下方都会显示消息 _“Ratings service is currently unavailable”_  而不是评级星标。

{{< image width="80%" ratio="36.19%"
    link="/blog/2018/egress-tcp/errorFetchingBookRating.png"
    caption="Ratings 服务的错误信息"
    >}}

与[使用外部Web服务](/blog/2018/egress-https/)一样，我们体验到**优雅的服务降级**，这很好, 虽然 _ratings_ 服务中有错误，但是应用程序并没有因此而崩溃, 应用程序的网页正确显示了书籍信息，详细信息和评论，只是没有评级星。

我们遇到的问题与[使用外部Web服务](/blog/2018/egress-https/)中的问题相同，即 Kubernetes 集群外的所有流量（TCP和HTTP）都被 sidecar 代理默认阻止, 要为 TCP 启用此类流量，必须定义 TCP 的出口规则。

### 外部 MySQL 实例的出口规则

TCP 出口规则来救我们, 我将以下 YAML `spec` 复制到一个文本文件（让我们称之为`egress-rule-mysql.yaml`）并编辑它以指定我的数据库实例的 IP 及其端口。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: EgressRule
metadata:
  name: mysql
  namespace: default
spec:
  destination:
      service: <MySQL instance IP>
  ports:
      - port: <MySQL instance port>
        protocol: tcp
{{< /text >}}

然后我运行 `istioctl` 将出口规则添加到服务网格：

{{< text bash >}}
$ istioctl create -f egress-rule-mysql.yaml
Created config egress-rule/default/mysql at revision 1954425
{{< /text >}}

请注意，对于 TCP 出口规则，我们将 `tcp` 指定为规则端口的协议, 另请注意，我们使用外部服务的 IP 而不是其域名, 下面我将详细讨论 TCP 出口规则, 现在，让我们验证我们添加的出口规则是否解决了问题, 让我们访问网页，看看评星是否回来了。

有效！ 访问应用程序的网页会显示评级而不会出现错误：

{{< image width="80%" ratio="36.69%"
    link="/blog/2018/egress-tcp/externalMySQLRatings.png"
    caption="Book Ratings 显示正常"
    >}}

请注意，正如预期的那样，我们会看到两个显示评论的一星评级, 我将评级更改为一颗星，为我们提供了一个视觉线索，确实使用了我们的外部数据库。

与 HTTP/HTTPS 的出口规则一样，我们可以动态地使用 `istioctl` 删除和创建 TCP 的出口规则。

## 出口 TCP 流量控制的动机

一些网内 Istio 应用程序必须访问外部服务，例如遗留系统, 在许多情况下，不通过 HTTP 或 HTTPS 协议执行访问, 使用其他 TCP 协议，例如[MongoDB wire 协议](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/)和[MySQL客户端/服务器协议](https://dev.mysql.com/doc/internals/en/client-server-protocol.html)等特定于数据库的协议, 与外部数据库通信。

请注意，如果访问外部 HTTPS 服务，如[控制出口TCP流量](/docs/tasks/traffic-management/egress/)任务中所述，应用程序必须向外部服务发出 HTTP 请求, 附加到 pod 或 VM 的 Envoy sidecar 代理将拦截请求并打开与外部服务的 HTTPS 连接, 流量将在 pod 或 VM 内部未加密，但会使 pod 或 VM 加密。

但是，由于以下原因，有时这种方法无法工作：

* 应用程序的代码配置为使用 HTTPS URL，无法更改

* 应用程序的代码使用一些库来访问外部服务，该库仅使用 HTTPS

* 即使流量仅在 Pod 或 VM 内部未加密，也存在不允许未加密流量的合规性要求

在这种情况下，HTTPS 可以被 Istio 视为 _opaque TCP_ ，并且可以像处理其他 TCP 非 HTTP 协议一样处理。

接下来让我们看看我们如何定义 TCP 流量的出口规则。

## TCP 流量的出口规则

启用到特定端口的 TCP 流量的出口规则必须指定 “TCP” 作为端口的协议, 此外，对于[MongoDB wire协议](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/)，协议可以指定为“MONGO”，而不是“TCP”。

对于规则的`destination.service`字段，必须使用[CIDR](https://tools.ietf.org/html/rfc2317)表示法中的 IP 或 IP 块。

要通过其主机名启用到外部服务的 TCP 流量，必须指定主机名的所有 IP, 每个 IP 必须由 CIDR 块指定或作为单个IP 指定，每个块或 IP 在单独的出口规则中。

请注意，外部服务的所有 IP 并不总是已知, 要通过 IP 启用 TCP 流量，而不是通过主机名启用流量，只需指定应用程序使用的 IP。

另请注意，外部服务的 IP 并不总是静态的，例如在 [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network) 的情况下, 有时 IP 在大多数情况下是静态的，但可以不时地更改，例如由于基础设施的变化, 在这些情况下，如果已知可能 IP 的范围，则应通过 CIDR 块指定范围（如果需要，甚至可以通过多个出口规则）, 如果不知道可能的IP的范围，则不能使用 TCP 的出口规则，并且[必须直接调用外部服务](/docs/tasks/traffic-management/egress/#calling-external-services-directly), 绕过 sidecar 代理。

## 与网格扩展的关系

请注意，本文中描述的场景与[集成虚拟机](/docs/examples/integrating-vms/)示例中描述的网格扩展场景不同, 在这种情况下，MySQL 实例在与 Istio 服务网格集成的外部（集群外）机器（裸机或VM）上运行 , MySQL 服务成为网格的一流公民，具有 Istio 的所有有益功能, 除此之外，服务可以通过本地集群域名寻址，例如通过`mysqldb.vm.svc.cluster.local`，并且可以通过[双向 TLS 身份验证](/docs/concepts/security/#mutual-tls-authentication)保护与它的通信, 无需创建出口规则来访问此服务; 但是，该服务必须在 Istio 注侧, 要启用此类集成，必须在计算机上安装 Istio 组件（ _Envoy proxy_ ，_node-agent_ ，_istio-agent_ ），并且必须可以从中访问 Istio 控制平面（_Pilot_ ，_Mixer_ ，_CA_ ）, 有关详细信息，请参阅[Istio Mesh Expansion](/docs/setup/kubernetes/mesh-expansion/)说明。

在我们的示例中，MySQL 实例可以在任何计算机上运行，也可以由云提供商作为服务进行配置, 无需集成机器
与 Istio , 无需从机器访问 Istio 控制平面, 在 MySQL 作为服务的情况下，MySQL 运行的机器可能无法访问并在其上安装所需的组件可能是不可能的, 在我们的例子中，MySQL 实例可以通过其全局域名进行寻址，如果消费应用程序希望使用该域名，这可能是有益的, 当在消费应用程序的部署配置中无法更改预期的域名时，这尤其重要。

## 清理

1. 删除 _test_ 数据库和 _bookinfo_ 用户：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> \
    -e "drop database test; drop user bookinfo;"
    {{< /text >}}

    _**或者**_

    对于`mysql`和本地数据库：

    {{< text bash >}}
    $ mysql -u root -p -e "drop database test; drop user bookinfo;"
    {{< /text >}}

1. 删除路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    Deleted config: route-rule/default/ratings-test-v2-mysql
    Deleted config: route-rule/default/reviews-test-ratings-v2
    {{< /text >}}

1. 取消部署 _ratings v2-mysql_ ：

    {{< text bash >}}
    $ kubectl delete -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" deleted
    {{< /text >}}

1. 删除出口规则：

    {{< text bash >}}
    $ istioctl delete egressrule mysql -n default
    Deleted config: egressrule mysql
    {{< /text >}}

## 未来的工作

在我的下一篇博客文章中，我将展示组合路由规则和出口规则的示例，以及通过 Kubernetes _ExternalName_ services 访问外部服务的示例。

## 结论

在这篇博文中，我演示了 Istio 服务网格中的微服务如何通过 TCP 使用外部服务, 默认情况下，Istio 会阻止所有流量（TCP 和 HTTP）到群集外的主机， 要为 TCP 启用此类流量，必须为服务网格创建 TCP 出口规则。
