---
title: Introspección de Istiod
description: Describe cómo usar ControlZ para obtener información sobre un componente istiod en ejecución.
weight: 60
keywords: [ops]
aliases:
  - /help/ops/controlz
  - /docs/ops/troubleshooting/controlz
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod incluye un framework de introspección flexible, llamado ControlZ, que facilita inspeccionar y manipular el estado interno
de una instancia de istiod. Istiod abre un puerto que puedes usar desde un navegador web para obtener una vista interactiva de su estado,
o mediante REST para acceder a él y controlarlo desde herramientas externas.

Cuando Istiod se inicia, registra un mensaje que indica la dirección IP y el puerto a los que debes conectarte para interactuar con ControlZ.

{{< text plain >}}
2020-08-04T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

Este es un ejemplo de la interfaz de ControlZ:

{{< image width="90%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

Para acceder a la página de ControlZ de istiod, puedes hacer port-forward de su endpoint de ControlZ
localmente y conectarte desde tu navegador local:

{{< text bash >}}
$ istioctl dashboard controlz deployment/istiod.istio-system
{{< /text >}}

Esto redirigirá la página de ControlZ del componente a `http://localhost:9876` para el acceso remoto.
