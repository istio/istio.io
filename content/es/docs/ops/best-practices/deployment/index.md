---
title: Mejores prácticas de despliegue
description: Mejores prácticas generales para configurar una service mesh de Istio.
force_inline_toc: true
weight: 10
aliases:
  - /docs/ops/prep/deployment
owner: istio/wg-environments-maintainers
test: n/a
---

Hemos identificado los siguientes principios generales para ayudarte a sacar el máximo
partido a tus despliegues de Istio. Estas mejores prácticas buscan limitar el impacto de
los cambios de configuración incorrectos y facilitar la gestión de tus despliegues.

## Despliega menos clústeres

Despliega Istio en un número reducido de clústeres grandes, en lugar de en un gran número
de clústeres pequeños. En lugar de añadir clústeres a tu despliegue, la mejor
práctica es usar la [tenencia por namespace](/es/docs/ops/deployment/deployment-models/#namespace-tenancy)
para gestionar clústeres grandes. Con este enfoque, puedes desplegar Istio en
uno o dos clústeres por zona o región. Después, puedes desplegar un control plane en
un clúster por región o zona para aumentar la fiabilidad.

## Despliega clústeres cerca de tus usuarios

Incluye en tu despliegue clústeres repartidos por todo el mundo para lograr **proximidad
geográfica con los usuarios finales**. La proximidad ayuda a que tu despliegue tenga una latencia baja.

## Despliega en varias zonas de disponibilidad

Incluye en tu despliegue clústeres **en varias regiones y zonas
de disponibilidad** dentro de cada región geográfica. Este enfoque limita el tamaño de los
{{< gloss "failure domain" >}}failure domains{{< /gloss >}} de tu despliegue
y te ayuda a evitar fallos globales.

## Ejecuta varias réplicas de istiod

Por defecto, `istiod` se despliega con una sola réplica. Cuando esa réplica
deja de estar disponible (por ejemplo, durante el drenaje de un nodo o una actualización progresiva), el
mutating webhook de inyección de sidecars (`failurePolicy: Fail`) rechaza todas las solicitudes de creación
de pods en todo el clúster. En la práctica, esto convierte una única réplica de `istiod`
en un punto único de fallo para cualquier operación que cree pods.

Para evitarlo, establece `autoscaleMin` en al menos `2` en tu sobrescritura de valores de Helm
para el chart `istio/istiod`. El chart viene con
`autoscaleEnabled: true` por defecto, así que el Horizontal Pod Autoscaler
controla el número de réplicas. Establecer el mínimo en 2 garantiza que al menos una
réplica siga disponible durante las interrupciones:

{{< text yaml >}}
autoscaleMin: 2
{{< /text >}}

Añade lo siguiente a tu sobrescritura de valores de Helm para el chart `istio/istiod`
para repartir las réplicas entre nodos y zonas.
Usa `requiredDuringSchedulingIgnoredDuringExecution` para la separación a nivel de nodo
y así garantizar que las réplicas se ejecuten en nodos distintos. Si la capacidad es insuficiente, el
pod que no se puede programar deja el problema a la vista en lugar de ubicar silenciosamente ambas
réplicas en un mismo nodo. Usa `preferredDuringSchedulingIgnoredDuringExecution`
para el reparto a nivel de zona y así evitar bloquear la programación en clústeres con menos
zonas que réplicas:

{{< text yaml >}}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - istiod
      topologyKey: kubernetes.io/hostname
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - istiod
        topologyKey: topology.kubernetes.io/zone
{{< /text >}}
