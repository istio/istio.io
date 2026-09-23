---
title: Monitoreo de Istio Multicluster con Prometheus
description: Configurar Prometheus para monitorear Istio multicluster.
weight: 10
aliases:
  - /help/ops/telemetry/monitoring-multicluster-prometheus
  - /docs/ops/telemetry/monitoring-multicluster-prometheus
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## Visión general

Esta guía está destinada a proporcionar orientación operacional sobre cómo configurar el monitoreo demesh de Istio compuestas por dos
o más clusters individuales de Kubernetes. No está destinada a establecer el *único* camino posible hacia adelante, sino más bien
para demostrar un enfoque viable al telemetría multicluster con Prometheus.

Nuestra recomendación para el monitoreo multicluster de Istio con Prometheus está construida sobre la base de la
[federación jerárquica](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation) de Prometheus.
Las instancias de Prometheus que se despliegan localmente a cada cluster por Istio actúan como recolectores iniciales que luego se federan hasta
una instancia de Prometheus de producción de toda la mesh. Ese Prometheus de toda la mesh puede vivir fuera de la mesh (externo), o en uno
de los clusters dentro de la mesh.

## Configuración de Istio multicluster

Sigue la sección de [instalación multicluster](/es/docs/setup/install/multicluster/) para configurar tus clusters de Istio en uno de los
[modelos de despliegue multicluster](/es/docs/ops/deployment/deployment-models/#multiple-clusters) soportados. Para el propósito de
esta guía, cualquiera de esos enfoques funcionará, con la siguiente advertencia:

**Asegúrate de que una instancia local de Prometheus de Istio esté instalada en cada cluster.**

El despliegue individual de Prometheus de Istio en cada cluster es requerido para formar la base del monitoreo entre clusters por
medio de federación a una instancia lista para producción de Prometheus que se ejecuta externamente o en uno de los clusters.

Valida que tienes una instancia de Prometheus ejecutándose en cada cluster:

{{< text bash >}}
$ kubectl -n istio-system get services prometheus
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
prometheus   ClusterIP   10.8.4.109   <none>        9090/TCP   20h
{{< /text >}}

## Configurar federación de Prometheus

### Prometheus de producción externo

Hay varias razones por las que podrías querer tener una instancia de Prometheus ejecutándose fuera de tu despliegue de Istio.
Tal vez quieras monitoreo a largo plazo separado del cluster que está siendo monitoreado. Tal vez quieras monitorear múltiples
mallas separadas en un solo lugar. O tal vez tengas otras motivaciones. Cualquiera que sea tu razón, necesitarás algunas configuraciones especiales
para hacer que todo funcione.

{{< image width="80%"
    link="./external-production-prometheus.svg"
    alt="Arquitectura de Prometheus de Producción externo para monitorear Istio multicluster."
    caption="Prometheus de Producción externo para monitorear Istio multicluster"
    >}}

{{< warning >}}
Esta guía demuestra conectividad a instancias locales de Prometheus del cluster, pero no aborda consideraciones de seguridad.
Para uso en producción, asegura el acceso a cada endpoint de Prometheus con HTTPS. Además, toma precauciones, como usar un
load-balancer interno en lugar de un endpoint público y la configuración apropiada de reglas de firewall.
{{< /warning >}}

Istio proporciona una manera de exponer servicios de cluster externamente a través de [Gateways](/es/docs/reference/config/networking/gateway/).
Puedes configurar un ingress gateway para el Prometheus local del cluster, proporcionando conectividad externa al endpoint de Prometheus en el cluster.

Para cada cluster, sigue las instrucciones apropiadas de la tarea [Acceso Remoto a Addons de Telemetría](/es/docs/tasks/observability/gateways/#option-1-secure-access-https).
También nota que **DEBERÍAS** establecer acceso seguro (HTTPS).

Después, configura tu instancia externa de Prometheus para acceder a las instancias locales de Prometheus del cluster usando una configuración
como la siguiente (reemplazando el dominio de ingress y el nombre del cluster):

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{INGRESS_DOMAIN}}'
      labels:
        cluster: '{{CLUSTER_NAME}}'
{{< /text >}}

Notas:

* `CLUSTER_NAME` debería establecerse al mismo valor que usaste para crear el cluster (establecido a través de `values.global.multiCluster.clusterName`).

* No se proporciona autenticación a los endpoint(s) de Prometheus. Esto significa que cualquiera puede consultar tus
instancias locales de Prometheus del cluster. Esto puede no ser deseable.

* Sin configuración HTTPS apropiada del gateway, todo se está transportando a través de texto plano. Esto puede no ser
deseable.

### Prometheus de producción en un cluster en malla

Si prefieres ejecutar el Prometheus de producción en uno de los clusters, necesitas establecer conectividad desde él hacia
las otras instancias locales de Prometheus del cluster en la mesh.

Esto es realmente solo una variación de la configuración para federación externa. En este caso, la configuración en el
cluster que ejecuta el Prometheus de producción es diferente de la configuración para el scraping remoto de Prometheus del cluster.

{{< image width="80%"
    link="./in-mesh-production-prometheus.svg"
    alt="Arquitectura de Prometheus de Producción en meshpara monitorear Istio multicluster."
    caption="Prometheus de Producción en meshpara monitorear Istio multicluster"
    >}}

Configura tu Prometheus de producción para acceder tanto a las instancias *locales* como *remotas* de Prometheus.

Primero ejecuta el siguiente comando:

{{< text bash >}}
$ kubectl -n istio-system edit cm prometheus -o yaml
{{< /text >}}

Luego agrega configuraciones para los clusters *remotos* (reemplazando el dominio de ingress y el nombre del cluster para cada cluster) y
agrega una configuración para el cluster *local*:

{{< text yaml >}}
scrape_configs:
- job_name: 'federate-{{REMOTE_CLUSTER_NAME}}'
  scrape_interval: 15s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="kubernetes-pods"}'

  static_configs:
    - targets:
      - 'prometheus.{{REMOTE_INGRESS_DOMAIN}}'
      labels:
        cluster: '{{REMOTE_CLUSTER_NAME}}'

- job_name: 'federate-local'

  honor_labels: true
  metrics_path: '/federate'

  metric_relabel_configs:
  - replacement: '{{CLUSTER_NAME}}'
    target_label: cluster

  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['istio-system']
  params:
    'match[]':
    - '{__name__=~"istio_(.*)"}'
    - '{__name__=~"pilot(.*)"}'
{{< /text >}}
