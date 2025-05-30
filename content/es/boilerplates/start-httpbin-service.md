---
---
*   Inicia el ejemplo [httpbin]({{< github_tree >}}/samples/httpbin).

    Si has habilitado la [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), despliega el servicio `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    De lo contrario, tienes que inyectar manualmente el sidecar antes de desplegar la aplicación `httpbin`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}
