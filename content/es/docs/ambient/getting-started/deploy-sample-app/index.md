---
title: Desplegar una aplicación de ejemplo
description: Despliega la aplicación de ejemplo Bookinfo.
weight: 2
owner: istio/wg-networking-maintainers
test: yes
prev: /docs/ambient/getting-started
---

Para explorar Istio, instalarás la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/), compuesta por cuatro microservicios separados que se utilizan para demostrar varias características de Istio.

{{< image width="50%" link="./bookinfo.svg" caption="La aplicación de ejemplo Bookinfo de Istio está escrita en muchos lenguajes diferentes" >}}

Como parte de esta guía, desplegarás la aplicación Bookinfo y expondrás el servicio `productpage` utilizando una gateway de entrada.

## Desplegar la aplicación Bookinfo

Comienza desplegando la aplicación:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

Para verificar que la aplicación se está ejecutando, comprueba el estado de los pods:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-cf74bb974-nw94k       1/1     Running   0          42s
productpage-v1-87d54dd59-wl7qf   1/1     Running   0          42s
ratings-v1-7c4bbf97db-rwkw5      1/1     Running   0          42s
reviews-v1-5fd6d4f8f8-66j45      1/1     Running   0          42s
reviews-v2-6f9b55c5db-6ts96      1/1     Running   0          42s
reviews-v3-7d99fd7978-dm6mx      1/1     Running   0          42s
{{< /text >}}

Para acceder al servicio `productpage` desde fuera del cluster, necesitas configurar una gateway de entrada.

## Desplegar y configurar la gateway de entrada

Utilizarás la API de Gateway de Kubernetes para desplegar una gateway llamada `bookinfo-gateway`:

{{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
{{< /text >}}

Por defecto, Istio crea un servicio `LoadBalancer` para una gateway. Como accederás a esta gateway a través de un túnel, no necesitas un balanceador de carga. Cambia el tipo de servicio a `ClusterIP` anotando la gateway:

{{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
$ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
{{< /text >}}

Para comprobar el estado de la gateway, ejecuta:

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
{{< /text >}}

Espera a que la gateway se muestre como programada antes de continuar.

## Acceder a la aplicación

Te conectarás al servicio `productpage` de Bookinfo a través de la gateway que acabas de aprovisionar. Para acceder a la gateway, necesitas usar el comando `kubectl port-forward`:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Abre tu navegador y navega a `http://localhost:8080/productpage` para ver la aplicación Bookinfo.

{{< image width="80%" link="./bookinfo-browser.png" caption="Aplicación Bookinfo" >}}

Si actualizas la página, deberías ver que la visualización de las calificaciones de los libros cambia a medida que las solicitudes se distribuyen entre las diferentes versiones del servicio `reviews`.

## Próximos pasos

[Continúa con la siguiente sección](../secure-and-visualize/) para agregar la aplicación a la malla y aprender a proteger y visualizar la comunicación entre las aplicaciones.
