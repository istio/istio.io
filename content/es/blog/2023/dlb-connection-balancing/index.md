---
title: "Uso del balanceo de carga de conexiones con descarga acelerada en Istio"
description: "Acelere el balanceo de conexiones usando la configuración de balanceo de conexiones DLB en gateways de Istio."
publishdate: 2023-08-08
attribution: "Loong Dai (Intel)"
keywords: [Istio, DLB, gateways]
---

## ¿Qué es el balanceo de carga de conexiones?

El balanceo de carga es una solución de red central utilizada para distribuir el tráfico entre múltiples servidores en una granja de servidores.
Los balanceadores de carga mejoran la disponibilidad y capacidad de respuesta de las aplicaciones y previenen la sobrecarga del servidor. Cada balanceador de carga
se sitúa entre los dispositivos cliente y los servidores backend, recibiendo y luego distribuyendo las solicitudes entrantes a cualquier servidor disponible capaz de cumplirlas.

Para un servidor web común, generalmente tiene múltiples trabajadores (procesadores o hilos). Si muchos clientes se conectan a
un solo trabajador, este trabajador se vuelve ocupado y genera latencia de cola larga mientras otros trabajadores funcionan en estado libre,
afectando el rendimiento del servidor web. El balanceo de carga de conexiones es la solución para esta situación,
que también se conoce como balanceo de conexiones.

## ¿Qué hace Istio para el balanceo de carga de conexiones?

Istio utiliza Envoy como plano de datos.

Envoy proporciona una implementación de balanceo de carga de conexiones llamada Exact connection balancer. Como su nombre lo indica, se mantiene un bloqueo durante el balanceo para que los recuentos de conexiones estén casi exactamente equilibrados entre los trabajadores. Es "casi" exacto en el sentido de que una conexión podría cerrarse en paralelo, haciendo que los recuentos sean incorrectos, pero esto debería rectificarse en la siguiente aceptación. Este balanceador sacrifica el rendimiento de aceptación por precisión y debe usarse cuando hay un pequeño número de conexiones que rara vez cambian, por ejemplo, salida gRPC de service mesh.

Obviamente, no es adecuado para un gateway de entrada ya que un gateway de entrada acepta miles de conexiones en un corto período de tiempo, y el costo de recursos del bloqueo provoca una gran caída en el rendimiento.

Ahora, Envoy ha integrado Intel® Dynamic Load Balancing (Intel®DLB) para acelerar el balanceo de carga de conexiones en casos de alto número de conexiones como gateway de entrada.

## Cómo Intel® Dynamic Load Balancing acelera el balanceo de carga de conexiones en Envoy

Intel DLB es un sistema gestionado por hardware de colas y árbitros que conecta productores y consumidores. Es un dispositivo PCI previsto para residir en el [uncore](https://en.wikipedia.org/wiki/Uncore) del CPU del servidor y puede interactuar con software que se ejecuta en los núcleos, y potencialmente con otros dispositivos.

Intel DLB implementa las siguientes características de balanceo de carga:

- Descarga la gestión de colas del software — útil donde hay costos significativos basados en colas.
    - Especialmente con escenarios multi-productor / multi-consumidor y procesamiento por lotes de encolar a múltiples destinos.
    - Los bloqueos de sobrecarga son necesarios para acceder a colas compartidas en el software. Intel DLB implementa acceso sin bloqueos a colas compartidas.
- Balanceo de carga dinámico y consciente del flujo y reordenamiento.
    - Asegura la distribución equitativa de tareas y una mejor utilización del núcleo de CPU. Puede proporcionar atomicidad basada en flujo si es necesario.
    - Distribuye flujos de alto ancho de banda en muchos núcleos sin pérdida de orden de paquetes.
    - Mejor determinismo y evita latencias de cola excesivas.
    - Utiliza menos huella de memoria IO y ahorra ancho de banda DDR.
- Colas de prioridad (hasta 8 niveles) — permite QOS.
    - Menor latencia para el tráfico que es sensible a la latencia.
    - Mediciones de retardo opcionales en los paquetes.
- Escalabilidad
    - Permite el dimensionamiento dinámico de aplicaciones, escala hacia arriba/abajo sin problemas.
    - Consciente de la energía; la aplicación puede bajar los trabajadores a un estado de menor consumo en casos de carga más ligera.

Hay tres tipos de colas de balanceo de carga:

- Desordenada: Para múltiples productores y consumidores. El orden de las tareas no es importante, y cada tarea se asigna al núcleo del procesador con la carga actual más baja.
- Ordenada: Para múltiples productores y consumidores donde el orden de las tareas es importante. Cuando múltiples tareas son procesadas por múltiples núcleos de procesador, deben reorganizarse en el orden original.
- Atómica: Para múltiples productores y consumidores, donde las tareas se agrupan según ciertas reglas. Estas tareas se procesan utilizando el mismo conjunto de recursos y el orden de las tareas dentro del mismo grupo es importante.

Se espera que un gateway de entrada procese tantos datos como sea posible lo más rápido posible, por lo que el balanceo de carga de conexiones Intel DLB utiliza una cola desordenada.

## Cómo usar el balanceo de carga de conexiones Intel DLB en Istio

Con la versión 1.17, Istio oficialmente soporta el balanceo de carga de conexiones Intel DLB.

Los siguientes pasos muestran cómo usar el balanceo de carga de conexiones Intel DLB en un [Ingress Gateway](/docs/tasks/traffic-management/ingress/ingress-control/) de Istio en una máquina SPR (Sapphire Rapids), asumiendo que el clúster de Kubernetes está en ejecución.

### Paso 1: Preparar el entorno DLB

Instale el controlador Intel DLB siguiendo [las instrucciones en el sitio oficial del controlador Intel DLB](https://www.intel.com/content/www/us/en/download/686372/intel-dynamic-load-balancer.html).

Instale el plugin de dispositivo Intel DLB con el siguiente comando:

{{< text bash >}}
$ kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/dlb_plugin?ref=v0.26.0
{{< /text >}}

Para más detalles sobre el plugin de dispositivo Intel DLB, consulte la [página principal del plugin de dispositivo Intel DLB](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/dlb#config-connection-balance-dlb).

Puede verificar el recurso del dispositivo Intel DLB:

{{< text bash >}}
$ kubectl describe nodes | grep dlb.intel.com/pf
  dlb.intel.com/pf:   2
  dlb.intel.com/pf:   2
...
{{< /text >}}

### Paso 2: Descargar Istio

En este blog usamos 1.17.2. Descargemos la instalación:

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.17.2 TARGET_ARCH=x86_64 sh -
$ cd istio-1.17.2
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

{{< tip >}}
Todas las siguientes acciones se realizarán bajo este directorio.
{{< /tip >}}

Puede verificar que la versión es 1.17.2:

{{< text bash >}}
$ istioctl version
no running Istio pods in "istio-system"
1.17.2
{{< /text >}}

### Paso 3: Instalar Istio

Cree una configuración de instalación para Istio, tenga en cuenta que asignamos 4 CPUs y 1 dispositivo DLB al gateway de entrada y establecemos la concurrencia en 4, que es igual al número de CPU.

{{< text bash >}}
$ cat > config.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        overlays:
          - kind: Deployment
            name: istio-ingressgateway
        podAnnotations:
          proxy.istio.io/config: |
            concurrency: 4
        resources:
          requests:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
          limits:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
        hpaSpec:
          maxReplicas: 1
          minReplicas: 1
  values:
    telemetry:
      enabled: false
EOF
{{< /text >}}

Use `istioctl` para instalar:

{{< text bash >}}
$ istioctl install -f config.yaml --set values.gateways.istio-ingressgateway.runAsRoot=true -y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete                                                                                                                                                                                                                                                                       Making this installation the default for injection and validation.

Thank you for installing Istio 1.17.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/hMHGiwZHPU7UQRWe9
{{< /text >}}

### Paso 4: Configurar el servicio backend

Dado que queremos usar el balanceo de carga de conexiones DLB en el gateway de entrada de Istio, primero necesitamos crear un servicio backend.

Usaremos una muestra proporcionada por Istio para probar, [httpbin]({{< github_tree >}}/release-1.17/samples/httpbin).

{{< text bash >}}
$ kubectl apply -f samples/httpbin/httpbin.yaml
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # The selector matches the ingress gateway pod labels.
  # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

Ahora ha creado una configuración de servicio virtual para el servicio httpbin que contiene dos reglas de ruta que permiten el tráfico para las rutas /status y /delay.

La lista de gateways especifica que solo se permiten solicitudes a través de su httpbin-gateway. Todas las demás solicitudes externas serán rechazadas con una respuesta 404.

### Paso 5: Habilitar el balanceo de carga de conexiones DLB

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: dlb
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: MERGE
      value:
        connection_balance_config:
            extend_balance:
              name: envoy.network.connection_balance.dlb
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.network.connection_balance.dlb.v3alpha.Dlb
EOF
{{< /text >}}

Se espera que si verifica el registro del pod del gateway de entrada `istio-ingressgateway-xxxx` verá entradas de registro similares a:

{{< text bash >}}
$ export POD="$(kubectl get pods -n istio-system | grep gateway | awk '{print $1}')"
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
{{< /text >}}

Envoy detectará y elegirá automáticamente el dispositivo DLB.

### Paso 6: Probar

{{< text bash >}}
$ export HOST="<YOUR-HOST-IP>"
$ export PORT="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')"
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

Tenga en cuenta que utiliza el flag `-H` para establecer el encabezado HTTP Host en `httpbin.example.com` ya que ahora no tiene vinculación DNS para ese host y simplemente está enviando su solicitud a la IP de entrada.

También puede agregar la vinculación DNS en `/etc/hosts` y eliminar el flag `-H`:

{{< text bash >}}
$ echo "$HOST httpbin.example.com" >> /etc/hosts
$ curl -s -I "http://httpbin.example.com:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

Acceda a cualquier otra URL que no haya sido expuesta explícitamente. Debería ver un error HTTP 404:

{{< text bash >}}
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/headers"
HTTP/1.1 404 Not Found
...
{{< /text >}}

Puede activar el nivel de registro de depuración para ver más registros relacionados con DLB:

{{< text bash >}}
$ istioctl pc log ${POD}.istio-system --level debug
istio-ingressgateway-665fdfbf95-2j8px.istio-system:
active loggers:
  admin: debug
  alternate_protocols_cache: debug
  aws: debug
  assert: debug
  backtrace: debug
...
{{< /text >}}

Ejecute `curl` para enviar una solicitud y verá algo como lo siguiente:

{{< text bash >}}
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
2023-05-05T06:37:45.974241Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:269   worker_3 dlb send fd 45 thread=47
2023-05-05T06:37:45.974427Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:286   worker_0 get dlb event 1        thread=46
2023-05-05T06:37:45.974453Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:303   worker_0 dlb recv 45    thread=46
2023-05-05T06:37:45.975215Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:283   worker_0 dlb receive none, skip thread=46
{{< /text >}}

Para más detalles sobre Istio Ingress Gateway, consulte la [Documentación oficial de Istio Ingress Gateway](/docs/tasks/traffic-management/ingress/ingress-control/).

