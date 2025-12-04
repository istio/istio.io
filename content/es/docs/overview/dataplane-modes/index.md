---
title: ¿Sidecar o ambient?
description: Aprende sobre los dos modos de data plane de Istio y cuál deberías usar.
weight: 30
keywords: [sidecar, ambient]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Un service mesh de Istio está dividido lógicamente en un data plane y un control plane.

El {{< gloss >}}data plane{{< /gloss >}} es el conjunto de proxies que median y controlan toda la comunicación de red entre microservicios. También recopilan y reportan telemetría sobre todo el tráfico de la mesh.

El {{< gloss >}}control plane{{< /gloss >}} gestiona y configura los proxies en el data plane.

Istio soporta dos {{< gloss "data plane mode">}}modos de data plane{{< /gloss >}} principales:

* **modo sidecar**, que despliega un proxy Envoy junto con cada Pod que inicias en tu cluster, o ejecutándose junto a servicios ejecutándose en VMs.
* **modo ambient**, que usa un proxy capa 4 por nodo, y opcionalmente un proxy Envoy por Namespace para características de capa 7.

Puedes elegir que ciertos namespaces o workloads se ejecuten en cada modo.

## Modo sidecar

Istio ha sido construido sobre el patrón sidecar desde su primer release en 2017. El modo sidecar está bien entendido y ha sido ampliamente probado en situaciones reales, pero viene con un costo de recursos y sobrecarga operacional.

* Cada aplicación que despliegues tiene un proxy Envoy {{< gloss "injection" >}}inyectado{{< /gloss >}} como un sidecar
* Todos los proxies pueden procesar tanto capa 4 como capa 7

## Modo ambient

Lanzado en 2022, el modo ambient fue construido para abordar las deficiencias reportadas por los usuarios del modo sidecar. A partir de Istio 1.22, está listo para producción para casos de uso de cluster único.

* Todo el tráfico es procesado a través de un proxy de nodo solo de capa 4
* Las aplicaciones pueden optar por enrutarse a través de un proxy Envoy para obtener características de capa 7

## Elegir entre sidecar y ambient

Los usuarios a menudo despliegan un mesh para habilitar una postura de seguridad zero-trust como primer paso y luego habilitan selectivamente capacidades L7 según sea necesario. la mesh ambient permite a esos usuarios evitar completamente el costo del procesamiento L7 cuando no es necesario.

<table>
  <thead>
    <tr>
      <td style="border-width: 0px"></td>
      <th><strong>Sidecar</strong></th>
      <th><strong>Ambient</strong></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>Gestión de tráfico</th>
      <td>Conjunto completo de características de Istio</td>
      <td>Conjunto completo de características de Istio (requiere usar waypoint)</td>
    </tr>
    <tr>
      <th>Seguridad</th>
      <td>Conjunto completo de características de Istio</td>
      <td>Conjunto completo de características de Istio: cifrado y autorización L4 en modo ambient. Requiere waypoints para autorización L7.</td>
    </tr>
    <tr>
      <th>Observabilidad</th>
      <td>Conjunto completo de características de Istio</td>
      <td>Conjunto completo de características de Istio: telemetría L4 en modo ambient; observabilidad L7 al usar waypoint</td>
    </tr>
    <tr>
      <th>Extensibilidad</th>
      <td>Conjunto completo de características de Istio</td>
      <td>A través de <a href="/es/docs/ambient/usage/extend-waypoint-wasm">plugins WebAssembly</a> (requiere usar waypoint)<br>La API EnvoyFilter no es compatible.</td>
    </tr>
    <tr>
      <th>Agregar workloads a la mesh</th>
      <td>Etiqueta un namespace y reinicia todos los pods para que se agreguen sidecars</td>
      <td>Etiqueta un namespace - no se requiere reinicio de pods</td>
    </tr>
    <tr>
      <th>Despliegue incremental</th>
      <td>Binario: el sidecar está inyectado o no lo está</td>
      <td>Gradual: L4 siempre está activado, L7 puede ser agregado mediante configuración</td>
    </tr>
    <tr>
      <th>Gestión del ciclo de vida</th>
      <td>Proxies gestionados por el desarrollador de la aplicación</td>
      <td>Administrador de la plataforma</td>
    </tr>
    <tr>
      <th>Utilización de recursos</th>
      <td>Desperdicio; los recursos de CPU y memoria deben ser provisionados para el peor caso de uso de cada pod individual</td>
      <td>Los proxies waypoint pueden ser escalados automáticamente como cualquier otro despliegue de Kubernetes.<br>Un workload con muchas réplicas puede usar un waypoint, en lugar de que cada uno tenga su propio sidecar.</td>
    </tr>
    <tr>
      <th>Costo promedio de recursos</th>
      <td>Grande</td>
      <td>Pequeño</td>
    </tr>
    <tr>
      <th>Latencia promedio (p90/p99)</th>
      <td>0.63ms-0.88ms</td>
      <td>Ambient: 0.16ms-0.20ms<br />Waypoint: 0.40ms-0.50ms</td>
    </tr>
    <tr>
      <th>Pasos de procesamiento L7</th>
      <td>2 (sidecar de origen y destino)</td>
      <td>1 (waypoint de destino)</td>
    </tr>
    <tr>
      <th>Configuración a escala</th>
      <td>Requiere <a href="/es/docs/ops/configuration/mesh/configuration-scoping/">configuración del alcance de cada sidecar</a> para reducir la configuración</td>
      <td>Funciona sin configuración personalizada</td>
    </tr>
    <tr>
      <th>Soporta protocolos "server-first"</th>
      <td><a href="/es/docs/ops/deployment/application-requirements/#server-first-protocols">Requiere configuración</a></td>
      <td>Sí</td>
    </tr>
    <tr>
      <th>Soporte para Kubernetes Jobs</th>
      <td>Complicado por la larga vida del sidecar</td>
      <td>Transparente</td>
    </tr>
    <tr>
      <th>Modelo de seguridad</th>
      <td>Más fuerte: cada workload tiene sus propias claves</td>
      <td>Fuerte: cada agente de nodo tiene solo las claves para los workloads en ese nodo</td>
    </tr>
    <tr>
      <th>Pod de aplicación comprometido<br>da acceso a claves de la mesh</th>
      <td>Sí</td>
      <td>No</td>
    </tr>
    <tr>
      <th>Soporte</th>
      <td>Estable, incluyendo multi-cluster</td>
      <td>Estable, solo single-cluster</td>
    </tr>
    <tr>
      <th>Plataformas compatibles</th>
      <td>Kubernetes (cualquier CNI)<br />Máquinas virtuales</td>
      <td>Kubernetes (cualquier CNI)</td>
    </tr>
  </tbody>
</table>

## capa 4 vs capa 7 features

El sobrecosto para procesar protocolos en capa 7 es significativamente mayor que el procesamiento de paquetes en capa 4. Para un servicio dado, si tus requisitos pueden ser satisfechos en L4, la mesh de servicio puede ser entregada a un costo sustancialmente menor.

### Security

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Encryption</th>
      <td>Toda la comunicación entre pods está cifrada usando {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}}.</td>
      <td>N/A&mdash;la identidad del servicio en Istio está basada en TLS.</td>
    </tr>
    <tr>
      <th>Autenticación de servicio a servicio</th>
      <td>{{< gloss >}}SPIFFE{{< /gloss >}}, a través de certificados mTLS. Istio emite un certificado X.509 corto que codifica la identidad de la cuenta de servicio del pod.</td>
      <td>N/A&mdash;la identidad del servicio en Istio está basada en TLS.</td>
    </tr>
    <tr>
      <th>Autorización de servicio a servicio</th>
      <td>Autorización basada en red, más políticas de identidad, por ejemplo:
        <ul>
          <li>A puede aceptar llamadas entrantes solo de "10.2.0.0/16";</li>
          <li>A puede llamar a B.</li>
        </ul>
      </td>
      <td>Política completa, por ejemplo:
        <ul>
          <li>A puede GET /foo en B solo con credenciales de usuario final válidas que contienen el ámbito READ.</li>
        </ul>
      </td>
    </tr>
    <tr>
      <th>Autenticación de usuario final</th>
      <td>N/A&mdash;no podemos aplicar configuraciones por usuario.</td>
      <td>Autenticación local de JWTs, soporte para autenticación remota a través de flujos OAuth y OIDC.</td>
    </tr>
    <tr>
      <th>Autorización de usuario final</th>
      <td>N/A&mdash;ver arriba.</td>
      <td>Las políticas de servicio a servicio pueden ser extendidas para requerir <a href="/es/docs/reference/config/security/conditions/">credenciales de usuario final con ámbitos específicos, emisores, principal, audiencias, etc.</a><br />La implementación completa de acceso usuario a recurso puede ser realizada usando autorización externa, permitiendo políticas por solicitud con decisiones de un servicio externo, por ejemplo OPA.</td>
    </tr>
  </tbody>
</table>

### Observability

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Logging</th>
      <td>Información de red básica: 5-tupla de red, bytes enviados/recibidos, etc. <a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">Ver documentación de Envoy</a>.</td>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators">Logging de metadatos de solicitud completo</a>, además de la información de red básica.</td>
    </tr>
    <tr>
      <th>Tracing</th>
      <td>No hoy; posiblemente en el futuro con HBONE.</td>
      <td>Envoy participa en el seguimiento distribuido. <a href="/es/docs/tasks/observability/distributed-tracing/overview/">Ver resumen de Istio sobre el seguimiento</a>.</td>
    </tr>
    <tr>
      <th>Metrics</th>
      <td>Solo TCP (bytes enviados/recibidos, número de paquetes, etc.).</td>
      <td>Métricas RED L7: tasa de solicitudes, tasa de errores, duración de la solicitud (latencia).</td>
    </tr>
  </tbody>
</table>

### Traffic management

<table>
  <thead>
    <tr>
      <td style="border-width: 0px" width="20%"></td>
      <th width="40%">L4</th>
      <th width="40%">L7</th>
    </tr>
   </thead>
   <tbody>
    <tr>
      <th>Load balancing</th>
      <td>Solo a nivel de conexión. <a href="/es/docs/tasks/traffic-management/tcp-traffic-shifting/">Ver tarea de desplazamiento de tráfico TCP</a>.</td>
      <td>Por solicitud, habilitando, por ejemplo, implementaciones de canary, tráfico gRPC, etc. <a href="/es/docs/tasks/traffic-management/traffic-shifting/">Ver tarea de desplazamiento de tráfico HTTP</a>.</td>
    </tr>
    <tr>
      <th>Circuit breaking</th>
      <td><a href="/es/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-TCPSettings">Solo TCP</a>.</td>
      <td><a href="/es/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings">Configuraciones HTTP</a> además de TCP.</td>
    </tr>
    <tr>
      <th>Detección de outliers</th>
      <td>En el establecimiento/fallo de la conexión.</td>
      <td>En éxito/fallo de la solicitud.</td>
    </tr>
    <tr>
      <th>Rate limiting</th>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rate_limit_filter#config-network-filters-rate-limit">Rate limit en datos de conexión L4, en el establecimiento de la conexión</a>, con opciones de rate limiting global y local.</td>
      <td><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter#config-http-filters-rate-limit">Rate limit en metadatos de solicitud L7</a>, por solicitud.</td>
    </tr>
    <tr>
      <th>Timeouts</th>
      <td>Solo establecimiento de conexión (la configuración de keep-alive de la conexión se configura a través de las configuraciones de circuit breaking).</td>
      <td>Por solicitud.</td>
    </tr>
    <tr>
      <th>Retries</th>
      <td>Retry establecimiento de conexión</td>
      <td>Retry fallo de solicitud.</td>
    </tr>
    <tr>
      <th>Inyección de fallos</th>
      <td>N/A&mdash;la inyección de fallos no puede ser configurada en conexiones TCP.</td>
      <td>Fallas completas de aplicación y de conexión (<a href="/es/docs/tasks/traffic-management/fault-injection/">timeouts, delays, códigos de respuesta específicos</a>).</td>
    </tr>
    <tr>
      <th>Traffic mirroring</th>
      <td>N/A&mdash;solo HTTP</td>
      <td><a href="/es/docs/tasks/traffic-management/mirroring/">Mirroring porcentual de solicitudes a múltiples backends</a>.</td>
    </tr>
  </tbody>
</table>

## Unsupported features

Las siguientes features están disponibles en modo sidecar, pero aún no implementadas en modo ambient:

* Interoperabilidad sidecar-waypoint
* Instalaciones multi-cluster
* Soporte multi-red
* Soporte de VM
