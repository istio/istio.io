---
---
*   您可以使用 `kubectl` 命令带上 `--context` 参数去访问集群 `cluster1` 和 `cluster2`，
    例如 `kubectl get pods --context cluster1`。
    使用如下命令列出您的上下文：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

*   保存集群的上下文到环境变量：

    {{< text bash >}}
    $ export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
    $ export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')
    $ echo "CTX_CLUSTER1 = ${CTX_CLUSTER1}, CTX_CLUSTER2 = ${CTX_CLUSTER2}"
    CTX_CLUSTER1 = cluster1, CTX_CLUSTER2 = cluster2
    {{< /text >}}

    {{< tip >}}
    如果您有超过两个集群的上下文并且您想要使用前两个以外的集群配置您的网格，您需要手动将环境变量设置为您需要的上下文名称。
    {{< /tip >}}
