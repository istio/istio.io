---
---
*   Puedes usar el comando `kubectl` para acceder a los clusteres `cluster1` y `cluster2` con la bandera `--context`,
    por ejemplo, `kubectl get pods --context cluster1`.
    Usa el siguiente comando para listar tus contextos:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

*   Almacena los nombres de contexto de tus clusteres en variables de entorno:

    {{< text bash >}}
    $ export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
    $ export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')
    $ echo "CTX_CLUSTER1 = ${CTX_CLUSTER1}, CTX_CLUSTER2 = ${CTX_CLUSTER2}"
    CTX_CLUSTER1 = cluster1, CTX_CLUSTER2 = cluster2
    {{< /text >}}

    {{< tip >}}
    Si tienes más de dos clusteres en la lista de contextos y quieres configurar tu malla usando clusteres que no sean
    los dos primeros, deberás establecer manualmente las variables de entorno a los nombres de contexto apropiados.
    {{< /tip >}}
