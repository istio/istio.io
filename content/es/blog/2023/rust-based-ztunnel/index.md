---
title: "Presentando Ztunnel basado en Rust para Istio Ambient Service Mesh"
description: Un proxy por nodo especialmente diseñado para Istio ambient mesh.
publishdate: 2023-02-28
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [istio,ambient,ztunnel]
---

El componente ztunnel (túnel de confianza cero) es un proxy por nodo especialmente diseñado para Istio ambient mesh. Es responsable de conectar y autenticar de forma segura las cargas de trabajo dentro de ambient mesh. Ztunnel está diseñado para enfocarse en un pequeño conjunto de características para sus cargas de trabajo en ambient mesh, como mTLS, autenticación, autorización L4 y telemetría, sin terminar el tráfico HTTP de la carga de trabajo ni analizar encabezados HTTP de la carga de trabajo. El ztunnel asegura que el tráfico se transporte de manera eficiente y segura a los proxies waypoint, donde se implementa el conjunto completo de funcionalidades de Istio, como telemetría HTTP y balanceo de carga.

Debido a que ztunnel está diseñado para ejecutarse en todos sus nodos de trabajo de Kubernetes, es crítico mantener su huella de recursos pequeña. Ztunnel está diseñado para ser una parte invisible (o "ambient") de su service mesh con un impacto mínimo en sus cargas de trabajo.

## Arquitectura de Ztunnel

Similar a los sidecars, ztunnel también sirve como cliente xDS y cliente CA:

1. Durante el arranque, se conecta de forma segura al control plane Istiod usando su
token de cuenta de servicio. Una vez que la conexión de ztunnel a Istiod se establece
de forma segura usando TLS, comienza a obtener la configuración xDS como un cliente xDS. Esto
funciona de manera similar a sidecars, gateways o proxies waypoint, excepto que Istiod
reconoce la solicitud de ztunnel y envía la configuración xDS especialmente diseñada
para ztunnel, sobre la cual aprenderá más pronto.
1. También sirve como un cliente CA para gestionar y aprovisionar certificados mTLS en nombre de todas las cargas de trabajo co-ubicadas que gestiona.
1. A medida que entra o sale el tráfico, sirve como un proxy central que maneja el tráfico entrante y saliente (ya sea texto plano fuera de la malla o HBONE dentro de la malla) para todas las cargas de trabajo co-ubicadas que gestiona.
1. Proporciona telemetría L4 (métricas y logs) junto con un servidor administrativo con información de depuración para ayudarlo a depurar ztunnel si es necesario.

{{< image width="100%"
    link="ztunnel-architecture.png"
    caption="Arquitectura de Ztunnel"
    >}}

## ¿Por qué no reutilizar Envoy?

Cuando se anunció Istio ambient service mesh el 7 de septiembre de 2022, el ztunnel se implementó usando un proxy Envoy. Dado que usamos Envoy para el resto de Istio - sidecars, gateways y proxies waypoint - fue natural para nosotros comenzar a implementar ztunnel usando Envoy.

Sin embargo, encontramos que aunque Envoy era un gran ajuste para otros casos de uso, era desafiante implementar ztunnel en Envoy, ya que muchas de las compensaciones, requisitos y casos de uso son dramáticamente diferentes a los de un proxy sidecar o gateway de ingress. Además, la mayoría de las cosas que hacen de Envoy un gran ajuste para esos otros casos de uso, como su rico conjunto de características L7 y extensibilidad, se desperdiciaron en ztunnel que no necesitaba esas características.

## Un ztunnel especialmente diseñado

Después de tener problemas para adaptar Envoy a nuestras necesidades, comenzamos a investigar hacer una implementación especialmente diseñada del ztunnel. Nuestra hipótesis era que al diseñar con un solo caso de uso enfocado en mente desde el principio, podríamos desarrollar una solución que fuera más simple y más eficiente que moldear un proyecto de propósito general a nuestros casos de uso específicos. La decisión explícita de hacer que ztunnel sea simple fue clave para esta hipótesis; una lógica similar no se mantendría para reescribir el gateway, por ejemplo, que tiene una lista enorme de características soportadas e integraciones.

Este ztunnel especialmente diseñado involucró dos áreas clave:

* El protocolo de configuración entre ztunnel y su Istiod
* La implementación en tiempo de ejecución de ztunnel

### Protocolo de configuración

Los proxies Envoy usan el [Protocolo xDS para configuración](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol). Esta es una parte clave de lo que hace que Istio funcione bien, ofreciendo actualizaciones de configuración ricas y dinámicas. Sin embargo, a medida que nos desviamos del camino trillado, la configuración se vuelve más y más específica, lo que significa que es mucho más grande y más costosa de generar. En un sidecar, un solo Servicio con 1 pod, genera aproximadamente ~350 líneas de xDS (en YAML), que ya ha sido desafiante escalar. El ztunnel basado en Envoy era mucho peor, y en algunas áreas tenía atributos de escalado N^2.

Para mantener la configuración de ztunnel lo más pequeña posible, investigamos usar un protocolo de configuración especialmente diseñado, que contiene precisamente la información que necesitamos (y nada más), en un formato eficiente. Por ejemplo, un solo pod podría representarse de manera concisa:

{{< text yaml >}}
name: helloworld-v1-55446d46d8-ntdbk
namespace: default
serviceAccount: helloworld
node: ambient-worker2
protocol: TCP
status: Healthy
waypointAddresses: []
workloadIp: 10.244.2.8
canonicalName: helloworld
canonicalRevision: v1
workloadName: helloworld-v1
workloadType: deployment
{{< /text >}}

Esta información se transporta sobre la API de transporte xDS, pero usa un tipo específico de ambient personalizado. Consulte la [sección de configuración xDS de carga de trabajo](#workload-xds-configuration) para aprender más sobre los detalles de configuración.

Al tener una API especialmente diseñada, podemos empujar lógica al proxy en lugar de en la configuración de Envoy. Por ejemplo, para configurar mTLS en Envoy, necesitamos agregar un gran conjunto idéntico de configuración que ajusta las configuraciones precisas de TLS para cada servicio; con ztunnel, solo necesitamos un solo enum para declarar si se debe usar mTLS o no. El resto de la lógica compleja está integrada directamente en el código de ztunnel.

Con esta API eficiente entre Istiod y ztunnel, encontramos que podríamos configurar ztunnels con información sobre mallas grandes (como aquellas con 100,000 pods) con órdenes de magnitud menos configuración, lo que significa menos costos de CPU, memoria y ancho de banda de red.

### Implementación en tiempo de ejecución

Como su nombre lo sugiere, ztunnel usa un [túnel HTTPS](/blog/2022/introducing-ambient-mesh/#building-an-ambient-mesh) para transportar las solicitudes de los usuarios. Aunque Envoy soporta este túnel, encontramos que el modelo de configuración era limitante para nuestras necesidades. En términos generales, Envoy opera enviando solicitudes a través de una serie de "filtros", comenzando con aceptar una solicitud y terminando con enviar una solicitud. Con nuestros requisitos, que tienen múltiples capas de solicitudes (el túnel mismo y las solicitudes de los usuarios), así como la necesidad de aplicar política por pod después del balanceo de carga, encontramos que necesitaríamos recorrer estos filtros 4 veces por conexión al implementar nuestro anterior ztunnel basado en Envoy. Aunque Envoy tiene [algunas optimizaciones](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/internal_listener) para esencialmente "enviarse una solicitud a sí mismo" en memoria, esto era aún muy complejo y costoso.

Al construir nuestra propia implementación, pudimos diseñar alrededor de estas restricciones desde el principio. Además, tenemos más flexibilidad en todos los aspectos del diseño. Por ejemplo, podríamos elegir compartir conexiones a través de hilos o implementar requisitos más específicos alrededor del aislamiento entre cuentas de servicio. Después de establecer que un proxy especialmente diseñado era viable, nos propusimos elegir los detalles de implementación.

#### Un ztunnel basado en Rust

Con el objetivo de hacer que ztunnel sea rápido, seguro y liviano, [Rust](https://www.rust-lang.org/) fue una elección obvia. Sin embargo, no fue nuestra primera. Dado el extenso uso actual de Go en Istio, esperábamos poder hacer que una implementación basada en Go cumpliera con estos objetivos. En prototipos iniciales, construimos algunas versiones simples tanto de una implementación basada en Go como de una basada en Rust. De nuestras pruebas, encontramos que la versión basada en Go no cumplía con nuestros requisitos de rendimiento y huella. Aunque es probable que pudiéramos haberla optimizado más, sentimos que un proxy basado en Rust nos daría la implementación óptima a largo plazo.

También se consideró una implementación en C++ - probablemente reutilizando partes de Envoy. Sin embargo, esta opción no se persiguió debido a la falta de seguridad de memoria, preocupaciones de experiencia del desarrollador y una tendencia general de la industria hacia Rust.

Este proceso de eliminación nos dejó con Rust, que fue un ajuste perfecto. Rust tiene una fuerte historia de éxito en aplicaciones de alto rendimiento y baja utilización de recursos, especialmente en aplicaciones de red (incluyendo service mesh). Elegimos construir sobre las bibliotecas [Tokio](https://tokio.rs/) y [Hyper](https://hyper.rs/), dos de los estándares de facto en el ecosistema que están extensamente probados en batalla y son fáciles de escribir código asíncrono altamente eficiente con ellas.

## Un recorrido rápido del ztunnel basado en Rust

### Configuración xDS de carga de trabajo

Las configuraciones xDS de carga de trabajo son muy fáciles de entender y depurar. Puede verlas enviando una solicitud a `localhost:15000/config_dump` desde uno de sus pods ztunnel, o usar el conveniente comando `istioctl pc workload`. Hay dos configuraciones xDS de carga de trabajo clave: workloads y policies.

Antes de que sus cargas de trabajo se incluyan en su ambient mesh, aún podrá verlas en el config dump de ztunnel, ya que ztunnel está al tanto de todas las cargas de trabajo independientemente de si están habilitadas para ambient o no. Por ejemplo, a continuación contiene una configuración de carga de trabajo de muestra para un pod helloworld v1 recién desplegado que está fuera de la malla indicado por `protocol: TCP`:

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
      "workloadIp": "10.244.2.8",
      "protocol": "TCP",
      "name": "helloworld-v1-cross-node-55446d46d8-ntdbk",
      "namespace": "default",
      "serviceAccount": "helloworld",
      "workloadName": "helloworld-v1-cross-node",
      "workloadType": "deployment",
      "canonicalName": "helloworld",
      "canonicalRevision": "v1",
      "node": "ambient-worker2",
      "authorizationPolicies": [],
      "status": "Healthy"
    }
  }
}
{{< /text >}}

Después de que el pod se incluye en ambient (etiquetando el namespace default con `istio.io/dataplane-mode=ambient`), el valor `protocol` se reemplaza con `HBONE`, instruyendo a ztunnel a actualizar todas las comunicaciones entrantes y salientes del pod helloworld-v1 para que sean HBONE.

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
      "workloadIp": "10.244.2.8",
      "protocol": "HBONE",
      ...
}
{{< /text >}}

Después de que despliegue cualquier política de autorización a nivel de carga de trabajo, la configuración de la política se enviará como configuración xDS de Istiod a ztunnel y se mostrará bajo `policies`:

{{< text plaintext >}}
{
  "policies": {
    "default/hw-viewer": {
      "name": "hw-viewer",
      "namespace": "default",
      "scope": "WorkloadSelector",
      "action": "Allow",
      "groups": [[[{
        "principals": [{"Exact": "cluster.local/ns/default/sa/sleep"}]
      }]]]
    }
  }
  ...
}
{{< /text >}}

También notará que la configuración de la carga de trabajo se actualiza con referencia a la política de autorización.

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
    "workloadIp": "10.244.2.8",
    ...
    "authorizationPolicies": [
        "default/hw-viewer"
    ],
  }
  ...
}
{{< /text >}}

### Telemetría L4 proporcionada por ztunnel

Puede que se sorprenda gratamente de que los logs de ztunnel son fáciles de entender. Por ejemplo, verá la solicitud HTTP Connect en el ztunnel de destino que indica la IP del pod de origen (`peer_ip`) y la IP del pod de destino.

{{< text plaintext >}}
2023-02-15T20:40:48.628251Z  INFO inbound{id=4399fa68cf25b8ebccd472d320ba733f peer_ip=10.244.2.5 peer_id=spiffe://cluster.local/ns/default/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.244.2.8:5000
{{< /text >}}

Puede ver métricas L4 de sus cargas de trabajo accediendo a la API `localhost:15020/metrics` que proporciona el conjunto completo de [métricas estándar](/docs/reference/config/metrics/) TCP, con las mismas etiquetas que los sidecars exponen. Por ejemplo:

{{< text plaintext >}}
istio_tcp_connections_opened_total{
  reporter="source",
  source_workload="sleep",
  source_workload_namespace="default",
  source_principal="spiffe://cluster.local/ns/default/sa/sleep",
  destination_workload="helloworld-v1",
  destination_workload_namespace="default",
  destination_principal="spiffe://cluster.local/ns/default/sa/helloworld",
  request_protocol="tcp",
  connection_security_policy="mutual_tls"
  ...
} 1
{{< /text >}}

Si instala Prometheus y Kiali, puede ver estas métricas fácilmente desde la UI de Kiali.

{{< image width="100%"
    link="kiali-ambient.png"
    caption="Dashboard de Kiali - telemetría L4 proporcionada por ztunnel"
    >}}

## Conclusión

Estamos súper emocionados de que el nuevo [ztunnel basado en Rust](https://github.com/istio/ztunnel/) esté drásticamente simplificado, sea más liviano y eficiente que el anterior ztunnel basado en Envoy. Con el xDS de carga de trabajo especialmente diseñado para el ztunnel basado en Rust, no solo podrá entender la configuración xDS mucho más fácilmente, sino que también tendrá un tráfico de red y costo drásticamente reducidos entre el control plane de Istiod y los ztunnels. Con Istio ambient ahora fusionado con el master upstream, puede probar el nuevo ztunnel basado en Rust siguiendo nuestra [guía de inicio](/docs/ambient/getting-started/).


