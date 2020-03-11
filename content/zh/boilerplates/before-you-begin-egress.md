---
---
## 开始之前{#before-you-begin}

*   按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 示例，以获取发送请求的测试源。
    如果您启用了[自动 sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，运行以下命令部署示例应用程序：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，在使用以下命令部署 `sleep` 应用程序之前，手动注入 sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    您可以使用任何安装了 `curl` 的 pod 作为测试源。
    {{< /tip >}}

*   为了发送请求，您需要创建 `SOURCE_POD` 环境变量来存储源 pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}
