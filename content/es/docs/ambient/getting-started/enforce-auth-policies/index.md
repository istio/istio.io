---
title: Aplicar políticas de autorización
description: Aplicar políticas de autorización de capa 4 y capa 7 en una malla ambient.
weight: 4
owner: istio/wg-networking-maintainers
test: yes
---

Después de haber agregado tu aplicación a la malla ambient, puedes proteger el acceso a la aplicación utilizando políticas de autorización de capa 4.

Esta característica te permite controlar el acceso hacia y desde un servicio en función de las identidades de los workloads del cliente que se emiten automáticamente a todas los workloads en la malla.

## Aplicar la política de autorización de capa 4

Vamos a crear una [política de autorización](/es/docs/reference/config/security/authorization-policy/) que restrinja qué servicios pueden comunicarse con el servicio `productpage`. La política se aplica a los pods con la etiqueta `app: productpage`, y permite llamadas solo desde la cuenta de servicio `cluster.local/ns/default/sa/bookinfo-gateway-istio`. Esta es la cuenta de servicio que utiliza la gateway de Bookinfo que desplegaste en el paso anterior.

{{< text syntax=bash snip_id=deploy_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
EOF
{{< /text >}}

Si abres la aplicación Bookinfo en tu navegador (`http://localhost:8080/productpage`), verás la página del producto, como antes. Sin embargo, si intentas acceder al servicio `productpage` desde una cuenta de servicio diferente, deberías ver un error.

Intentemos acceder a la aplicación Bookinfo desde un cliente diferente en el cluster:

{{< text syntax=bash snip_id=deploy_curl >}}
$ kubectl apply -f @samples/curl/curl.yaml@
{{< /text >}}

Dado que el pod `curl` utiliza una cuenta de servicio diferente, no tendrá acceso al servicio `productpage`:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage"
command terminated with exit code 56
{{< /text >}}

## Aplicar la política de autorización de capa 7

Para aplicar las políticas de capa 7, primero necesitas un {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} parael namespace. Este proxy manejará todo el tráfico de capa 7 que ingrese al namespaces.

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
✅ waypoint default/waypoint applied
✅ waypoint default/waypoint is ready!
✅ namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Puedes ver el proxy de waypoint y asegurarte de que tenga el estado `Programmed=True`:

{{< text bash >}}
$ kubectl get gtw waypoint
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         42s
{{< /text >}}

Agregar una [política de autorización L7](/es/docs/ambient/usage/l7-features/) permitirá explícitamente que el servicio `curl` envíe solicitudes `GET` al servicio `productpage`, pero no realice otras operaciones:

{{< text syntax=bash snip_id=deploy_l7_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-waypoint
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/curl
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

Observa que el campo `targetRefs` se utiliza para especificar el servicio de destino para la política de autorización de un proxy de waypoint. La sección de reglas es similar a la anterior, pero esta vez agregaste la sección `to` para especificar la operación permitida.

Recuerda que nuestra política L4 le indicó al ztunnel que solo permitiera conexiones desde la gateway. Ahora necesitamos actualizarla para que también permita conexiones desde el waypoint.

{{< text syntax=bash snip_id=update_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
        - cluster.local/ns/default/sa/waypoint
EOF
{{< /text >}}

{{< tip >}}
Para obtener más información sobre cómo habilitar más características de Istio, lee la [guía de usuario de características de capa 7](/es/docs/ambient/usage/l7-features/).
{{< /tip >}}

Confirma que el nuevo proxy de waypoint está aplicando la política de autorización actualizada:

{{< text bash >}}
$ # Esto falla con un error de RBAC porque no estás usando una operación GET
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage" -X DELETE
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # Esto falla con un error de RBAC porque no se permite la identidad del servicio reviews-v1
$ kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/productpage
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # Esto funciona ya que estás permitiendo explícitamente las solicitudes GET desde el pod curl
$ kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

## Próximos pasos

Con el proxy de waypoint en su lugar, ahora puedes aplicar políticas de capa 7 enel namespace. Además de las políticas de autorización, [puedes usar el proxy de waypoint para dividir el tráfico entre servicios](../manage-traffic/). Esto es útil al realizar despliegues canary o pruebas A/B.
