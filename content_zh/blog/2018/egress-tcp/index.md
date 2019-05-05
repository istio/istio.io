---
title: 使用外部 TCP 服务
description: 描述基于 Istio 的 Bookinfo 示例的简单场景。
publishdate: 2018-02-06
subtitle: 网格外部 TCP 流量的服务入口
attribution: Vadim Eisenberg
keywords: [traffic-management,egress,tcp]
---

{{< tip >}}
这篇博客在2018年7月23日有修改，修改的内容使用了新的 [v1alpha3 流量管理 API](/zh/blog/2018/v1alpha3-routing/)。如果你想使用旧版本 API，请参考[这个文档](https://archive.istio.io/v0.7/blog/2018/egress-tcp.html)。
{{< /tip >}}

在我之前的博客文章[使用外部 Web 服务](/zh/blog/2018/egress-https/)中，描述了 Istio 服务网格内的应用程序是如何使用 HTTPS 消费外部服务的。在这篇文章中，则会演示通过 TCP 使用外部服务的方法。这里会用到 [Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)，这个版本的应用会把书籍评级数据保存在 MySQL 数据库中。下面的步骤里，会在集群外部署数据库，并配置 `ratings` 服务使用这个数据库，并且还要会定义 [Service Entry](/docs/reference/config/networking/v1alpha3/service-entry/) 以允许网内应用程序访问外部数据库。

## Bookinfo 示例应用程序与外部评级数据库

首先，在 Kubernetes 集群之外部署一个 MySQL 数据库实例来保存 Bookinfo 评级数据，然后修改 [Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)以使用这个数据库。

### 为评级数据设置数据库

根据任务需求，部署一个 [MySQL](https://www.mysql.com) 的实例，这里可以使用任何 MySQL 实例；例如可以使用 [Compose for MySQL](https://www.ibm.com/cloud/compose/mysql)。下面会使用 `mysqlsh`（[MySQL Shell](https://dev.mysql.com/doc/mysql-shell/en/)）作为 MySQL 客户端来提供评级数据。

1. 设置 `MYSQL_DB_HOST` 和 `MYSQL_DB_PORT` 环境变量。

    {{< text bash >}}
    $ export MYSQL_DB_HOST=<你的 MySQL host>
    $ export MYSQL_DB_PORT=<你的 MySQL port>
    {{< /text >}}

    如果你使用的是本地数据库，使用的是默认 MYSQL port，那 `host` 和 `port` 分别是 `localhost` 和 `3306`。

1. 初始化数据库时，如果出现提示，执行下面的命令输入密码。这个命令通过 `admin` 数据库用户凭证来执行。这个 `admin` 用户是通过 [Compose for Mysql](https://www.ibm.com/cloud/compose/mysql) 创建数据库时默认存在的。

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT
    {{< /text >}}

    **或者**

    如果使用的是 `mysql` 客户端和本地 MySQL 数据库时，运行：

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT
    {{< /text >}}

1. 创建一个名为 `bookinfo` 的用户，并在 `test.ratings` 表上授予它 `SELECT` 权限：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    **或者**

    如果用的是 `mysql` 和本地数据库，命令是：

    {{< text bash >}}
    $ mysql -u root -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    在这里，建议使用[最小特权原则](https://en.wikipedia.org/wiki/Principle_of_least_privilege)，这意味着不在 Bookinfo 应用程序中使用 `admin` 用户；而是为应用程序 Bookinfo 创建了一个最小权限的特殊用户 `bookinfo`， 在这种情况下，`bookinfo` 用户只对单个表具有 `SELECT` 特权。

    在运行命令创建用户之后，应该检查最后一个命令的编号并运行 `history -d <创建用户的命令编号>` 来清理我的 bash 历史记录，防止新用户的密码存储在 bash 历史记录中，如果你使用了 `mysql` 命令行工具，记得要删除 `~/.mysql_history` 文件中的最后一个命令。在 [MySQL 文档](https://dev.mysql.com/doc/refman/5.5/en/create-user.html)中阅读有关新创建用户的密码保护的更多信息。

1. 检查创建的评级数据，看看一切都按预期工作：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u bookinfo -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

    **或者**

    对于 `mysql` 和本地数据库：

    {{< text bash >}}
    $ mysql -u bookinfo -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

1. 暂时将评级设置为 `1`，以便在 Bookinfo `ratings` 服务使用我们的数据库时提供可视线索：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:

    Rows matched: 2  Changed: 2  Warnings: 0
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    **或者**

    对于 `mysql` 和本地数据库：

    {{< text bash >}}
    $ mysql -u root -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    因为 `bookinfo` 用户在 `test.ratings` 表上没有 `UPDATE` 权限，所以在最后一个命令中使用了 `admin/root` 用户

现在就已经可以去部署使用外部数据库的 Bookinfo 应用程序版本了。

### Bookinfo 应用程序的初始设置

为了演示使用外部数据库的场景，首先要求有一个安装了 [Istio](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤) 的 Kubernetes 集群，然后部署 [Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)，并[创建默认的 Destination rule 对象](/docs/examples/bookinfo/#apply-default-destination-rules)，还要对 Istio 的缺省策略进行配置，[拦截外发流量](/docs/tasks/traffic-management/egress/#change-to-the-blocking-by-default-policy)

此应用程序使用 `ratings` 微服务来获取书籍评级，评分在 1 到 5 之间。评级显示为每个评论的星号。`ratings` 微服务有几个不同版本，有的会使用 [MongoDB](https://www.mongodb.com)，有的会使用 [MySQL](https://www.mysql.com)。

这篇博客例子里的命令是以 Istio 0.8 以上版本为基础的，不管是否启用了[双向 TLS](/zh/docs/concepts/security/#双向-tls-认证)，都是可用的。

这是 [Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)中应用程序的端到端架构图。

{{< image width="80%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="原始的 Bookinfo 应用程序"
    >}}

### 将数据库用于 Bookinfo 应用程序中的评级数据

1. 修改使用 MySQL 数据库的 `ratings` 服务版本的 `Deployment` 对象的 `spec`，以使用前面搭建的数据库实例。该文件位于 Istio 发行包的 [`samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml`]({{<github_blob>}}/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml) 中。编辑以下几行：

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

    替换上面代码段中的值，指定数据库主机，端口，用户和密码。请注意，在 Kubernetes 中使用容器环境变量中密码的正确方法是[使用 Secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)，在这个示例任务中，我们直接配置了明文密码， **切记！不要在真实环境中这样做**！我想你们应该也知道，`"password"` 这个值也不应该用作密码。

1. 应用修改后的 `spec` 来部署使用外部数据库的 `ratings` 服务，`v2-mysql` 的版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@
    deployment "ratings-v2-mysql" created
    {{< /text >}}

1. 将发往 `reviews` 服务的所有流量路由到 `v3` 版本，这样做是为了确保 `reviews` 服务始终调用 `ratings` 服务，此外，将发往 `ratings` 服务的所有流量路由到使用外部数据库的 `ratings:v2-mysql`。

    添加两个 [`VirtualService`](/docs/reference/config/networking/v1alpha3/virtual-service/)，为上述两个服务指定路由。这些代码保存在 Istio 发行包的 `samples/bookinfo/networking/virtual-service-ratings-mysql.yaml` 中。

    **注意**：确保你在完成了[添加默认目标路由](/zh/docs/examples/bookinfo/#应用缺省目标规则)的步骤之后才执行下面的命令。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    {{< /text >}}

更新的架构如下所示，请注意网格内的蓝色箭头，来自我们添加的 `VirtualService` 定义，将请求发送给 `reviews v3` 和 `ratings v2-mysql`。

{{< image width="80%"
    link="/blog/2018/egress-tcp/bookinfo-ratings-v2-mysql-external.svg"
    caption="Bookinfo 应用程序，ratings 服务是 v2-mysql，使用外部的 MySQL 数据库"
    >}}

请注意，MySQL 数据库位于 Istio 服务网格之外，或者更准确地说是在 Kubernetes 集群之外，服务网格的边界由虚线标记。

### 访问网页

在[确定入口 IP 和端口](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口)之后，访问应用程序的网页。

你会发现问题，在每个评审信息下方都会显示 `"Ratings service is currently unavailable”`  而不是评级星标。

{{< image width="80%" link="/blog/2018/egress-tcp/errorFetchingBookRating.png" caption="Ratings 服务的错误信息" >}}

与[使用外部 Web 服务](/zh/blog/2018/egress-https/)一样，你会体验到**优雅的服务降级**，这很好，虽然 `ratings` 服务中有错误，但是应用程序并没有因此而崩溃，应用程序的网页正确显示了书籍信息，详细信息和评论，只是没有评级星。

你遇到的问题与[使用外部 Web 服务](/zh/blog/2018/egress-https/)中的问题相同，即 Kubernetes 集群外的所有流量（TCP 和 HTTP）都被 Sidecar 代理根据默认策略阻止了，要启用这一访问，必须定义 `ServiceEntry`

### 外部 MySQL 实例的网格外部服务入口

为网格外的服务定义 `ServiceEntry`。

1. 获取你的 MySQL 数据库实例的 IP 地址，例如可以通过 [host](https://linux.die.net/man/1/host) 命令实现：

    {{< text bash >}}
    $ export MYSQL_DB_IP=$(host $MYSQL_DB_HOST | grep " has address " | cut -d" " -f4)
    {{< /text >}}

    如果是本地数据库，设置 `MYSQL_DB_IP` 环境变量为你的本机 IP，保证这个地址能被集群访问到。

1. 为网格外 TCP 服务定义 `ServiceEntry`

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mysql-external
    spec:
      hosts:
      - $MYSQL_DB_HOST
      addresses:
      - $MYSQL_DB_IP/32
      ports:
      - name: tcp
        number: $MYSQL_DB_PORT
        protocol: tcp
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1. 检查你刚刚新增的 `ServiceEntry`，确保它的值是正确的

    {{< text bash >}}
    $ kubectl get serviceentry mysql-external -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
    ...
    {{< /text >}}

请注意，对于 TCP `ServiceEntry`，`port` 的 `protocol` 的值应该设置为 `tcp`；另外注意，要在 `addresses` 列表里面指定外部服务的 IP 地址（一个 `32` 为后缀的 [CIDR](https://tools.ietf.org/html/rfc2317)）。

[后续章节](#tcp-流量的服务入口)中还会详细讨论 TCP `ServiceEntry`。现在先来验证我们添加的出口规则是否解决了问题。访问网页看看评星是否恢复显示。

现在访问应用程序的网页的时候，会显示评级而不会出现错误：

{{< image width="80%" link="/blog/2018/egress-tcp/externalMySQLRatings.png" caption="Book Ratings 显示正常" >}}

正如预期的那样，你会看到两个显示评论的一星评级。将评级更改为一颗星，为我们提供了一个视觉线索，确实使用了我们的外部数据库。

与 HTTP/HTTPS 的服务入口一样，你可以动态地使用 `kubectl` 删除和创建 TCP 的服务入口。

## 出口 TCP 流量控制的动机

一些网内 Istio 应用程序必须访问外部服务，例如遗留系统，在许多情况下，都不是通过 HTTP 或 HTTPS 协议，而是使用其他 TCP 协议完成和外部数据库的通信，例如 [MongoDB wire 协议](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/)和 [MySQL 客户端/服务器协议](https://dev.mysql.com/doc/internals/en/client-server-protocol.html)等特定数据库的协议。

接下来我会再说说 TCP 流量的服务入口。

## TCP 流量的服务入口

启用到特定端口的 TCP 流量的服务入口必须指定 `TCP` 作为端口的协议，此外，对于 [MongoDB wire协议](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/)，协议可以指定为 `MONGO`，而不是 `TCP`。

对于服务入口配置的 `addresses` 字段，必须使用 [CIDR](https://tools.ietf.org/html/rfc2317)表示法中的 IP 块。注意在 TCP 服务入口配置中，`host` 字段会被忽略。

要通过其主机名启用到外部服务的 TCP 流量，必须指定主机名的所有 IP，每个 IP 必须由 CIDR 块指定。

请注意，外部服务的所有 IP 并不总是已知。要往外发送 TCP 流量，只能配置为被应用程序使用的 IP。

另请注意，外部服务的 IP 并不总是静态的，例如 [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network) 的情况。有时 IP 在大多数情况下是静态的，但可以不时地更改，例如由于基础设施的变化。在这些情况下，如果已知可能 IP 的范围，则应通过 CIDR 块指定范围。如果不知道可能的IP的范围，则不能使用 TCP 服务入口。可以绕过 Sidecar 代理，[直接调用外部服务](/zh/docs/tasks/traffic-management/egress/#直接调用外部服务)。

## 与网格扩展的关系

请注意，本文中描述的场景与[集成虚拟机](/zh/docs/examples/integrating-vms/)示例中描述的网格扩展场景不同。在那种场景中，MySQL 实例在与 Istio 服务网格集成的外部（集群外）机器（物理机或虚拟机）上运行，和 Istio 服务网格进行集成。这种情况下，MySQL 服务成为网格的一等公民，具有 Istio 的所有有益功能，服务可以通过本地集群域名寻址，例如通过 `mysqldb.vm.svc.cluster.local`，并且可以通过[双向 TLS 身份验证](/zh/docs/concepts/security/#双向-tls-认证)保护与它的通信，无需创建 `ServiceEntry` 来访问此服务; 但是，该服务必须在 Istio 中进行注册，要启用此类集成，必须在计算机上安装 Istio 组件（ `Envoy proxy` 、`node-agent`、`istio-agent` ），并且必须可以从中访问 Istio 控制平面（`Pilot` ，`Mixer` ，`Citadel`）。有关详细信息，请参阅 [Istio 网格扩展](/zh/docs/setup/kubernetes/additional-setup/mesh-expansion/)的相关说明。

在我们的示例中，MySQL 实例可以在任何计算机上运行，也可以由云提供商作为服务进行配置。无需把服务器集成进 Istio。无需访问 Istio 控制平面。在 MySQL 作为服务的情况下，可能无法直接访问 MySQL 所在的服务器，也无法在服务器上安装所需的组件。在我们的例子中，MySQL 实例可以通过其全局域名进行寻址，如果消费应用程序希望使用该域名，尤其是在消费应用程序的部署配置中无法更改时，这就更重要了。

## 清理

1. 删除 `test` 数据库和 `bookinfo` 用户：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "drop database test; drop user bookinfo;"
    {{< /text >}}

    **或者**

    对于`mysql`和本地数据库：

    {{< text bash >}}
    $ mysql -u root -p --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT -e "drop database test; drop user bookinfo;"
    {{< /text >}}

1. 删除虚拟服务：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    Deleted config: virtual-service/default/reviews
    Deleted config: virtual-service/default/ratings
    {{< /text >}}

1. 取消部署 `ratings v2-mysql` ：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@
    deployment "ratings-v2-mysql" deleted
    {{< /text >}}

1. 删除服务入口：

    {{< text bash >}}
    $ kubectl delete serviceentry mysql-external -n default
    Deleted config: serviceentry mysql-external
    {{< /text >}}

## 结论

本文演示了 Istio 服务网格中的微服务通过 TCP 使用外部服务的方法，默认情况下，Istio 会阻止所有（TCP 和 HTTP）到集群外的主机的流量，要为网格中的服务启用对外的 TCP 流量，必须创建 TCP `ServiceEntry`。
