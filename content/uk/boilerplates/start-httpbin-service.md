---
---
*   Запустіть зразок [httpbin]({{< github_tree >}}/samples/httpbin).

    Якщо ви увімкнули [автоматичну інʼєкцію sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), розгорніть сервіс `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    В іншому випадку вам потрібно вручну додати sidecar перед розгортанням застосунку `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}
