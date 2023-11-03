---
title: 添加一个新版本的 reviews
overview: 部署一个新版本的微服务。

weight: 50

owner: istio/wg-docs-maintainers
test: no
---

在此模块中，您将部署 reviews 服务的一个新版本 v2，该服务将返回审阅人员提供的评分星级和评级颜色。
在实际场景中，在部署之前，您将在模拟环境中执行静态分析测试、单元测试、集成测试、端到端测试和验证。

1.  部署 `reviews` 不带 `app=reviews` 标签的新版本微服务。没有此标签，
    将不会选择新版本 `reviews` 来提供服务。因此，生产代码不会调用它。 运行以下命令部署 `reviews`
    微服务的版本 2，再更换标签 `app=reviews` 为 `app=reviews_test`：

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | sed 's/app: reviews/app: reviews_test/' | kubectl apply -l app=reviews_test,version=v2 -f -
    deployment.apps/reviews-v2 created
    {{< /text >}}

1.  访问您的应用程序以确保已部署的微服务不会破坏它。

1.  从集群内部使用您之前部署的测试容器测试新版本的微服务。请注意您的新版本在测试期间访问微服务
    ratings 的生产 Pod。还需要注意，您必须使用 Pod IP 访问新版本的微服务，因为它还没有被
    `reviews` 服务选中。

    1.  获取 Pod IP：

        {{< text bash >}}
        $ REVIEWS_V2_POD_IP=$(kubectl get pod -l app=reviews_test,version=v2 -o jsonpath='{.items[0].status.podIP}')
        $ echo $REVIEWS_V2_POD_IP
        {{< /text >}}

    1.  向 Pod 发送请求并查看它是否返回正确结果：

        {{< text bash >}}
        $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl -sS "$REVIEWS_V2_POD_IP:9080/reviews/7"
        {"id": "7","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
        {{< /text >}}

    1.  连续发送 10 次请求来执行原始负载测试：

        {{< text bash >}}
        $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do curl -o /dev/null -s -w '%{http_code}\n' $REVIEWS_V2_POD_IP:9080/reviews/7; done"
        200
        200
        ...
        {{< /text >}}

1.  前面的步骤确保您新版本的 `reviews` 可以正常工作，并且能够对其进行部署。
    您将一个单副本的服务部署到生产中，因此实际生产流量将开始到达您的新服务。在当前的设置下，
    75% 的流量将到达旧版本（三个旧版本的 Pod），而 25% 的流量将到达新版本（单个 Pod）。

    要部署 **reviews v2**，请重新部署带有 `app=reviews` 标签的新版本，以便它能被
    `reviews` 服务寻址。

    {{< text bash >}}
    $ kubectl label pods -l version=v2 app=reviews --overwrite
    pod "reviews-v2-79c8c8c7c5-4p4mn" labeled
    {{< /text >}}

1.  现在，您访问应用程序页面，并观察评级上的黑色星标。您可以多访问几次该页面，
    发现有时返回的页面带有星级（大约 25% 的时间），有时不带星级（大约 75% 的时间）。

    {{< image width="80%"
        link="bookinfo-reviews-v2.png"
        caption="Bookinfo Web Application with black stars as ratings"
        >}}

1.  如果您在实际场景下遇到新版本有任何问题，可以快速取消部署新版本，仅使用旧版本：

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2
    $ kubectl delete pod -l app=reviews,version=v2
    deployment.apps "reviews-v2" deleted
    pod "reviews-v2-79c8c8c7c5-4p4mn" deleted
    {{< /text >}}

    留出时间让配置更改在系统中生效。然后，访问几次您的应用程序页面，现在看到黑色星级没有再出现。

    恢复新版本：

    {{< text bash >}}
    $ kubectl apply -l app=reviews,version=v2 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
    deployment.apps/reviews-v2 created
    {{< /text >}}

    多次访问程序页面，发现大约有 25% 的时间会出现黑色星级。

1.  接下来，增加新版本的副本。您可以慢慢的，仔细地检查没有错误的数量增加。

    {{< text bash >}}
    $ kubectl scale deployment reviews-v2 --replicas=3
    deployment.apps/reviews-v2 scaled
    {{< /text >}}

    现在，您可以访问几次您的应用程序页面，看到黑色星级出现的时间大约是一半。

1.  现在，您可以停用旧版：

    {{< text bash >}}
    $ kubectl delete deployment reviews-v1
    deployment.apps "reviews-v1" deleted
    {{< /text >}}

    访问该应用程序的页面将只返回带有黑色的评级。

在以上步骤中，您执行了更新 `reviews`。首先，您发布了新版本且没有发送模拟生产流量。
您在生产环境中使用测试流量对其进行了测试。您检查了新版本是否提供正确的结果。
您发布了新版本，并逐渐增加其生产流量。最后，您停用了旧版本。

在这里，您可以使用以下示例任务来改进部署策略。首先，在生产中进行端到端测试。
这要求能够使用请求参数（例如使用存储在 Cookie 中的用户名）将流量驱动到新版本。
此外，对新版本的生产流量进行屏蔽，并检查新版本是否提供了错误的结果或者产生了错误。
最后，获得对部署的更详细的控制。例如，您可以部署 1%，然后每小时增加 1%，只要服务没有被降级。
Istio 直接帮助您执行这些任务来增强 Kubernetes 的价值。有关部署的更多详细信息和最佳实践，
请参阅[部署模型](/zh/docs/ops/deployment/deployment-models/)。

在这里，您有两个选择：

1. 使用 **service mesh**。在服务网格中，您将所有报告、路由、策略、安全逻辑放在
   **Sidecar** 代理中，并**透明的**注入到您的应用程序 Pod 中。
   业务逻辑保留在应用程序代码中，无需更改应用程序的代码。

1. 在应用程序代码中实现所需的功能。大多数功能已各种库中提供，例如
   Netflix 的 [Hystrix](https://github.com/Netflix/Hystrix) 在 Java 编程语言中。
   但是，您现在必须修改您的代码才能使用这些库。您的业务代码将膨胀，业务逻辑将与报告、路由、策略、网络逻辑混合在一起。
   由于您的微服务使用不同的编程语言，因此您必须学习、使用和更新多个库。

参阅 [Istio 服务网格](/zh/about/service-mesh/)以了解 Istio 如何执行此处以及更多内容中提到的任务。
接下来的模块中，您将探索 Istio 的各种功能。

您已经准备好[在 `productpage` 中启用 Istio](/zh/docs/examples/microservices-istio/add-istio/)。
