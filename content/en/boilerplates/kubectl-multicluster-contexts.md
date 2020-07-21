---
---
*   You can use the `kubectl` command to access both the `cluster1` and `cluster2` clusters with the `--context` flag,
    for example `kubectl get pods --context cluster1`.
    Use the following command to list your contexts:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

*   Store the context names of your clusters in environment variables:

    {{< text bash >}}
    $ export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
    $ export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')
    $ echo CTX_CLUSTER1 = ${CTX_CLUSTER1}, CTX_CLUSTER2 = ${CTX_CLUSTER2}
    CTX_CLUSTER1 = cluster1, CTX_CLUSTER2 = cluster2
    {{< /text >}}

    {{< tip >}}
    If you have more than two clusters in the context list and you want to configure your mesh using clusters other than
    the first two, you will need to manually set the environment variables to the appropriate context names.
    {{< /tip >}}
