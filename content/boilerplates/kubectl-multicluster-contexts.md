---
---
* The `kubectl` command is used to access both the `cluster1` and `cluster2` clusters with the `--context` flag.
  Use the following command to list your contexts:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* Export the following environment variables with the context names of your configuration:

    {{< text bash >}}
    $ export CTX_CLUSTER1=<KUBECONFIG_CONTEXT_NAME_FOR_CLUSTER_1>
    $ export CTX_CLUSTER2=<KUBECONFIG_CONTEXT_NAME_FOR_CLUSTER_2>
    {{< /text >}}
