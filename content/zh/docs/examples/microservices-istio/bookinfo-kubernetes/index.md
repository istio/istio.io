---
title: 使用 Kubernetes 运行 Bookinfo
overview: 在 Kubernetes 中部署使用 ratings 微服务的 Bookinfo 应用。
weight: 30

---

{{< boilerplate work-in-progress >}}

该模块显示了一个应用程序，它由四种以不同编程语言编写的微服务组成：`productpage`、`details`、`ratings` 和 `reviews`。我们将组成的应用程序称为 `Bookinfo`，您可以在 [Bookinfo 示例](/zh/docs/examples/bookinfo)页面中了解更多信息。

`reviews` 微服务具有三个版本：`v1`、`v2`、`v3`，而 [Bookinfo 示例](/zh/docs/examples/bookinfo)展示的是该应用的最终版本。在此模块中，应用程序仅使用 `reviews` 微服务的 `v1` 版本。接下来的模块通过多个版本的 `reviews` 微服务增强了应用程序。

## 部署应用程序及测试 pod{#deploy-the-application-and-a-testing-pod}

1.  设置环境变量 `MYHOST` 的值为应用程序的 URL：

    {{< text bash >}}
    $ export MYHOST=$(kubectl config view -o jsonpath={.contexts..namespace}).bookinfo.com
    {{< /text >}}

1.  浏览 [`bookinfo.yaml`]({{< github_blob >}}/samples/bookinfo/platform/kube/bookinfo.yaml)。
    这是该应用的 Kubernetes 部署规范。注意 services 和 deployments。

1.  部署应用到 Kubernetes 集群：

    {{< text bash >}}
    $ kubectl apply -l version!=v2,version!=v3 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
    service "details" created
    deployment "details-v1" created
    service "ratings" created
    deployment "ratings-v1" created
    service "reviews" created
    deployment "reviews-v1" created
    service "productpage" created
    deployment "productpage-v1" created
    {{< /text >}}

1.  检查 pods 的状态：

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          10s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          8s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          9s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          9s
    {{< /text >}}

1.  四个服务达到 `Running` 状态后，就可以扩展 deployment。要使每个微服务的每个版本在三个 pods 中运行，请执行以下命令：

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 3
    deployment "details-v1" scaled
    deployment "productpage-v1" scaled
    deployment "ratings-v1" scaled
    deployment "reviews-v1" scaled
    deployment "reviews-v2" scaled
    deployment "reviews-v3" scaled
    {{< /text >}}

1.  检查 pods 的状态。可以看到每个微服务都有三个 pods：

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   0          50s
    details-v1-6d86fd9949-mksv7     1/1     Running   0          50s
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          1m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          50s
    productpage-v1-c9965499-nccwq   1/1     Running   0          50s
    productpage-v1-c9965499-tjdjx   1/1     Running   0          1m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          50s
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          50s
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          49s
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          1m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          49s
    {{< /text >}}

1.  部署测试 pod，[sleep]({{< github_tree >}}/samples/sleep)，用来向您的微服务发送请求：

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

1.  从测试 pod 中用 curl 命令发送请求给 Bookinfo 应用，以确认该应用运行正常：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## 启用对应用的外部访问{#enable-external-access-to-the-application}

应用程序运行后，使集群外部的客户端可以访问它。成功配置以下步骤后，即可从笔记本电脑的浏览器访问该应用程序。

{{< warning >}}

如果您的集群运行于 GKE，请将 `productpage` service 的类型修改为 `LoadBalancer`，如以下示例所示：

{{< text bash >}}
$ kubectl patch svc productpage -p '{"spec": {"type": "LoadBalancer"}}'
service/productpage patched
{{< /text >}}

{{< /warning >}}

### 配置 Kubernetes Ingress 资源并访问应用页面{#configure-the-Kubernetes-Ingress-resource-and-access-your-application-webpage}

1.  创建 Kubernetes Ingress 资源：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: bookinfo
    spec:
      rules:
      - host: $MYHOST
        http:
          paths:
          - path: /productpage
            backend:
              serviceName: productpage
              servicePort: 9080
          - path: /login
            backend:
              serviceName: productpage
              servicePort: 9080
          - path: /logout
            backend:
              serviceName: productpage
              servicePort: 9080
          - path: /static
            backend:
              serviceName: productpage
              servicePort: 9080
    EOF
    {{< /text >}}

### 更新 `/etc/hosts` 配置文件{#update-your-etc-hosts-configuration-file}

1.  将以下命令的输出内容追加到 `/etc/hosts` 文件。您应当具有[超级用户](https://en.wikipedia.org/wiki/Superuser)权限，并且可能需要使用 [`sudo`](https://en.wikipedia.org/wiki/Sudo) 来编辑 `/etc/hosts`。

    {{< text bash >}}
    $ echo $(kubectl get ingress istio-system -n istio-system -o jsonpath='{..ip} {..host}') $(kubectl get ingress bookinfo -o jsonpath='{..host}')
    {{< /text >}}

### 访问应用{#access-your-application}

1.  用以下命令访问应用主页：

    {{< text bash >}}
    $ curl -s $MYHOST/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

1.  将以下命令的输出内容粘贴到浏览器的地址栏：

    {{< text bash >}}
    $ echo http://$MYHOST/productpage
    {{< /text >}}

    可以看到以下页面：

    {{< image width="80%"
        link="bookinfo.png"
        caption="Bookinfo Web Application"
        >}}

1.  观察微服务是如何互相调用的。例如，`reviews` 使用 URL `http://ratings:9080/ratings` 调用 `ratings` 微服务。
    查看 [`reviews` 的代码]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java)：

    {{< text java >}}
    private final static String ratings_service = "http://ratings:9080/ratings";
    {{< /text >}}

1.  在一个单独的终端窗口中设置无限循环，将流量发送到您的应用程序，以模拟现实世界中恒定的用户流量：

    {{< text bash >}}
    $ while :; do curl -s $MYHOST/productpage | grep -o "<title>.*</title>"; sleep 1; done
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    <title>Simple Bookstore App</title>
    ...
    {{< /text >}}

您已经准备好[测试应用](/zh/docs/examples/microservices-istio/production-testing)了。
