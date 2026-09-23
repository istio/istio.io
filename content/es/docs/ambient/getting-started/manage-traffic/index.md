---
title: Gestionar el tráfico
description: Gestionar el tráfico entre servicios en el modo ambient.
weight: 5
owner: istio/wg-networking-maintainers
test: yes
---

Ahora que tienes un proxy de waypoint instalado, aprenderás a dividir el tráfico entre servicios.

## Dividir el tráfico entre servicios

La aplicación Bookinfo tiene tres versiones del servicio `reviews`. Puedes dividir el tráfico entre estas versiones para probar nuevas características o realizar pruebas A/B.

Vamos a configurar el enrutamiento del tráfico para enviar el 90% de las solicitudes a `reviews` v1 y el 10% a `reviews` v2:

{{< text syntax=bash snip_id=deploy_httproute >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
{{< /text >}}

Para confirmar que aproximadamente el 10% del tráfico de 100 solicitudes va a `reviews-v2`, puedes ejecutar el siguiente comando:

{{< text syntax=bash snip_id=test_traffic_split >}}
$ kubectl exec deploy/curl -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
{{< /text >}}

Notarás que la mayoría de las solicitudes van a `reviews-v1`. Puedes confirmar lo mismo si abres la aplicación Bookinfo en tu navegador y actualizas la página varias veces. Observa que las solicitudes de `reviews-v1` no tienen estrellas, mientras que las solicitudes de `reviews-v2` tienen estrellas negras.

## Próximos pasos

Esta sección concluye la guía de introducción al modo ambient de Istio. Puedes continuar con la sección de [Limpieza](/es/docs/ambient/getting-started/cleanup) para eliminar Istio o seguir explorando las [guías de usuario del modo ambient](/es/docs/ambient/usage/) para obtener más información sobre las características y capacidades de Istio.
