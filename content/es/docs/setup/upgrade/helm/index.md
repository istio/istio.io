---
title: Actualizar con Helm
linktitle: Actualizar con Helm
description: Instrucciones para actualizar Istio usando Helm.
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: yes
---

Sigue esta guía para actualizar y configurar una mesh de Istio usando
[Helm](https://helm.sh/docs/). Esta guía asume que ya realizaste una
[instalación con Helm](/es/docs/setup/install/helm) de una versión menor o de parche anterior de Istio.

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## Pasos de actualización {#upgrade-steps}

Antes de actualizar Istio, se recomienda ejecutar el comando `istioctl x precheck` para asegurarte de que la actualización sea compatible con tu entorno.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

### Actualización canary (recomendada) {#canary-upgrade-recommended}

Puedes instalar una versión canary del control plane de Istio para validar que la nueva
versión es compatible con tu configuración existente y con el data plane siguiendo
estos pasos:

{{< warning >}}
Ten en cuenta que, cuando instalas una versión canary del servicio `istiod`, los recursos
a nivel de clúster del chart base se comparten entre tu instalación
principal y la canary.
{{< /warning >}}

{{< boilerplate crd-upgrade-123 >}}

1. Actualiza el chart base de Istio para asegurarte de que todos los recursos a nivel de clúster estén al día

    {{< text bash >}}
    $ helm upgrade istio-base istio/base -n istio-system
    {{< /text >}}

1. Instala una versión canary del chart de discovery de Istio configurando el valor
   de revisión:

    {{< text bash >}}
    $ helm install istiod-canary istio/istiod \
        --set revision=canary \
        -n istio-system
    {{< /text >}}

1. Verifica que tienes dos versiones de `istiod` instaladas en tu clúster:

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. Si usas [gateways de Istio](/es/docs/setup/additional-setup/gateway/#deploying-a-gateway), instala una revisión canary del chart de gateway configurando el valor de revisión:

    {{< text bash >}}
    $ helm install istio-ingress-canary istio/gateway \
        --set revision=canary \
        -n istio-ingress
    {{< /text >}}

1. Verifica que tienes dos versiones de `istio-ingress gateway` instaladas en tu clúster:

    {{< text bash >}}
    $ kubectl get pods -L istio.io/rev -n istio-ingress
      NAME                                    READY   STATUS    RESTARTS   AGE     REV
      istio-ingress-754f55f7f6-6zg8n          1/1     Running   0          5m22s   default
      istio-ingress-canary-5d649bd644-4m8lp   1/1     Running   0          3m24s   canary
    {{< /text >}}

    Consulta [Actualizar gateways](/es/docs/setup/additional-setup/gateway/#canary-upgrade-advanced) para ver la documentación detallada sobre la actualización canary de gateways.

1. Sigue [estos pasos](/es/docs/setup/upgrade/canary/#data-plane) para probar o migrar
   los workloads existentes para que usen el control plane canary.

1. Una vez que hayas verificado y migrado tus workloads para que usen el control plane
   canary, puedes desinstalar el control plane anterior:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Vuelve a actualizar el chart base de Istio, esta vez haciendo que la nueva revisión `canary` sea la predeterminada en todo el clúster.

    {{< text bash >}}
    $ helm upgrade istio-base istio/base --set defaultRevision=canary -n istio-system
    {{< /text >}}

### Etiquetas de revisión estables {#stable-revision-labels}

{{< boilerplate revision-tags-preamble >}}

#### Uso {#usage}

{{< boilerplate revision-tags-usage >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags-mwc.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_previous_version_revision >}}-1 -n istio-system | kubectl apply -f -
$ helm template istiod istio/istiod -s templates/revision-tags-mwc.yaml --set revisionTags="{prod-canary}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< warning >}}
Estos comandos crean nuevos recursos `MutatingWebhookConfiguration` en tu clúster; sin embargo, no pertenecen a ningún chart de Helm porque `kubectl` aplica las plantillas manualmente. Consulta las instrucciones
más abajo para desinstalar las etiquetas de revisión.
{{< /warning >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags-mwc.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

#### Etiqueta default {#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags-mwc.yaml --set revisionTags="{default}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

### Actualización in-place {#in-place-upgrade}

Puedes realizar una actualización in-place de Istio en tu clúster usando el flujo de
actualización de Helm.

{{< warning >}}
Agrega tu archivo de valores personalizados u opciones personalizadas a los siguientes comandos para
conservar tu configuración personalizada durante las actualizaciones con Helm.
{{< /warning >}}

{{< boilerplate crd-upgrade-123 >}}

1. Actualiza el chart base de Istio:

    {{< text bash >}}
    $ helm upgrade istio-base istio/base -n istio-system
    {{< /text >}}

1. Actualiza el chart de discovery de Istio:

    {{< text bash >}}
    $ helm upgrade istiod istio/istiod -n istio-system
    {{< /text >}}

1. (Opcional) Actualiza los charts de gateway instalados en tu clúster:

    {{< text bash >}}
    $ helm upgrade istio-ingress istio/gateway -n istio-ingress
    {{< /text >}}

## Desinstalar {#uninstall}

Consulta la sección de desinstalación de nuestra [guía de instalación con Helm](/es/docs/setup/install/helm/#uninstall).
