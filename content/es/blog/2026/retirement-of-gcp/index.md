---
title: "ACCIÓN REQUERIDA PARA LOS USUARIOS DE GOOGLE CONTAINER REGISTRY ANTES DEL 16 DE DICIEMBRE DE 2026, scream tests y nuestra migración a AWS"
description: Qué puedes hacer con tus Helm charts y claves de firma para asegurarte de que no te afecte la migración a AWS.
publishdate: 2026-08-21
attribution: Steven Jin (Microsoft), Keith Mattix (Solo.io)
keywords: [Istio,Container Registry,Helm]
---

{{< warning >}}
Este blog se ha actualizado para reflejar que `gcr.io/istio-release`, `registry.istio.io/release` y `https://istio-release.storage.googleapis.com/` se darán de baja el 16 de diciembre de 2026 a las 15:00 UTC.
{{< /warning >}}

Este año, debido a cambios en nuestro modelo de financiación, Istio está migrando toda su infraestructura de Google Cloud Platform a Amazon Web Services y Cloudflare.
Esta publicación describe la transición de nuestras imágenes de contenedor, Helm charts, otros artefactos de las versiones (RPMs, DEBs, código fuente, documentos SPDX, `istioctl` y licencias), claves de firma y **los próximos scream tests, en los que deshabilitaremos el acceso a todos los artefactos alojados en GCP**.

## Imágenes de contenedor

En una [publicación anterior del blog](../retirement-of-gcr.io-follow-up/), anunciamos que los registros de contenedores `gcr.io/istio-release` y `registry.istio.io` se darán de baja en diciembre de 2026 y que solo publicaríamos las imágenes de contenedor de Istio en Docker Hub.
A partir de Istio 1.31, solo publicaremos las imágenes de contenedor de Istio en `docker.io/istio`.
Consulta [la publicación anterior](../retirement-of-gcr.io-follow-up/) para ver los detalles sobre cómo dejar de usar `gcr.io/istio-release` y `registry.istio.io`.

## Helm charts y otros artefactos de las versiones

Históricamente, Istio publicaba los Helm charts en `https://istio-release.storage.googleapis.com/charts`, así como en `gcr.io/istio-release/charts` como artefactos OCI.
Del mismo modo, publicábamos otros artefactos de las versiones (RPMs, DEBs, código fuente, documentos SPDX, `istioctl` y licencias) en `https://istio-release.storage.googleapis.com/releases`.
Los Helm charts y otros artefactos de las versiones se eliminarán de las ubicaciones anteriores el 16 de diciembre de 2026 a las 15:00 UTC.
Todos los Helm charts de todas las versiones de Istio están disponibles actualmente en `https://blob.istio.io/istio-release/charts` y seguiremos publicándolos allí en el futuro previsible.
Todos los Helm charts OCI de todas las versiones de Istio están disponibles actualmente en `ghcr.io/istio/release/charts` y seguiremos publicándolos allí en el futuro previsible.
Todos los demás artefactos de las versiones de todas las versiones de Istio están disponibles actualmente en `https://blob.istio.io/istio-release/releases` y seguiremos publicándolos allí en el futuro previsible.
Istio 1.30 será la última versión menor con Helm charts, Helm charts OCI e imágenes publicados en `gcr.io/istio-release`, `registry.istio.io/release` y `https://istio-release.storage.googleapis.com/charts`.
Istio 1.31 **no** tendrá Helm charts, Helm charts OCI ni imágenes publicados en `gcr.io/istio-release/`, `registry.istio.io/release` ni `https://istio-release.storage.googleapis.com/charts`.
Habrá más información disponible en las notas de la versión.

## Claves de firma

Como resultado de nuestra migración, cambiaremos nuestros pares de claves pública/privada.
Seguiremos alojando la clave pública antigua en `https://istio.io/misc/istio-key.pub` en el futuro previsible.
Sin embargo, las imágenes más recientes se firmarán con una nueva clave, cuya clave pública correspondiente estará disponible en `https://istio.io/misc/istio-key-v2.pub`.

Esperamos que se usen las siguientes claves de firma para cada versión:

| Versión | Clave pública de firma |
|---------|-------------|
| 1.18.x - 1.30.x | `https://istio.io/misc/istio-key.pub` |
| 1.31.0 | `https://istio.io/misc/istio-key.pub` |
| 1.31.1+  | `https://istio.io/misc/istio-key-v2.pub` |

## Scream tests y lo que debes hacer

Realizaremos una serie de "scream tests" en los que deshabilitaremos temporalmente el acceso a `gcr.io/istio-release`, `registry.istio.io/release` y `https://istio-release.storage.googleapis.com/`.
El primer scream test será el 15 de septiembre de 2026 de 15:00 a 16:00 UTC.
El segundo scream test será el 13 de octubre de 2026 de 15:00 a 18:00 UTC.
El tercer scream test será el 17 de noviembre de 2026 de 15:00 a 21:00 UTC.
El cuarto y último scream test será desde el 8 de diciembre de 2026 a las 15:00 UTC hasta el 9 de diciembre de 2026 a las 15:00 UTC.
El acceso a las imágenes, los Helm charts y otros artefactos de las versiones se deshabilitará de forma permanente el 16 de diciembre de 2026 a las 15:00 UTC.

Si usas `registry.istio.io/release` o `gcr.io/istio-release`, debes migrar a `docker.io/istio` o a una caché pull-through lo antes posible.
Si instalas Istio usando Helm charts desde `https://istio-release.storage.googleapis.com/charts`, debes migrar a `https://blob.istio.io/istio-release/charts` lo antes posible.
Si instalas Istio usando Helm charts OCI en `gcr.io/istio-release/charts`, debes migrar a `ghcr.io/istio/release/charts` lo antes posible.
Si verificas la firma de las imágenes de Istio, presta atención a qué clave de firma se usa para tu versión de Istio y actualiza tu clave pública en consecuencia.
Debes completar tu migración lo antes posible para evitar cualquier interrupción en tus despliegues de Istio.
