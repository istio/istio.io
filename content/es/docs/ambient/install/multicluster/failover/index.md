---
title: Configurar el comportamiento de failover en la instalación multiclúster ambient
description: Configura la detección de anomalías y el comportamiento de failover en una mesh ambient multiclúster usando waypoints.
weight: 70
keywords: [kubernetes,multicluster,ambient]
test: yes
owner: istio/wg-environments-maintainers
prev: /docs/ambient/install/multicluster/verify
---
Sigue esta guía para personalizar el comportamiento de failover en tu instalación multiclúster de Istio en modo ambient usando waypoint proxies.

Antes de proceder, asegúrate de completar la instalación de Istio multiclúster en modo ambient siguiendo una de las
[guías de instalación multiclúster](/docs/ambient/install/multicluster) y verificar que la instalación funciona correctamente.

En esta guía, construiremos sobre la aplicación `HelloWorld` usada para verificar la instalación multiclúster. Configuraremos
el failover por localidad para el servicio `HelloWorld` para preferir endpoints en el clúster local al cliente usando un
`DestinationRule` y desplegaremos un waypoint proxy para aplicar la configuración.

## Desplegar el waypoint proxy

Para configurar la detección de anomalías y personalizar el comportamiento de failover para el servicio necesitamos un waypoint proxy. Para comenzar,
despliega el waypoint proxy en cada clúster de la mesh:

{{< text bash >}}
$ istioctl --context "${CTX_CLUSTER1}" waypoint apply --name waypoint --for service -n sample --wait
$ istioctl --context "${CTX_CLUSTER2}" waypoint apply --name waypoint --for service -n sample --wait
{{< /text >}}

Confirma el estado del despliegue del waypoint proxy en `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           137m
{{< /text >}}

Confirma el estado del despliegue del waypoint proxy en `cluster2`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" get deployment waypoint --namespace sample
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           138m
{{< /text >}}

Espera hasta que todos los waypoint proxies estén listos.

Configura el servicio `HelloWorld` en cada clúster para usar el waypoint proxy:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
$ kubectl --context "${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
{{< /text >}}

Finalmente, y este paso es específico del despliegue multiclúster de waypoint proxies, marca el servicio del waypoint proxy en cada
clúster como global, tal como hiciste antes con el servicio `HelloWorld`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" label svc waypoint -n sample istio.io/global=true
$ kubectl --context "${CTX_CLUSTER2}" label svc waypoint -n sample istio.io/global=true
{{< /text >}}

El servicio `HelloWorld` en ambos clústeres ahora está configurado para usar waypoint proxies, pero los waypoint proxies aún no hacen
nada útil.

## Configurar el failover por localidad

Para configurar el failover por localidad, crea y aplica un `DestinationRule` en `cluster1`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

Aplica el mismo `DestinationRule` también en `cluster2`:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER2}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
{{< /text >}}

Este `DestinationRule` configura lo siguiente:

- [Detección de anomalías](/docs/reference/config/networking/destination-rule/#OutlierDetection) para el servicio `HelloWorld`.
  Esto indica a los waypoint proxies cómo identificar cuándo los endpoints de un servicio no están saludables. Es necesario para que
  el failover funcione correctamente.

- [Prioridad de failover](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting) que indica
  al waypoint proxy cómo priorizar los endpoints al enrutar requests. En este ejemplo, el waypoint proxy preferirá endpoints
  en el mismo clúster que el waypoint proxy cuando estén disponibles y se consideren saludables según la configuración de detección de anomalías.

Con estas políticas en vigor, los waypoint proxies preferirán endpoints en el mismo clúster que el waypoint proxy cuando estén
disponibles y se consideren saludables según la configuración de detección de anomalías.

## Verificar que el tráfico permanece en el clúster local

Envía un request desde los pods `curl` en `cluster1` al servicio `HelloWorld`:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Ahora, si repites este request varias veces y verificas que la versión de `HelloWorld` siempre debería ser `v1` porque el
tráfico permanece en `cluster1`:

{{< text plain >}}
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
...
{{< /text >}}

De manera similar, envía requests desde los pods `curl` en `cluster2` varias veces:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Deberías ver que todos los requests son procesados en `cluster2` mirando la versión en la respuesta:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

## Verificar el failover a otro clúster

Para verificar que el failover al clúster remoto funciona, simula una interrupción del servicio `HelloWorld` en `cluster1` escalando el
deployment a cero:

{{< text bash >}}
$ kubectl --context "${CTX_CLUSTER1}" scale --replicas=0 deployment/helloworld-v1 -n sample
{{< /text >}}

Envía un request desde los pods `curl` en `cluster1` al servicio `HelloWorld` nuevamente:

{{< text bash >}}
$ kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
{{< /text >}}

Esta vez deberías ver que el request es procesado por el servicio `HelloWorld` en `cluster2` porque no hay
endpoints disponibles en `cluster1`:

{{< text plain >}}
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
{{< /text >}}

**¡Felicitaciones!** Configuraste exitosamente el failover por localidad en un despliegue ambient multiclúster de Istio.
