---
---
*   启动 [httpbin]\({{< github_tree >}}/samples/httpbin) 样例程序。

    如果您启用了 [sidecar 自动注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，通过以下命令部署 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    否则，您必须在部署 `httpbin` 应用程序前进行手动注入，部署命令如下：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}
