---
---
## Antes de empezar

*   Configura Istio siguiendo las instrucciones de la [Guía de instalación](/es/docs/setup/).

    {{< tip >}}
    El egress gateway y el registro de acceso se habilitarán si instalas el
    [perfil de configuración](/es/docs/setup/additional-setup/config-profiles/) `demo`.
    {{< /tip >}}

*   Despliega la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) para usarla como fuente de prueba para enviar solicitudes.
    Si tienes habilitada la
    [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    , ejecuta el siguiente comando para desplegar la aplicación de ejemplo:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    De lo contrario, inyecta manualmente el sidecar antes de desplegar la aplicación `curl` con el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Puedes usar cualquier pod con `curl` instalado como fuente de prueba.
    {{< /tip >}}

*   Establece la variable de entorno `SOURCE_POD` con el nombre de tu pod de origen:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}
