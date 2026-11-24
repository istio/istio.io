---
title: "Una actualización sobre la migración de nuestro registro de contenedores"
description: Lo que puedes hacer hoy para asegurarte de que tus clústeres no se vean afectados por la retirada de `gcr.io/istio-release` y `registry.istio.io`.
publishdate: 2026-07-23
attribution: Steven Jin (Microsoft)
keywords: [Istio,Container Registry]
---

{{< warning >}}
Daremos de baja de forma permanente `gcr.io/istio-release`, `registry.istio.io/release` y `https://istio-release.storage.googleapis.com/` el 16 de diciembre de 2026 a las 15:00 UTC.
Consulta [ACCIÓN REQUERIDA PARA LOS USUARIOS DE GOOGLE CONTAINER REGISTRY ANTES DEL 16 DE DICIEMBRE DE 2026, scream tests y nuestra migración a AWS](../retirement-of-gcp/) para obtener más orientación.
{{< /warning >}}

En una [publicación anterior del blog](../retirement-of-gcr.io/), anunciamos que Istio retirará el registro de contenedores `gcr.io/istio-release` a finales de 2026 y que `registry.istio.io/release` pasará a ser el nuevo hogar de las imágenes de Istio.
El diseño original era que `registry.istio.io/release` fuera un Cloudflare worker que redirigiera las solicitudes, como proxy, a cualquier registro compatible con OCI, lo que nos permitiría cambiar de registro sin ninguna interrupción para los usuarios de Istio.
Actualmente, hacemos de proxy hacia `gcr.io/istio-release`.

Como mencionamos antes, retiraremos `gcr.io/istio-release` a finales de 2026.
Con un presupuesto de infraestructura limitado para 2027, planeamos usar plataformas gratuitas de alojamiento de contenedores para alojar las imágenes de Istio.
Desafortunadamente, hacer de proxy a través de Cloudflare significa que canalizamos todo el tráfico por unas pocas IPs de salida, lo que activa las políticas de límite de tasa de las plataformas gratuitas de alojamiento de contenedores.

Tras hablar con las plataformas de alojamiento sobre esta limitación, hemos tomado la difícil decisión de retirar `registry.istio.io/release`.
Seguiremos alojando `registry.istio.io/release` hasta finales de 2026.
Como siempre, publicaremos las imágenes de Istio en `docker.io/istio` y planeamos publicarlas en espejos en el futuro.

## ¿Me afecta esto?

Por defecto, las instalaciones de Istio 1.30 usan `registry.istio.io/release` como su registro de contenedores.
Todas las demás versiones de Istio usan `docker.io/istio` por defecto.
Puedes comprobar si te afecta ejecutando lo siguiente:

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("registry.istio.io/release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

El comando anterior listará todos los pods que usan imágenes alojadas en `registry.istio.io/release`.
Si hay algún pod de este tipo, probablemente necesitarás migrar.

Ten en cuenta que, como se mencionó en la publicación anterior, seguiremos retirando `gcr.io/istio-release` a finales de 2026, así que debes comprobar también si usas `gcr.io/istio-release`.

## Qué hacer hoy

Aunque planeamos mantener las imágenes disponibles en `registry.istio.io/release` y `gcr.io/istio-release` hasta finales de 2026,
te sugerimos que migres a `docker.io/istio` lo antes posible.
Mejor aún, configura una caché pull-through para garantizar la máxima disponibilidad.

### Usando `istioctl`

Si instalas Istio con `istioctl`, puedes actualizar tu configuración de `IstioOperator` de la siguiente manera:

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: docker.io/istio  # or your pull-through cache
  # Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

E instala Istio usando esta configuración:

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

También puedes pasar el registro como argumento de línea de comandos:

{{< text bash >}}
$ istioctl install --set hub=docker.io/istio # or your pull-through cache
{{< /text >}}

### Usando Helm

Si usas Helm para instalar Istio, actualiza tu archivo de valores de la siguiente manera:

{{< text yaml >}}
# ...
hub: docker.io/istio  # or your pull-through cache
global:
  hub: docker.io/istio  # or your pull-through cache
# Everything else can stay the same unless you reference `gcr.io/istio-release` images elsewhere
{{< /text >}}

Luego, actualiza tu instalación de Helm con tu nuevo archivo de valores.
