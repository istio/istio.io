---
title: 网格可视化
description: 本任务展示了在 Istio 网格中对服务进行可视化的过程。
weight: 49
keywords: [可视化,遥测]
---

本任务中展示了如何对 Istio 服务网格进行多角度的可视化。

这个任务中，首先要安装 [Kiali](https://www.kiali.io) 插件，然后使用 Web 界面来查看网格内的服务图以及 Istio 配置对象；最后还要通过 Kiali API 用 JSON 格式生成服务图数据。

任务中用到了  [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用作为测试案例。

## 开始之前

> {{< idea_icon >}} 下面的介绍假设已经安装了 Helm，并使用 Helm 来安装 Kiali。

[Kiali 安装指南](https://www.kiali.io/gettingstarted/)中还介绍了不借助 Helm 安装 Kiali 的方法。

在 Istio 命名空间中创建一个 Secret，作为 Kiali 的认证凭据。[Helm README](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/README.md#installing-the-chart) 中介绍了更多细节。修改并运行下列命令：

```bash
USERNAME=$(echo -n 'admin' | base64)
PASSPHRASE=$(echo -n 'mysecret' | base64)
NAMESPACE=istio-system
kubectl create namespace $NAMESPACE
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $USERNAME
  passphrase: $PASSPHRASE
EOF
```

创建了 Kiali Secret 之后，根据 [Helm 安装简介](/zh/docs/setup/kubernetes/helm-install/) 使用 Helm 来安装 Kiali。在运行 `helm` 命令的时候必须使用 `--set kiali.enabled=true` 选项，例如：

{{< text bash >}}
$ helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

> {{< idea_icon >}} 本文并未涉及 Jaeger 和 Grafana。如果已经在集群中部署了这两个组件，并且希望能够集成到 Kiali 之中，就必须在 `helm` 命令中增加参数：

{{< text bash >}}
    $ helm template \
        --set kiali.enabled=true \
        --set "kiali.dashboard.jaegerURL=http://$(kubectl get svc tracing -o jsonpath='{.spec.clusterIP}'):80" \
        --set "kiali.dashboard.grafanaURL=http://$(kubectl get svc grafana -o jsonpath='{.spec.clusterIP}'):3000" \
        install/kubernetes/helm/istio \
        --name istio --namespace istio-system > $HOME/istio.yaml
    $ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

完成 Istio 和 Kiali 之后，就可以部署 [Bookinfo](/zh/docs/examples/bookinfo/) 应用了。

## 生成服务图

1. 要验证服务是否在集群中正确运行，需要执行如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1. [确定 Bookinfo 的 URL](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口)。

1. 要向网格发送流量，有三种方法：

    * 用浏览器访问 `http://$GATEWAY_URL/productpage`
    * 重复执行下面的命令：

        {{< text bash >}}
        $ curl http://$GATEWAY_URL/productpage
        {{< /text >}}

    * 如果系统中安装了 `watch` 命令，就可以用它来持续发送请求：

        {{< text bash >}}
        $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
        {{< /text >}}

1. 要获得 Kiali 的 URL，可使用和 Bookinfo 相同的 `GATEWAY_URL`，但是使用不同的端口。

    * 如果当前环境具备外部负载均衡器支持，可以运行如下命令：

        {{< text bash >}}
        $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].port}')"
        $ echo $KIALI_URL
        http://172.30.141.9:15029
        {{< /text >}}

    * 如果所在环境中没有负载均衡支持（例如 Minikube），则运行下列命令：

        {{< text bash >}}
        $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].nodePort}')"
        $ echo $KIALI_URL
        http://192.168.99.100:31758
        {{< /text >}}

1. 要浏览 Kiali 界面，用浏览器打开 `$KIALI_URL` 即可。

1. 可以使用前面建立 Secret 时使用的用户名和密码在 Kiali 登录页上进行登录。如果使用的是上面的示例 Secret，那么用户名就是 `admin`，密码就是 `mysecret`。

1. 登录后会显示 **Overview** 页面，这里可以浏览服务网格的概况。

    **Overview** 页面中会显示网格里所有命名空间中的服务。例如下面的截图：

    {{< image width="75%" ratio="58%"
    link="/docs/tasks/telemetry/kiali/kiali-overview.png"
    caption="概览示例"
    >}}

1. 要查看指定命名空间的服务图，可以点击 Bookinfo 命名空间卡片，会显示类似的页面：

    {{< image width="75%" ratio="89%"
    link="/docs/tasks/telemetry/kiali/kiali-graph.png"
    caption="服务图样例"
    >}}

1. 要查看指标的合计，可以在服务图上选择任何节点或者边缘，就会在右边的 Panel 上显示所选指标的详情。

1. 如果希望用不同的图形方式来查看服务网格，可以从 **Graph Type** 下拉菜单进行选择。有多种不同的图形类别可供挑选：**App**、**Versioned App**、**Workload** 以及 **Service**。

    * **App** 类型会将同一应用的所有版本的数据聚合为单一的图形节点，下面的例子展示了一个 **reviews** 节点，其中包含三个版本的 Reviews 应用：

        {{< image width="75%" ratio="35%"
        link="/docs/tasks/telemetry/kiali/kiali-app.png"
        caption="应用图样例"
        >}}

    * **Versioned App** 类型会把一个 App 的每个版本都用一个节点来展示，但是一个应用的所有版本会被汇总在一起，下面的示例中显示了一个在分组框中的 **reviews** 服务，其中包含了三个节点，每个节点都代表 reviews 应用的一个版本：

        {{< image width="75%" ratio="67%"
        link="/docs/tasks/telemetry/kiali/kiali-versionedapp.png"
        caption="分版本应用图样例"
        >}}

    * **Workload** 类型的图会将网格中的每个工作负载都呈现为一个节点。

        这种类型的图不需要读取工作负载的 `app` 和 `version` 标签。所以如果你的工作负载中没有这些标签，这种类型就是个合理选择了。

        {{< image width="70%" ratio="76%"
        link="/docs/tasks/telemetry/kiali/kiali-workload.png"
        caption="工作负载图样例"
        >}}

    * **Service** 图类型为网格中的每个服务生成一个节点，但是会排除所有的应用和工作负载。

        {{< image width="70%" ratio="35%"
        link="/docs/tasks/telemetry/kiali/kiali-service-graph.png"
        caption="服务图样例"
        >}}

1. 要验证 Istio 配置的详情，可以点击左边菜单栏上的 **Applications**、**Workloads** 或者 **Services**。下面的截图展示了 Bookinfo 应用的信息：

   {{< image width="80%" ratio="56%"
   link="/docs/tasks/telemetry/kiali/kiali-services.png"
   caption="详情样例"
   >}}

## 关于 Kiali 的 API

[Kiali API](https://www.kiali.io/api/) 提供了为服务图以及其它指标、健康状况以及配置信息生成 JSON 文件的能力。例如可以用浏览器打开 `$KIALI_URL/api/namespaces/bookinfo/graph?graphType=app`，会看到使用 JSON 格式表达的 `app` 类型的服务图

Kiali API

Kiali API 来自于 Prometheus 查询，并依赖于标准的 Istio 指标配置。它还需要调用 Kubernetes API 来获取关于服务方面的附加信息。为了获得 Kiali 的最佳体验，工作负载应该像 Bookinfo 一样使用 `app` 和 `version` 标签。

## 清理

如果不想继续任何后续任务，可以从集群中移除 Bookinfo 应用以及 Kiali：

1. 参考[清理 Bookinfo](/zh/docs/examples/bookinfo/#清理) 的指导，可以移除 Bookinfo 应用。

1. 要从 Kubernetes 环境中卸载  Kiali，可以删除所有 `app=kiali` 的对象：

{{< text bash >}}
$ kubectl delete all,secrets,sa,configmaps,deployments,ingresses,clusterroles,clusterrolebindings,virtualservices,destinationrules --selector=app=kiali -n istio-system
{{< /text >}}
