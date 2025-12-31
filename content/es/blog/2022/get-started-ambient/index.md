---
title: "Primeros pasos con Istio Ambient Mesh"
description: "Guía paso a paso para empezar con Istio ambient mesh."
publishdate: 2022-09-07T08:00:00-06:00
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [ambient,demo,guide]
---

{{< warning >}}
Consulta la última [documentación de primeros pasos con ambient mesh](/docs/ambient/getting-started/) para obtener instrucciones actualizadas.
{{< /warning >}}

Ambient mesh es [un nuevo modo de plano de datos para Istio presentado hoy](/blog/2022/introducing-ambient-mesh/). Siguiendo esta guía de primeros pasos, podrás ver cómo ambient mesh puede simplificar la incorporación de aplicaciones, ayudar en las operaciones continuas y reducir el consumo de recursos de la infraestructura del service mesh.

## Instalar Istio con modo Ambient

1. [Descarga la versión de vista previa](https://gcsweb.istio.io/gcs/istio-build/dev/0.0.0-ambient.191fe680b52c1754ee72a06b3e0d3f9d116f2e82) de Istio con soporte para ambient mesh.
2. Consulta los [entornos soportados]({{< github_raw >}}/tree/experimental-ambient#supported-environments). Recomendamos usar un clúster Kubernetes versión 1.21 o superior con dos nodos o más. Si no tienes un clúster Kubernetes, puedes montarlo en local (por ejemplo, usando kind como se muestra abajo) o desplegar uno en Google Cloud o AWS:

{{< text bash >}}
$ kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ambient
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
{{< /text >}}

El perfil `ambient` está diseñado para ayudarte a empezar con ambient mesh.
Instala Istio con el perfil `ambient` en tu clúster Kubernetes usando el `istioctl` descargado arriba:

{{< text bash >}}
$ istioctl install --set profile=ambient
{{< /text >}}

Tras ejecutar el comando anterior, verás una salida como la siguiente, que indica que estos cuatro componentes se han instalado correctamente:

{{< text plain >}}
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ CNI installed
✔ Installation complete
{{< /text >}}

Por defecto, el perfil ambient habilita Istio core, Istiod, el ingress gateway, el agente de túnel zero‑trust (ztunnel) y el plugin CNI.
El plugin Istio CNI se encarga de detectar qué pods de aplicaciones forman parte de la ambient mesh y de configurar la redirección de tráfico entre los ztunnels.
Verás que con el perfil ambient por defecto se instalan los siguientes pods en el namespace `istio-system`:

{{< text bash >}}
$ kubectl get pod -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-cni-node-97p9l                    1/1     Running   0          29s
istio-cni-node-rtnvr                    1/1     Running   0          29s
istio-cni-node-vkqzv                    1/1     Running   0          29s
istio-ingressgateway-5dc9759c74-xlp2j   1/1     Running   0          29s
istiod-64f6d7db7c-dq8lt                 1/1     Running   0          47s
ztunnel-bq6w2                           1/1     Running   0          47s
ztunnel-tcn4m                           1/1     Running   0          47s
ztunnel-tm9zl                           1/1     Running   0          47s
{{< /text >}}

Los componentes `istio-cni` y `ztunnel` se despliegan como [Kubernetes `DaemonSets`](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), que se ejecutan en cada nodo.
Cada pod de Istio CNI revisa todos los pods co‑ubicados en el mismo nodo para ver si forman parte de la ambient mesh.
Para esos pods, el plugin CNI configura la redirección de tráfico para que todo el tráfico entrante y saliente hacia los pods se redirija primero al ztunnel co‑ubicado.
A medida que se despliegan o eliminan pods en el nodo, el plugin CNI continúa monitorizando y actualizando la lógica de redirección.

## Desplegar tus aplicaciones

Usarás la aplicación de ejemplo [Bookinfo](/docs/examples/bookinfo/), que forma parte de la descarga de Istio de los pasos anteriores.
En modo ambient, despliegas aplicaciones en tu clúster Kubernetes exactamente igual que lo harías sin Istio.
Esto significa que puedes tener tus aplicaciones ejecutándose en Kubernetes antes de habilitar ambient mesh, y hacer que se unan al mesh sin necesidad de reiniciar ni reconfigurar tus aplicaciones.

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f https://raw.githubusercontent.com/linsun/sample-apps/main/sleep/sleep.yaml
$ kubectl apply -f https://raw.githubusercontent.com/linsun/sample-apps/main/sleep/notsleep.yaml
{{< /text >}}

{{< image width="75%"
    link="app-not-in-ambient.png"
    caption="Aplicaciones fuera de la ambient mesh con tráfico en texto plano"
    >}}

Nota: `sleep` y `notsleep` son dos aplicaciones sencillas que pueden servir como clientes `curl`.

Conecta `productpage` al ingress gateway de Istio para poder acceder a Bookinfo desde fuera del clúster:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

Prueba tu aplicación Bookinfo: debería funcionar con o sin el gateway. Nota: puedes reemplazar `istio-ingressgateway.istio-system` por la IP (o hostname) del balanceador si tiene una:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

## Añadir tu aplicación a la ambient mesh

Puedes habilitar que todos los pods de un namespace formen parte de la ambient mesh simplemente etiquetando el namespace:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
{{< /text >}}

¡Enhorabuena! Has añadido correctamente todos los pods del namespace `default` a la ambient mesh. Lo mejor es que no necesitas reiniciar ni redeplegar nada.

Envía algo de tráfico de prueba:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

Ganarás inmediatamente comunicación mTLS entre las aplicaciones dentro de la ambient mesh.

{{< image width="75%"
    link="app-in-ambient-secure-overlay.png"
    caption="Peticiones entrantes de sleep a `productpage` y de `productpage` a reviews con la capa secure overlay"
    >}}

Si te interesa el certificado X.509 de cada identidad, puedes aprender más inspeccionando un certificado:

{{< text bash >}}
$ istioctl pc secret ds/ztunnel -n istio-system -o json | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode | openssl x509 -noout -text -in /dev/stdin
{{< /text >}}

Por ejemplo, la salida muestra el certificado para el principal de sleep, válido durante 24 horas y emitido por el clúster Kubernetes local.

{{< text plain >}}
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 307564724378612391645160879542592778778 (0xe762cfae32a3b8e3e50cb9abad32b21a)
    Signature Algorithm: SHA256-RSA
        Issuer: O=cluster.local
        Validity
            Not Before: Aug 29 21:00:14 2022 UTC
            Not After : Aug 30 21:02:14 2022 UTC
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: RSA
                Public-Key: (2048 bit)
                Modulus:
                    ac:db:1a:77:72:8a:99:28:4a:0c:7e:43:fa:ff:35:
                    75:aa:88:4b:80:4f:86:ca:69:59:1c:b5:16:7b:71:
                    dd:74:57:e2:bc:cf:ed:29:7d:7b:fa:a2:c9:06:e6:
                    d6:41:43:2a:3c:2c:18:8e:e8:17:f6:82:7a:64:5f:
                    c4:8a:a4:cd:f1:4a:9c:3f:e0:cc:c5:d5:79:49:37:
                    30:10:1b:97:94:2c:b7:1b:ed:a2:62:d9:3b:cd:3b:
                    12:c9:b2:6c:3c:2c:ac:54:5b:a7:79:97:fb:55:89:
                    ca:08:0e:2e:2a:b8:d2:e0:3b:df:b2:21:99:06:1b:
                    60:0d:e8:9d:91:dc:93:2f:7c:27:af:3e:fc:42:99:
                    69:03:9c:05:0b:c2:11:25:1f:71:f0:8a:b1:da:4a:
                    da:11:7c:b4:14:df:6e:75:38:55:29:53:63:f5:56:
                    15:d9:6f:e6:eb:be:61:e4:ce:4b:2a:f9:cb:a6:7f:
                    84:b7:4c:e4:39:c1:4b:1b:d4:4c:70:ac:98:95:fe:
                    3e:ea:5a:2c:6c:12:7d:4e:24:ab:dc:0e:8f:bc:88:
                    02:f2:66:c9:12:f0:f7:9e:23:c9:e2:4d:87:75:b8:
                    17:97:3c:96:83:84:3f:d1:02:6d:1c:17:1a:43:ce:
                    68:e2:f3:d7:dd:9e:a6:7d:d3:12:aa:f5:62:91:d9:
                    8d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                Server Authentication, Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:93:49:C1:B8:AB:BF:0F:7D:44:69:5A:C3:2A:7A:3C:79:19:BE:6A:B7
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/sleep
{{< /text >}}

Nota: si no obtienes ninguna salida, puede significar que `ds/ztunnel` ha seleccionado un nodo que no gestiona ningún certificado. En su lugar, puedes especificar un pod ztunnel concreto (por ejemplo, `istioctl pc secret ztunnel-tcn4m -n istio-system`) que gestione alguno de los pods de ejemplo.

## Asegurar el acceso a la aplicación

Después de añadir tu aplicación a ambient mesh, puedes asegurar el acceso usando políticas de autorización L4.
Esto te permite controlar el acceso hacia/desde un servicio en función de las identidades de los workloads cliente, pero no a nivel L7 (por ejemplo, métodos HTTP como `GET` y `POST`).

### Políticas de autorización L4

Permite explícitamente que las service accounts `sleep` e `istio-ingressgateway` llamen al servicio `productpage`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
EOF
{{< /text >}}

Confirma que la política de autorización anterior funciona:

{{< text bash >}}
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | head -n1
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
$ # this should fail with an empty reply
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

### Políticas de autorización L7

Usando la Gateway API de Kubernetes, puedes desplegar un waypoint proxy para el servicio `productpage` que use la service account `bookinfo-productpage`. Cualquier tráfico que vaya al servicio `productpage` será mediado, aplicado y observado por el proxy de capa 7 (L7).

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
 name: productpage
 annotations:
   istio.io/service-account: bookinfo-productpage
spec:
 gatewayClassName: istio-mesh
EOF
{{< /text >}}

Observa que `gatewayClassName` debe ser `istio-mesh` para el waypoint proxy.

Consulta el estado del waypoint proxy de `productpage`; deberías ver los detalles del recurso Gateway con estado `Ready`:

{{< text bash >}}
$ kubectl get gateway productpage -o yaml
...
status:
  conditions:
  - lastTransitionTime: "2022-09-06T20:24:41Z"
    message: Deployed waypoint proxy to "default" namespace for "bookinfo-productpage"
      service account
    observedGeneration: 1
    reason: Ready
    status: "True"
    type: Ready
{{< /text >}}

Actualiza nuestra `AuthorizationPolicy` para permitir explícitamente que las service accounts `sleep` e `istio-ingressgateway` hagan `GET` al servicio `productpage`, pero no permitan otras operaciones:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

Confirma que la política de autorización anterior funciona:

{{< text bash >}}
$ # this should fail with an RBAC error because it is not a GET operation
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ -X DELETE | head -n1
$ # this should fail with an RBAC error because the identity is not allowed
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/  | head -n1
$ # this should continue to work
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | head -n1
{{< /text >}}

{{< image width="75%"
    link="app-in-ambient-l7.png"
    caption="Peticiones entrantes de sleep a `productpage` y de `productpage` a reviews con secure overlay y procesamiento L7"
    >}}

Con el waypoint proxy de `productpage` desplegado, también obtendrás automáticamente métricas L7 para todas las peticiones al servicio `productpage`:

{{< text bash >}}
$ kubectl exec deploy/bookinfo-productpage-waypoint-proxy -- curl -s http://localhost:15020/stats/prometheus | grep istio_requests_total
{{< /text >}}

Verás la métrica con `response_code=403` y algunas métricas con `response_code=200`, como se muestra a continuación:

{{< text plain >}}
istio_requests_total{
  response_code="403",
  source_workload="notsleep",
  source_workload_namespace="default",
  source_principal="spiffe://cluster.local/ns/default/sa/notsleep",
  destination_workload="productpage-v1",
  destination_principal="spiffe://cluster.local/ns/default/sa/bookinfo-productpage",
  connection_security_policy="mutual_tls",
  ...
}
{{< /text >}}

La métrica muestra dos respuestas `403` cuando el workload origen (`notsleep`) llama al workload destino (`productpage-v1`), incluyendo los principals de origen y destino mediante una conexión mutual TLS.

## Controlar el tráfico

Despliega un waypoint proxy para el servicio `review` usando la service account `bookinfo-review`, de modo que cualquier tráfico hacia el servicio `review` sea mediado por el waypoint proxy.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
 name: reviews
 annotations:
   istio.io/service-account: bookinfo-reviews
spec:
 gatewayClassName: istio-mesh
EOF
{{< /text >}}

Aplica el virtual service de `reviews` para dirigir el 90% del tráfico a reviews v1 y el 10% a reviews v2.

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-reviews.yaml
{{< /text >}}

Confirma que aproximadamente el 10% del tráfico (de 100 peticiones) va a `reviews-v2`:

{{< text bash >}}
$ kubectl exec -it deploy/sleep -- sh -c 'for i in $(seq 1 100); do curl -s http://istio-ingressgateway.istio-system/productpage | grep reviews-v.-; done'
{{< /text >}}

## Para terminar

Los recursos existentes de Istio siguen funcionando, independientemente de si eliges usar el modo de plano de datos sidecar o ambient.

Echa un vistazo a este breve vídeo para ver a Lin recorriendo la demo de Istio ambient mesh en 5 minutos:

<iframe width="560" height="315" src="https://www.youtube.com/embed/wTGF4S4ZmJ0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Qué sigue

Estamos muy entusiasmados con el nuevo plano de datos ambient de Istio y su arquitectura "ambient" sencilla. Incorporar aplicaciones a un service mesh con el modo ambient ahora es tan simple como etiquetar un namespace. Tus aplicaciones obtendrán beneficios inmediatos como mTLS con identidad criptográfica para el tráfico del mesh y observabilidad L4. Si necesitas controlar acceso, rutas, aumentar resiliencia u obtener métricas L7 entre tus aplicaciones en ambient mesh, puedes aplicar waypoint proxies según lo necesites. Somos muy partidarios de pagar solo por lo que necesitamos: no solo ahorra recursos, sino que también reduce el coste operativo de tener que actualizar constantemente muchos proxies. Te invitamos a probar la nueva arquitectura de plano de datos ambient de Istio para experimentar lo sencilla que es. ¡Esperamos tu [feedback](http://slack.istio.io) en la comunidad de Istio!
