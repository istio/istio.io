---
title: Entender tu mesh con istioctl describe
description: Te muestra cómo usar istioctl describe para verificar la configuración de un pod de tu mesh.
weight: 30
keywords: [traffic-management, istioctl, debugging, kubernetes]
aliases:
  - /docs/ops/troubleshooting/istioctl-describe
owner: istio/wg-user-experience-maintainers
test: no
---

{{< boilerplate experimental-feature-warning >}}

En Istio 1.3 incluimos el comando [`istioctl experimental describe`](/es/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod).
Este comando de la CLI te proporciona la información necesaria para entender
la configuración que afecta a un {{< gloss >}}pod{{< /gloss >}}. Esta guía te muestra
cómo usar este subcomando experimental para ver si un pod está en la mesh y
verificar su configuración.

El uso básico del comando es el siguiente:

{{< text bash >}}
$ istioctl experimental describe pod <pod-name>[.<namespace>]
{{< /text >}}

Agregar un namespace al nombre del pod tiene el mismo efecto que usar la opción `-n`
de `istioctl` para especificar un namespace distinto del namespace por defecto.

{{< tip >}}
Como en todos los demás comandos de `istioctl`, puedes reemplazar `experimental`
por `x` para mayor comodidad.
{{< /tip >}}

Esta guía asume que ya has desplegado el ejemplo [Bookinfo](/es/docs/examples/bookinfo/)
en tu mesh. Si todavía no lo has hecho,
[inicia los servicios de la aplicación](/es/docs/examples/bookinfo/#start-the-application-services)
y [determina la IP y el puerto del ingress](/es/docs/examples/bookinfo/#determine-the-ingress-ip-and-port)
antes de continuar.

## Verificar que un pod está en la mesh {#verify-a-pod-is-in-the-mesh}

El comando `istioctl describe` devuelve una advertencia si el proxy {{< gloss >}}Envoy{{< /gloss >}}
no está presente en un pod o si el proxy no se ha iniciado. Además, el comando advierte
cuando algunos de los [requisitos de Istio para los pods](/es/docs/ops/deployment/application-requirements/)
no se cumplen.

Por ejemplo, el siguiente comando genera una advertencia que indica que un pod `kube-dns`
no forma parte del service mesh porque no tiene sidecar:

{{< text bash >}}
$ export KUBE_POD=$(kubectl -n kube-system get pod -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod -n kube-system $KUBE_POD
Pod: coredns-f9fd979d6-2zsxk
   Pod Ports: 53/UDP (coredns), 53 (coredns), 9153 (coredns)
WARNING: coredns-f9fd979d6-2zsxk is not part of mesh; no Istio sidecar
--------------------
2021-01-22T16:10:14.080091Z     error   klog    an error occurred forwarding 42785 -> 15000: error forwarding port 15000 to pod 692362a4fe313005439a873a1019a62f52ecd02c3de9a0957cd0af8f947866e5, uid : failed to execute portforward in network namespace "/var/run/netns/cni-3c000d0a-fb1c-d9df-8af8-1403e6803c22": failed to dial 15000: dial tcp4 127.0.0.1:15000: connect: connection refused[]
Error: failed to execute command on sidecar: failure running port forward process: Get "http://localhost:42785/config_dump": EOF
{{< /text >}}

El comando no genera esa advertencia para un pod que forma parte de la mesh,
como el servicio `ratings` de Bookinfo; en su lugar, muestra la configuración de Istio aplicada al pod:

{{< text bash >}}
$ export RATINGS_POD=$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')
$ istioctl experimental describe pod $RATINGS_POD
Pod: ratings-v1-7dc98c7588-8jsbw
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP targets pod port 9080
{{< /text >}}

La salida muestra la siguiente información:

- Los puertos del contenedor del servicio en el pod: `9080` para el contenedor `ratings` en este ejemplo.
- Los puertos del contenedor `istio-proxy` en el pod: `15090` en este ejemplo.
- El protocolo que usa el servicio en el pod: `HTTP` en el puerto `9080` en este ejemplo.

## Verificar la configuración de destination rules {#verify-destination-rule-configurations}

Puedes usar `istioctl describe` para ver qué
[destination rules](/es/docs/concepts/traffic-management/#destination-rules) se aplican a las solicitudes
dirigidas a un pod. Por ejemplo, aplica las
[destination rules de TLS mutuo]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml) de Bookinfo:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Ahora vuelve a describir el pod `ratings`:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pod: ratings-v1-f745cf57b-qrxl2
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
DestinationRule: ratings for "ratings"
   Matching subsets: v1
      (Non-matching subsets v2,v2-mysql,v2-mysql-vm)
   Traffic Policy TLS Mode: ISTIO_MUTUAL
{{< /text >}}

Ahora el comando muestra información adicional:

- La destination rule `ratings` se aplica a las solicitudes al servicio `ratings`.
- El subconjunto de la destination rule `ratings` que coincide con el pod: `v1` en este ejemplo.
- Los demás subconjuntos definidos por la destination rule.
- El pod acepta solicitudes HTTP o de TLS mutuo, pero los clientes usan TLS mutuo.

## Verificar la configuración de virtual services {#verify-virtual-service-configurations}

Cuando los [virtual services](/es/docs/concepts/traffic-management/#virtual-services) configuran
rutas hacia un pod, `istioctl describe` también incluye esas rutas en su salida.
Por ejemplo, aplica los
[virtual services de Bookinfo]({{< github_file>}}/samples/bookinfo/networking/virtual-service-all-v1.yaml)
que enrutan todas las solicitudes a los pods `v1`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

Luego, describe un pod que implemente la versión `v1` del servicio `reviews`:

{{< text bash >}}
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

La salida contiene información similar a la que se mostró antes para el pod `ratings`,
pero también incluye las rutas del virtual service hacia el pod.

El comando `istioctl describe` no solo muestra los virtual services que afectan al pod.
Si un virtual service configura el host del servicio de un pod, pero no le llegará ningún tráfico,
la salida del comando incluye una advertencia. Esto puede ocurrir si el virtual service
en realidad bloquea el tráfico porque nunca lo enruta hacia el subconjunto del pod. Por
ejemplo:

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

La advertencia incluye la causa del problema y cuántas rutas se revisaron, e
incluso te da información sobre las demás rutas configuradas. En este ejemplo,
no llega tráfico al pod `v2` porque la ruta del virtual service dirige todo
el tráfico al subconjunto `v1`.

Si ahora eliminas las destination rules de Bookinfo:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Puedes ver otra función útil de `istioctl describe`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset v1 but NO DESTINATION RULE defining subsets!
{{< /text >}}

La salida te muestra que eliminaste la destination rule, pero no el virtual
service que depende de ella. El virtual service enruta el tráfico al subconjunto `v1`,
pero no hay ninguna destination rule que defina el subconjunto `v1`.
Por lo tanto, el tráfico destinado a la versión `v1` no puede llegar al pod.

Si en este momento actualizas el navegador para enviar una nueva solicitud a Bookinfo,
verás el siguiente mensaje: `Error fetching product reviews`.
Para solucionar el problema, vuelve a aplicar la destination rule:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Al recargar el navegador, verás que la aplicación vuelve a funcionar, y
ejecutar `istioctl experimental describe pod $REVIEWS_V1_POD` ya no genera
advertencias.

## Verificar las rutas de tráfico {#verifying-traffic-routes}

El comando `istioctl describe` también muestra los pesos de la división del tráfico.
Por ejemplo, ejecuta el siguiente comando para enrutar el 90% del tráfico al subconjunto `v1`
y el 10% al subconjunto `v2` del servicio `reviews`:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
{{< /text >}}

Ahora describe el pod `reviews v1`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   Weight 90%
{{< /text >}}

La salida muestra que el virtual service `reviews` tiene un peso del 90% para el
subconjunto `v1`.

Esta función también es útil para otros tipos de enrutamiento. Por ejemplo, puedes desplegar
un enrutamiento basado en encabezados:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
{{< /text >}}

Luego, vuelve a describir el pod:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 2 HTTP routes)
      Route to non-matching subset v2 for (when headers are end-user=jason)
      Route to non-matching subset v3 for (everything)
{{< /text >}}

La salida genera una advertencia porque estás describiendo un pod del subconjunto `v1`.
Sin embargo, la configuración del virtual service que aplicaste enruta el tráfico al subconjunto `v2`
si el encabezado contiene `end-user=jason`, y al subconjunto `v3` en todos
los demás casos.

## Verificar el TLS mutuo estricto {#verifying-strict-mutual-tls}

Siguiendo las instrucciones de [migración a TLS mutuo](/es/docs/tasks/security/authentication/mtls-migration/),
puedes habilitar el TLS mutuo estricto para el servicio `ratings`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: ratings-strict
spec:
  selector:
    matchLabels:
      app: ratings
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Ejecuta el siguiente comando para describir el pod `ratings`:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

La salida indica que las solicitudes al pod `ratings` ahora están restringidas y son seguras.

Sin embargo, a veces un deployment deja de funcionar al cambiar el TLS mutuo a `STRICT`.
La causa probable es que la destination rule no coincidía con la nueva configuración.
Por ejemplo, si configuras los clientes de Bookinfo para que no usen TLS mutuo mediante las
[destination rules de HTTP sin cifrar]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

Si abres Bookinfo en el navegador, verás `Ratings service is currently unavailable`.
Para saber por qué, ejecuta el siguiente comando:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
...
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

La salida incluye una advertencia que describe el conflicto
entre la destination rule y la política de autenticación.

Puedes restablecer el comportamiento correcto aplicando una destination rule que use
TLS mutuo:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

## Conclusión y limpieza {#conclusion-and-cleanup}

Nuestro objetivo con el comando `istioctl x describe` es ayudarte a entender la
configuración de tráfico y de seguridad de tu mesh de Istio.

¡Nos encantaría conocer tus ideas para mejorarlo!
Únete a nosotros en [https://discuss.istio.io](https://discuss.istio.io).

Para eliminar los pods y las configuraciones de Bookinfo que se usaron en esta guía, ejecuta
los siguientes comandos:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl delete -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}
