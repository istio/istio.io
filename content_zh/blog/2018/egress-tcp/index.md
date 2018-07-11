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

在我之前的博客文章[Consuming External Web Services]（/ blog / 2018 / egress-https /）中，我描述了如何通过HTTPS在网状Istio应用程序中使用外部服务。, 在这篇文章中，我演示了通过TCP消费外部服务。, 我使用[Istio Bookinfo示例应用程序]（/ docs / examples / bookinfo /），这是将书籍评级数据保存在MySQL数据库中的版本。, 我在集群外部署此数据库并配置_ratings_ microservice以使用它。, 我定义了[出口规则]（/ docs / reference / config / istio.routing.v1alpha1 / #EdressRule）以允许网内应用程序访问外部数据库。

## Bookinfo示例应用程序与外部评级数据库

首先，我在Kubernetes集群之外设置了一个MySQL数据库实例来保存图书评级数据。, 然后我修改[Bookinfo示例应用程序]（/ docs / examples / bookinfo /）以使用我的数据库。

### 为评级数据设置数据库

为此，我设置了[MySQL]（https://www.mysql.com）的实例。, 你可以使用任何MySQL实例;, 我使用[Compose for MySQL]（https://www.ibm.com/cloud/compose/mysql）。, 我使用`mysqlsh`（[MySQL Shell]（https://dev.mysql.com/doc/mysql-shell/en/））作为MySQL客户端来提供评级数据。

1.要初始化数据库，我会在出现提示时运行以下命令输入密码。, 该命令使用`admin`用户的凭据执行，默认情况下由[Compose for MySQL]（https://www.ibm.com/cloud/compose/mysql）创建。

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>
    {{< /text >}}

    _**或**_

    使用`mysql`客户端和本地MySQL数据库时，我会运行：

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysql -u root -p
    {{< /text >}}

1.然后我创建一个名为_bookinfo_的用户，并在`test.ratings`表上授予它_SELECT_权限：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>  \
    -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    _**OR**_

    对于`mysql`和本地数据库，命令将是：

    {{< text bash >}}
    $ mysql -u root -p -e \
    "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}
    
    在这里，我应用[最小特权原则]（https://en.wikipedia.org/wiki/Principle_of_least_privilege）。, 这意味着我不在Bookinfo应用程序中使用我的_admin_用户。, 相反，我使用最小权限为Bookinfo应用程序_bookinfo_创建了一个特殊用户。, 在这种情况下，_bookinfo_用户只对单个表具有“SELECT”特权。
    
    在运行命令创建用户之后，我将通过检查最后一个命令的编号并运行`history -d <创建用户的命令编号>来清理我的bash历史记录。, 我不希望新用户的密码存储在bash历史记录中。, 如果我使用`mysql`，我也会删除`〜/ .mysql_history`文件中的最后一个命令。, 在[MySQL文档]（https://dev.mysql.com/doc/refman/5.5/en/create-user.html）中阅读有关新创建用户的密码保护的更多信息。

1.  我检查创建的评级，看看一切都按预期工作：

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

    _**或**_

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

1.  我暂时将评级设置为1，以便在Bookinfo _ratings_服务使用我们的数据库时提供可视线索：

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
    
    我在最后一个命令中使用了_admin_用户（和_root_用于本地数据库），因为_bookinfo_用户在`test.ratings`表上没有_UPDATE_权限。

现在我准备部署将使用我的数据库的Bookinfo应用程序版本。

### Bookinfo应用程序的初始设置

为了演示使用外部数据库的场景，我首先使用安装了[Istio]的Kubernetes集群（/ docs / setup / kubernetes / quick-start /＃installation-steps）。, 然后我部署[Istio Bookinfo示例应用程序]（/ docs / examples / bookinfo /）。, 此应用程序使用_ratings_微服务来获取书籍评级，数字在1到5之间。评级显示为每个评论的星号。, 有几个版本的_ratings_ microservice。, 有些人使用[MongoDB]（https://www.mongodb.com），其他人使用[MySQL]（https://www.mysql.com）作为他们的数据库。

此博客文章中的示例命令与Istio 0.3+一起使用，启用或不启用[Mutual TLS]（/ docs / concepts / security / mutual-tls /）。

提醒一下，这是[Bookinfo示例应用程序]（/ docs / examples / bookinfo /）中应用程序的端到端架构。

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The original Bookinfo application"
    >}}

### 将数据库用于Bookinfo应用程序中的评级数据

1.  我修改了使用MySQL数据库的_ratings_微服务版本的部署规范，以使用我的数据库实例。, 该规范位于Istio发行档案的`samples / bookinfo / kube / bookinfo-ratings-v2-mysql.yaml`中。, 我编辑以下几行：

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

    我替换上面代码段中的值，指定数据库主机，端口，用户和密码。, 请注意，在Kubernetes中使用容器环境变量中密码的正确方法是[使用机密]（https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables）。, 仅对于此示例任务，我直接在部署规范中编写密码。 , **不要在真实环境中这样做**！, 我还假设每个人都意识到“密码”不应该用作密码......

1.  我应用修改后的规范来部署将使用我的数据库的_ratings_ microservice，_v2-mysql_的版本。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" created
    {{< /text >}}

1.  我将发往_reviews_服务的所有流量路由到其_v3_版本。, 我这样做是为了确保_reviews_服务始终调用_ratings_
服务。, 此外，我将发往_ratings_服务的所有流量路由到使用我的数据库的_ratings v2-mysql_。, 我通过添加两个[路由规则]（/ docs / reference / config / istio.routing.v1alpha1 /）为上述两种服务添加路由。, 这些规则在Istio发行档案的`samples / bookinfo / kube / route-rule-ratings-mysql.yaml`中指定。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/kube/route-rule-ratings-mysql.yaml@
    Created config route-rule/default/ratings-test-v2-mysql at revision 1918799
    Created config route-rule/default/reviews-test-ratings-v2 at revision 1918800
    {{< /text >}}

更新的架构如下所示。, 请注意，网格内的蓝色箭头标记根据我们添加的路径规则配置的流量。, 根据路由规则，流量将发送到_reviews v3_和_ratings v2-mysql_。

{{< image width="80%" ratio="59.31%"
    link="./bookinfo-ratings-v2-mysql-external.svg"
    caption="The Bookinfo application with ratings v2-mysql and an external MySQL database"
    >}}

请注意，MySQL数据库位于Istio服务网格之外，或者更准确地说是在Kubernetes集群之外。, 服务网格的边界由虚线标记。

### 访问网页

在[确定入口IP和端口]（/ docs / examples / bookinfo / #infinition-the-ingress-ip-and-port）之后，让我们访问应用程序的网页。

我们遇到了问题...在每次审核下方都会显示消息_“评级服务当前不可用”_而不是评级星标。

{{< image width="80%" ratio="36.19%"
    link="./errorFetchingBookRating.png"
    caption="The Ratings service error messages"
    >}}

与[使用外部Web服务]（/ blog / 2018 / egress-https /）一样，我们体验**优雅的服务降级**，这很好。, 由于_ratings_ microservice中的错误，应用程序没有崩溃。, 应用程序的网页正确显示了书籍信息，详细信息和评论，只是没有评级星。

我们遇到的问题与[使用外部Web服务]（/ blog / 2018 / egress-https /）中的问题相同，即Kubernetes集群外的所有流量（TCP和HTTP）都被边车代理默认阻止。, 要为TCP启用此类流量，必须定义TCP的出口规则。

### 外部MySQL实例的出口规则

TCP出口规则来救我们。, 我将以下YAML规范复制到一个文本文件（让我们称之为`egress-rule-mysql.yaml`）并编辑它以指定我的数据库实例的IP及其端口。

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

然后我运行`istioctl`将出口规则添加到服务网格：

{{< text bash >}}
$ istioctl create -f egress-rule-mysql.yaml
Created config egress-rule/default/mysql at revision 1954425
{{< /text >}}

请注意，对于TCP出口规则，我们将`tcp`指定为规则端口的协议。, 另请注意，我们使用外部服务的IP而不是其域名。, 我将详细讨论TCP出口规则[下面]（＃egress-rules-for-tcp-traffic）。, 现在，让我们验证我们添加的出口规则是否解决了问题。, 让我们访问网页，看看明星是否回来了。

有效！, 访问应用程序的网页会显示评级而不会出现错误：

{{< image width="80%" ratio="36.69%"
    link="./externalMySQLRatings.png"
    caption="Book Ratings Displayed Correctly"
    >}}

请注意，正如预期的那样，我们会看到两个显示评论的一星评级。, 我将评级更改为一颗星，为我们提供了一个视觉线索，确实使用了我们的外部数据库。

与HTTP / HTTPS的出口规则一样，我们可以动态地使用`istioctl`删除和创建TCP的出口规则。

## 出口TCP流量控制的动机

一些网内Islation应用程序必须访问外部服务，例如遗留系统。, 在许多情况下，不通过HTTP或HTTPS协议执行访问。, 使用其他TCP协议，例如[MongoDB有线协议]（https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/）和[MySQL客户端/服务器协议]（https）等特定于数据库的协议, ：//dev.mysql.com/doc/internals/en/client-server-protocol.html）与外部数据库通信。

请注意，如果访问外部HTTPS服务，如[控制出口TCP流量]（/ docs / tasks / traffic-management / egress /）任务中所述，应用程序必须向外部服务发出HTTP请求。, 附加到pod或VM的Envoy边车代理将拦截请求并打开与外部服务的HTTPS连接。, 流量将在pod或VM内部未加密，但会使pod或VM加密。

但是，由于以下原因，有时这种方法无法工作：

* 应用程序的代码配置为使用HTTPS URL，无法更改

* 应用程序的代码使用一些库来访问外部服务，该库仅使用HTTPS

* 即使流量仅在Pod或VM内部未加密，也存在不允许未加密流量的合规性要求

在这种情况下，HTTPS可以被Istio视为_opaque TCP_，并且可以像处理其他TCP非HTTP协议一样处理。

接下来让我们看看我们如何定义TCP流量的出口规则。

## TCP流量的出口规则

启用到特定端口的TCP流量的出口规则必须指定“TCP”作为端口的协议。, 此外，对于[MongoDB有线协议]（https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/），协议可以指定为“MONGO”，而不是“TCP”。

对于规则的`destination.service`字段，必须使用[CIDR]（https://tools.ietf.org/html/rfc2317）表示法中的IP或IP块。

要通过其主机名启用到外部服务的TCP流量，必须指定主机名的所有IP。, 每个IP必须由CIDR块指定或作为单个IP指定，每个块或IP在单独的出口规则中。

请注意，外部服务的所有IP并不总是已知。, 要通过IP启用TCP流量，而不是通过主机名启用流量，只需指定应用程序使用的IP。

另请注意，外部服务的IP并不总是静态的，例如在[CDNs]（https://en.wikipedia.org/wiki/Content_delivery_network）的情况下。, 有时IP在大多数情况下是静态的，但可以不时地更改，例如由于基础设施的变化。, 在这些情况下，如果已知可能IP的范围，则应通过CIDR块指定范围（如果需要，甚至可以通过多个出口规则）。, 如果不知道可能的IP的范围，则不能使用TCP的出口规则，并且[必须直接调用外部服务]（/ docs / tasks / traffic-management / egress /＃calling-external-services-direct），, 绕过边车代理人。

## 与网格扩展的关系

请注意，本文中描述的场景与[集成虚拟机]（/ docs / examples / integrate-vms /）示例中描述的网格扩展场景不同。, 在这种情况下，MySQL实例在与Istio服务网格集成的外部（集群外）机器（裸机或VM）上运行。 , MySQL服务成为网格的一流公民，具有Istio的所有有益功能。, 除此之外，服务可以通过本地集群域名寻址，例如通过`mysqldb.vm.svc.cluster.local`，并且可以通过[相互TLS身份验证]保护与它的通信（/ docs / concepts /, 安全/互-TLS /）。, 无需创建出口规则来访问此服务;, 但是，该服务必须在Istio注册。, 要启用此类集成，必须在计算机上安装Istio组件（_Envoy proxy_，_node-agent_，_istio-agent_），并且必须可以从中访问Istio控制平面（_Pilot_，_Mixer _，_ CA_）。, 有关详细信息，请参阅[Istio Mesh Expansion]（/ docs / setup / kubernetes / mesh-expansion /）说明。

在我们的示例中，MySQL实例可以在任何计算机上运行，​​也可以由云提供商作为服务进行配置。, 无需集成机器
与Istio。, 无需从机器访问Istio控制平面。, 在MySQL作为服务的情况下，MySQL运行的机器可能无法访问并在其上安装所需的组件可能是不可能的。, 在我们的例子中，MySQL实例可以通过其全局域名进行寻址，如果消费应用程序希望使用该域名，这可能是有益的。, 当在消费应用程序的部署配置中无法更改预期的域名时，这尤其重要。

## 清理

1.  删除_test_数据库和_bookinfo_用户：

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> \
    -e "drop database test; drop user bookinfo;"
    {{< /text >}}

    _**OR**_

    对于`mysql`和本地数据库：

    {{< text bash >}}
    $ mysql -u root -p -e "drop database test; drop user bookinfo;"
    {{< /text >}}

1.  删除路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/kube/route-rule-ratings-mysql.yaml@
    Deleted config: route-rule/default/ratings-test-v2-mysql
    Deleted config: route-rule/default/reviews-test-ratings-v2
    {{< /text >}}

1.  取消部署_ratings v2-mysql_：

    {{< text bash >}}
    $ kubectl delete -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" deleted
    {{< /text >}}

1.  删除出口规则：

    {{< text bash >}}
    $ istioctl delete egressrule mysql -n default
    Deleted config: egressrule mysql
    {{< /text >}}

## 未来的工作

在我的下一篇博客文章中，我将展示组合路由规则和出口规则的示例，以及通过Kubernetes _ExternalName_ services访问外部服务的示例。

## 结论

在这篇博文中，我演示了Istio服务网格中的微服务如何通过TCP使用外部服务。, 默认情况下，Istio会阻止所有流量（TCP和HTTP）到群集外的主机。, 要为TCP启用此类流量，必须为服务网格创建TCP出口规则。
