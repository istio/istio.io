---
title: Actualizaciones canary
description: Actualiza Istio ejecutando primero un despliegue canary de un nuevo control plane.
weight: 10
keywords: [kubernetes,upgrading,canary]
owner: istio/wg-environments-maintainers
test: no
---

Puedes actualizar Istio ejecutando primero un despliegue canary del nuevo control plane, lo que te permite
monitorear el efecto de la actualización con un pequeño porcentaje de los workloads antes de migrar todo el
tráfico a la nueva versión. Esto es mucho más seguro que hacer una
[actualización in-place](/es/docs/setup/upgrade/in-place/) y es el método de actualización recomendado.

Al instalar Istio, puedes usar la opción de instalación `revision` para desplegar varios control planes independientes
al mismo tiempo. Para iniciar una versión canary de una actualización, instala el control plane de la nueva versión de Istio
junto al anterior, usando un valor de `revision` diferente. Cada revisión es una implementación completa del control plane de Istio
con su propio `Deployment`, `Service`, etc.

## Antes de actualizar {#before-you-upgrade}

[Descarga las versiones de Istio](/es/docs/setup/additional-setup/download-istio-release/)
tanto de la versión instalada como de la versión de destino, para tener disponibles los binarios de `istioctl`
correspondientes antes de empezar.

Antes de actualizar Istio, se recomienda ejecutar el comando `istioctl x precheck` para asegurarte de que la actualización sea compatible con tu entorno.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/
{{< /text >}}

{{< idea >}}

Con las actualizaciones basadas en revisiones se puede saltar dos versiones menores (p. ej., actualizar directamente de
la versión `1.15` a la `1.17`). En cambio, con las actualizaciones in-place es necesario actualizar a cada versión menor
intermedia.

{{< /idea >}}

## Control plane

Para instalar una nueva revisión llamada `canary`, configura el campo `revision` de la siguiente manera:

{{< tip >}}
En un entorno de producción, es mejor usar un nombre de revisión que corresponda a la versión de Istio.
Sin embargo, debes reemplazar los caracteres `.` en el nombre de la revisión, por ejemplo, `revision={{< istio_full_version_revision >}}` para Istio `{{< istio_full_version >}}`,
porque `.` no es un carácter válido en un nombre de revisión.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

Después de ejecutar el comando, tendrás dos deployments y dos services del control plane ejecutándose en paralelo:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-htddg    1/1     Running   0          47s
istiod-canary-84c8d4dcfb-skcfv   1/1     Running   0          25s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
istiod-{{< istio_previous_version_revision >}}-1   ClusterIP   10.96.93.151     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   109s
istiod-canary   ClusterIP   10.104.186.250   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   87s
{{< /text >}}

También verás que hay dos configuraciones del inyector de sidecar, incluida la de la nueva revisión.

{{< text bash >}}
$ kubectl get mutatingwebhookconfigurations
NAME                            WEBHOOKS   AGE
istio-sidecar-injector-{{< istio_previous_version_revision >}}-1   2          2m16s
istio-sidecar-injector-canary   2          114s
{{< /text >}}

## Data plane

Consulta [Actualización canary de gateways](/es/docs/setup/additional-setup/gateway/#canary-upgrade-advanced) para entender cómo ejecutar instancias del gateway de Istio específicas de una revisión.
En este ejemplo, como usamos el perfil `default` de Istio, los gateways de Istio no ejecutan instancias específicas de una revisión, sino que se actualizan in-place para usar la nueva revisión del control plane. Puedes verificar que el gateway `istio-ingress` está usando la revisión `canary` ejecutando el siguiente comando:

{{< text bash >}}
$ istioctl proxy-status | grep "$(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}')" | awk -F '[[:space:]][[:space:]]+' '{print $8}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

Sin embargo, instalar la nueva revisión no tiene ningún efecto sobre los sidecar proxies existentes. Para actualizarlos,
debes configurarlos para que apunten al nuevo control plane `istiod-canary`. Esto se controla durante la inyección del sidecar
según la etiqueta de namespace `istio.io/rev`.

Crea un namespace `test-ns` con `istio-injection` habilitado. En el namespace `test-ns`, despliega un pod de ejemplo de curl:

1. Crea un namespace `test-ns`.

    {{< text bash >}}
    $ kubectl create ns test-ns
    {{< /text >}}

1. Etiqueta el namespace con la etiqueta `istio-injection`.

    {{< text bash >}}
    $ kubectl label namespace test-ns istio-injection=enabled
    {{< /text >}}

1. Levanta un pod de ejemplo de curl en el namespace `test-ns`.

    {{< text bash >}}
    $ kubectl apply -n test-ns -f samples/curl/curl.yaml
    {{< /text >}}

Para actualizar el namespace `test-ns`, elimina la etiqueta `istio-injection` y agrega la etiqueta `istio.io/rev` para que apunte a la revisión `canary`. La etiqueta `istio-injection` debe eliminarse porque, por compatibilidad con versiones anteriores, tiene prioridad sobre la etiqueta `istio.io/rev`.

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

Después de actualizar el namespace, debes reiniciar los pods para que se vuelva a inyectar el sidecar.
Una forma de reiniciar todos los pods del namespace `test-ns` es:

{{< text bash >}}
$ kubectl rollout restart deployment -n test-ns
{{< /text >}}

Cuando se vuelva a inyectar el sidecar, los pods quedarán configurados para apuntar al control plane `istiod-canary`. Puedes verificarlo con `istioctl proxy-status`.

{{< text bash >}}
$ istioctl proxy-status | grep "\.test-ns "
{{< /text >}}

La salida mostrará todos los pods del namespace que usan la revisión canary.

## Etiquetas de revisión estables {#stable-revision-labels}

{{< tip >}}
Si usas Helm, consulta la [documentación de actualización con Helm](/es/docs/setup/upgrade/helm).
{{</ tip >}}

{{< boilerplate revision-tags-preamble >}}

### Uso {#usage}

{{< boilerplate revision-tags-usage >}}

1. Instala dos revisiones del control plane, usando el binario `istioctl`
   de la versión correspondiente a cada revisión:

    {{< text bash >}}
    $ ./istio-{{< istio_previous_version >}}.1/bin/istioctl install --revision={{< istio_previous_version_revision >}}-1 --set profile=minimal --skip-confirmation
    $ ./istio-{{< istio_full_version >}}/bin/istioctl install --revision={{< istio_full_version_revision >}} --set profile=minimal --skip-confirmation
    {{< /text >}}

1. Crea las etiquetas de revisión `stable` y `canary` y asócialas a sus respectivas revisiones:

    {{< text bash >}}
    $ istioctl tag set prod-stable --revision {{< istio_previous_version_revision >}}-1
    $ istioctl tag set prod-canary --revision {{< istio_full_version_revision >}}
    {{< /text >}}

1. Etiqueta los namespaces de las aplicaciones para asignarlos a sus respectivas etiquetas de revisión:

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl label ns app-ns-1 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-2
    $ kubectl label ns app-ns-2 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-3
    $ kubectl label ns app-ns-3 istio.io/rev=prod-canary
    {{< /text >}}

1. Levanta un pod de ejemplo de curl en cada namespace:

    {{< text bash >}}
    $ kubectl apply -n app-ns-1 -f samples/curl/curl.yaml
    $ kubectl apply -n app-ns-2 -f samples/curl/curl.yaml
    $ kubectl apply -n app-ns-3 -f samples/curl/curl.yaml
    {{< /text >}}

1. Verifica la asignación entre las aplicaciones y el control plane con el comando `istioctl proxy-status`:

    {{< text bash >}}
    $ istioctl ps
    NAME                                CLUSTER        CDS        LDS        EDS        RDS        ECDS         ISTIOD                             VERSION
    curl-78ff5975c6-62pzf.app-ns-3      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-s8zfg     {{< istio_full_version >}}
    curl-78ff5975c6-8kxpl.app-ns-1      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version >}}.1
    curl-78ff5975c6-8q7m6.app-ns-2      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version_revision >}}.1
    {{< /text >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ istioctl tag set prod-stable --revision {{< istio_full_version_revision >}} --overwrite
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n app-ns-1
$ kubectl rollout restart deployment -n app-ns-2
{{< /text >}}

Verifica la asignación entre las aplicaciones y el control plane con el comando `istioctl proxy-status`:

{{< text bash >}}
$ istioctl ps
NAME                                                   CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                             VERSION
curl-5984f48bc7-kmj6x.app-ns-1                         Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
curl-78ff5975c6-jldk4.app-ns-3                         Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
curl-7cdd8dccb9-5bq5n.app-ns-2                         Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
{{< /text >}}

### Etiqueta default {#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ istioctl tag set default --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

## Desinstalar el control plane anterior {#uninstall-old-control-plane}

Después de actualizar tanto el control plane como el data plane, puedes desinstalar el control plane anterior. Por ejemplo, el siguiente comando desinstala un control plane de la revisión `{{< istio_previous_version_revision >}}-1`:

{{< text bash >}}
$ istioctl uninstall --revision {{< istio_previous_version_revision >}}-1 -y
{{< /text >}}

Si el control plane anterior no tiene una etiqueta de revisión, desinstálalo usando sus opciones de instalación originales, por ejemplo:

{{< text bash >}}
$ istioctl uninstall -f manifests/profiles/default.yaml -y
{{< /text >}}

Confirma que el control plane anterior se eliminó y que solo queda el nuevo en el clúster:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

Ten en cuenta que las instrucciones anteriores solo eliminaron los recursos de la revisión del control plane especificada, pero no los recursos a nivel de clúster compartidos con otros control planes. Para desinstalar Istio por completo, consulta la [guía de desinstalación](/es/docs/setup/install/istioctl/#uninstall-istio).

## Desinstalar el control plane canary {#uninstall-canary-control-plane}

Si decides volver al control plane anterior en lugar de completar la actualización canary,
puedes desinstalar la revisión canary con:

{{< text bash >}}
$ istioctl uninstall --revision=canary -y
{{< /text >}}

Sin embargo, en este caso primero debes reinstalar manualmente los gateways de la revisión anterior,
porque el comando de desinstalación no revierte automáticamente los que se actualizaron in-place.

{{< tip >}}
Asegúrate de usar la versión de `istioctl` correspondiente al control plane anterior para reinstalar los
gateways anteriores y, para evitar tiempo de inactividad, asegúrate de que estén en funcionamiento antes de continuar
con la desinstalación de la revisión canary.
{{< /tip >}}

## Limpieza {#cleanup}

1. Elimina las etiquetas de revisión creadas:

    {{< text bash >}}
    $ istioctl tag remove prod-stable
    $ istioctl tag remove prod-canary
    {{< /text >}}

1. Elimina los namespaces usados en el ejemplo de actualización canary con etiquetas de revisión (`istio.io/rev=canary`):

    {{< text bash >}}
    $ kubectl delete ns istio-system test-ns
    {{< /text >}}

1. Elimina los namespaces usados en el ejemplo de actualización canary con etiquetas de revisión estables (`prod-stable`, `prod-canary`):

    {{< text bash >}}
    $ kubectl delete ns istio-system app-ns-1 app-ns-2 app-ns-3
    {{< /text >}}
