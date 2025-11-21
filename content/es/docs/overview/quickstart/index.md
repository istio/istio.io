---
title: "Inicio Rápido"
description: Aprende cómo comenzar con un ejemplo de instalación simple.
weight: 50
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
skip_seealso: true
test: n/a
---

¡Gracias por tu interés en Istio!

Istio tiene dos modos principales: **modo ambient** y **modo sidecar**.

* [Modo ambient](/es/docs/overview/dataplane-modes/#ambient-mode) es el nuevo modelo mejorado, creado para abordar las deficiencias del modo sidecar. En modo ambient, un túnel seguro se instala en cada nodo, y puedes optar por el conjunto completo de características con proxies que instalas, (generalmente) por Namespace.
* [Modo sidecar](/es/docs/overview/dataplane-modes/#sidecar-mode) es el modelo tradicional de service mesh pionero de Istio en 2017. En modo sidecar, un proxy se despliega junto con cada Pod de Kubernetes u otro Workload.

La mayor parte de la energía en la comunidad Istio se dirige hacia la mejora del modo ambient, aunque el modo sidecar sigue estando completamente soportado. Se espera que cualquier nueva característica importante contribuida al proyecto funcione en ambos modos.

En general, **recomendamos que los nuevos usuarios comiencen con el modo ambient**. Es más rápido, más barato y más fácil de gestionar. Hay [casos de uso avanzados](/es/docs/overview/dataplane-modes/#unsupported-features) que aún requieren el uso del modo sidecar, pero cerrar estas brechas está en nuestro roadmap de 2025.

<div style="text-align: center;">
  <div style="display: inline-block;">
    <a href="/es/docs/ambient/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-ambient">Comenzar con modo ambient</a>
    <a href="/es/docs/setup/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-sidecar">Comenzar con modo sidecar</a>
  </div>
</div>
