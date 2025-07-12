---
title: ¿Cómo averiguar qué le sucedió a una solicitud en Istio?
weight: 80
---

Puede habilitar el [seguimiento](/es/docs/tasks/observability/distributed-tracing/) para determinar el flujo de una solicitud en Istio.

Además, puede usar los siguientes comandos para saber más sobre el estado de la malla:

* [`istioctl proxy-config`](/es/docs/reference/commands/istioctl/#istioctl-proxy-config): recupera información sobre la configuración del proxy cuando se ejecuta en Kubernetes:

    {{< text plain >}}
    # Recuperar información sobre la configuración de arranque para la instancia de Envoy en el pod especificado.
    $ istioctl proxy-config bootstrap productpage-v1-bb8d5cbc7-k7qbm

    # Recuperar información sobre la configuración del cluster para la instancia de Envoy en el pod especificado.
    $ istioctl proxy-config cluster productpage-v1-bb8d5cbc7-k7qbm

    # Recuperar información sobre la configuración del listener para la instancia de Envoy en el pod especificado.
    $ istioctl proxy-config listener productpage-v1-bb8d5cbc7-k7qbm

    # Recuperar información sobre la configuración de la ruta para la instancia de Envoy en el pod especificado.
    $ istioctl proxy-config route productpage-v1-bb8d5cbc7-k7qbm

    # Recuperar información sobre la configuración del endpoint para la instancia de Envoy en el pod especificado.
    $ istioctl proxy-config endpoints productpage-v1-bb8d5cbc7-k7qbm

    # Pruebe lo siguiente para descubrir más comandos de proxy-config
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`: obtiene información sobre diferentes recursos en la malla junto con la configuración de enrutamiento:

    {{< text plain >}}
    # Listar todos los virtual services
    $ kubectl get virtualservices
    {{< /text >}}
