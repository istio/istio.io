---
title: Primeros pasos
description: Cómo desplegar e instalar Istio en modo ambient.
weight: 2
aliases:
  - /docs/ops/ambient/getting-started
  - /latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
test: yes
skip_list: true
next: /docs/ambient/getting-started/deploy-sample-app
---

Esta guía te permite evaluar rápidamente el {{< gloss "ambient" >}}modo ambient{{< /gloss >}} de Istio. Necesitarás un cluster de Kubernetes para continuar. Si no tienes un cluster, puedes usar [kind](/es/docs/setup/platform-setup/kind) o cualquier otra [plataforma de Kubernetes compatible](/es/docs/setup/platform-setup).

Estos pasos requieren que tengas un {{< gloss >}}cluster{{< /gloss >}} ejecutando una
[versión compatible](/es/docs/releases/supported-releases#support-status-of-istio-releases) de Kubernetes ({{< supported_kubernetes_versions >}}).

## Descargar la CLI de Istio

Istio se configura usando una herramienta de línea de comandos llamada `istioctl`. Descárgala, y las aplicaciones de ejemplo de Istio:

{{< text syntax=bash snip_id=none >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

Comprueba que puedes ejecutar `istioctl` imprimiendo la versión del comando. En este punto, Istio no está instalado en tu cluster, por lo que verás que no hay pods listos.

{{< text syntax=bash snip_id=none >}}
$ istioctl version
Istio is not present in the cluster: no running Istio pods in namespace "istio-system"
client version: {{< istio_full_version >}}
{{< /text >}}

## Instalar Istio en tu cluster

`istioctl` admite una serie de [perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) que incluyen diferentes opciones predeterminadas y se pueden personalizar para tus necesidades de producción. El soporte para el modo ambient se incluye en el perfil `ambient`. Instala Istio con el siguiente comando:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

Una vez que se complete la instalación, obtendrás la siguiente salida que indica que todos los componentes se han instalado correctamente.

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

## Instalar las CRD de la API de Gateway de Kubernetes

Utilizarás la API de Gateway de Kubernetes para configurar el enrutamiento del tráfico.

{{< boilerplate gateway-api-install-crds >}}

## Próximos pasos

¡Felicidades! Has instalado correctamente Istio con soporte para el modo ambient. Continúa con el siguiente paso para [instalar una aplicación de ejemplo](/es/docs/ambient/getting-started/deploy-sample-app/).
