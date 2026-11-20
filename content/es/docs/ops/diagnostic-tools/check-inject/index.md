---
title: Verificar la inyección de sidecar de Istio con istioctl check-inject
description: Aprende a usar istioctl check-inject para confirmar si la inyección de sidecar de Istio está habilitada correctamente para tus deployments.
weight: 45
keywords: [istioctl, injection, kubernetes]
owner: istio/wg-user-experience-maintainers
test: no
---

`istioctl experimental check-inject` es una herramienta de diagnóstico que te ayuda a verificar si determinados webhooks realizarán la inyección de sidecar de Istio en tus pods. Usa esta herramienta para comprobar si la configuración de inyección de sidecar se aplica correctamente en un clúster en ejecución.

## Inicio rápido {#quick-start}

Para comprobar por qué se produjo o no (o se producirá o no) la inyección de sidecar de Istio en un pod concreto, ejecuta:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> <pod-name>
{{< /text >}}

Para un deployment, ejecuta:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> deploy/<deployment-name>
{{< /text >}}

O bien, para pares de etiquetas:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> -l <label-key>=<label-value>
{{< /text >}}

Por ejemplo, si tienes un deployment llamado `httpbin` en el namespace `hello` y un pod llamado `httpbin-1234` con la etiqueta `app=httpbin`, los siguientes comandos son equivalentes:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n hello httpbin-1234
$ istioctl experimental check-inject -n hello deploy/httpbin
$ istioctl experimental check-inject -n hello -l app=httpbin
{{< /text >}}

Resultados de ejemplo:

{{< text plain >}}
WEBHOOK                      REVISION  INJECTED      REASON
istio-revision-tag-default   default   ✔             Namespace label istio-injection=enabled matches
istio-sidecar-injector-1-18  1-18      ✘             No matching namespace labels (istio.io/rev=1-18) or pod labels (istio.io/rev=1-18)
{{< /text >}}

Si el campo `INJECTED` está marcado con `✔`, el webhook de esa fila realizará la inyección, y se muestra el motivo por el que el webhook inyectará el sidecar.

Si el campo `INJECTED` está marcado con `✘`, el webhook de esa fila no realizará la inyección, y también se muestra el motivo.

Posibles motivos por los que el webhook no realizará la inyección o la inyección tendrá errores:

1. **No hay etiquetas de namespace ni de pod que coincidan**: Asegúrate de que el namespace o el pod tengan las etiquetas adecuadas.

1. **No hay etiquetas de namespace ni de pod que coincidan con una revisión específica**: Configura las etiquetas correctas para que coincidan con la revisión de Istio deseada.

1. **Una etiqueta del pod impide la inyección**: Elimina la etiqueta o asígnale el valor adecuado.

1. **Una etiqueta del namespace impide la inyección**: Cambia la etiqueta al valor adecuado.

1. **Varios webhooks inyectan sidecars**: Asegúrate de que solo haya un webhook habilitado para la inyección, o configura las etiquetas adecuadas en el namespace o el pod para seleccionar un webhook específico.
