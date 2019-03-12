* `kubectl` 能通过 `--context` 参数切换上下文，以支持对不同集群 `cluster1` 和 `cluster2` 的访问。
  使用如下命令列出现存的上下文：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* 使用配置的上下文名称导出以下环境变量：

    {{< text bash >}}
    $ export CTX_CLUSTER1=<KUBECONFIG_CONTEXT_NAME_FOR_CLUSTER_1>
    $ export CTX_CLUSTER2=<KUBECONFIG_CONTEXT_NAME_FOR_CLUSTER_2>
    {{< /text >}}
