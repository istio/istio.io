---
---
*   Ви можете використовувати команду `kubectl` для доступу до обох кластерів `cluster1` та `cluster2`, використовуючи прапорець `--context`, наприклад, `kubectl get pods --context cluster1`. Використовуйте наступну команду, щоб отримати ваші контексти:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

*   Збережіть імена контекстів ваших кластерів у змінних середовища:

    {{< text bash >}}
    $ export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
    $ export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')
    $ echo "CTX_CLUSTER1 = ${CTX_CLUSTER1}, CTX_CLUSTER2 = ${CTX_CLUSTER2}"
    CTX_CLUSTER1 = cluster1, CTX_CLUSTER2 = cluster2
    {{< /text >}}

    {{< tip >}}
    Якщо у вас більше ніж два кластери у списку контекстів і ви хочете налаштувати свою мережу, використовуючи інші кластери, ніж перші два, вам потрібно буде вручну встановити змінні середовища на відповідні імена контекстів.
    {{< /tip >}}
