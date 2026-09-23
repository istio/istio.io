---
title: Presentando soporte multiclúster para modo ambient (alpha)
description: Istio 1.27 agrega soporte alpha de multiclúster ambient, extendiendo la familiar arquitectura liviana y modular de ambient para ofrecer conectividad segura, descubrimiento y balanceo de carga entre clústeres.
date: 2025-08-04
attribution: Jackie Maertens (Microsoft), Keith Mattix (Microsoft), Mikhail Krinkin (Microsoft), Steven Jin (Microsoft)
keywords: [ambient,multicluster]
---

El soporte multiclúster ha sido una de las características más solicitadas de ambient — ¡y a partir de Istio 1.27, está disponible en estado alpha!
Buscamos obtener los beneficios y evitar las complicaciones de las arquitecturas multiclúster mientras usamos el mismo diseño modular que los usuarios de ambient aman.
Este lanzamiento trae la funcionalidad central de una malla multiclúster y sienta las bases para un conjunto de características más rico en próximos lanzamientos.

## El poder y complejidad de Multiclúster

Las arquitecturas multiclúster aumentan la resistencia a interrupciones, reducen su radio de impacto y escalan a través de centros de datos.
Dicho esto, integrar múltiples clústeres plantea desafíos de conectividad, seguridad y operacionales.

En un único clúster de Kubernetes, cada pod puede conectarse directamente a otro pod a través de una IP de pod única o VIP de servicio.
Estas garantías se rompen en arquitecturas multiclúster;
los espacios de direcciones IP de diferentes clústeres podrían superponerse,
e incluso sin superposición, la infraestructura subyacente necesitaría configuración para enrutar tráfico entre clústeres.

La conectividad entre clústeres también presenta desafíos de seguridad.
El tráfico de pod a pod saldrá de los límites del clúster y los pods aceptarán conexiones desde fuera de su clúster.
Sin verificación de identidad en el borde del clúster y cifrado fuerte,
un atacante externo podría explotar un pod vulnerable o interceptar tráfico no cifrado.

Una solución multiclúster debe conectar clústeres de forma segura y hacerlo
a través de APIs simples y declarativas que se mantengan al ritmo de entornos dinámicos donde los clústeres se agregan y eliminan frecuentemente.

## Componentes clave

El multiclúster ambient extiende ambient con componentes nuevos y APIs mínimas para
conectar clústeres de forma segura usando la arquitectura liviana y modular de ambient.
Se basa en el modelo de {{< gloss "namespace sameness" >}}igualdad de namespace{{< /gloss >}}
para que los servicios mantengan sus nombres DNS existentes entre clústeres, permitiéndole controlar la comunicación entre clústeres sin cambiar el código de la aplicación.

### Gateways Este-Oeste

Cada clúster tiene un gateway este-oeste con una IP globalmente enrutable que actúa como punto de entrada para la comunicación entre clústeres.
Un ztunnel se conecta al gateway este-oeste del clúster remoto, identificando el servicio de destino por su nombre con namespace.
El gateway este-oeste luego balancea la carga de la conexión a un pod local.
Usar la IP enrutable del gateway este-oeste elimina la necesidad de configuración de enrutamiento entre clústeres,
y direccionar pods por nombre con namespace en lugar de IP elimina problemas con espacios de IP superpuestos.
Juntas, estas decisiones de diseño habilitan conectividad entre clústeres sin cambiar las redes del clúster o reiniciar cargas de trabajo,
incluso cuando se agregan o eliminan clústeres.

### HBONE doble

El multiclúster ambient usa conexiones [HBONE](/docs/ambient/architecture/hbone) anidadas para asegurar eficientemente el tráfico que atraviesa los límites del clúster.
Una conexión HBONE externa cifra el tráfico al gateway este-oeste y permite que el ztunnel de origen y el gateway este-oeste verifiquen la identidad del otro.
Una conexión HBONE interna cifra el tráfico de extremo a extremo, lo que permite que el ztunnel de origen y el ztunnel de destino verifiquen la identidad del otro.
Al mismo tiempo, las capas HBONE permiten que ztunnel reutilice efectivamente las conexiones entre clústeres, minimizando los handshakes TLS.

{{< image link="./mc-ambient-traffic-flow.png" caption="Flujo de tráfico multiclúster de Istio ambient" >}}

### Descubrimiento de servicios y alcance

Marcar un servicio como global habilita la comunicación entre clústeres.
Istiod configura los gateways este-oeste para aceptar y enrutar tráfico de servicios globales a pods locales y
programa ztunnels para balancear la carga del tráfico de servicios globales a clústeres remotos.

Los administradores de malla definen los criterios basados en etiquetas para servicios globales a través de la API `ServiceScope`,
y los desarrolladores de aplicaciones etiquetan sus servicios en consecuencia.
El `ServiceScope` predeterminado es

{{< text yaml >}}
serviceScopeConfigs:
  - servicesSelector:
      matchExpressions:
        - key: istio.io/global
          operator: In
          values: ["true"]
    scope: GLOBAL
{{< /text >}}

lo que significa que cualquier servicio con la etiqueta `istio.io/global=true` es global.
Aunque el valor predeterminado es directo, la API `ServiceScope` puede expresar condiciones complejas usando una mezcla de ANDs y ORs.

Por defecto, ztunnel balancea la carga del tráfico uniformemente a través de todos los endpoints --incluso los remotos--,
pero esto es configurable a través del campo `trafficDistribution` del servicio para cruzar límites de clúster solo cuando no hay endpoints locales.
Por lo tanto, los usuarios tienen control sobre si y cuándo el tráfico cruza los límites del clúster sin cambios en el código de la aplicación.

## Limitaciones y hoja de ruta

Aunque la implementación actual del multiclúster ambient tiene las características fundamentales para una solución multiclúster,
todavía hay mucho trabajo por hacer.
Buscamos mejorar las siguientes áreas

* La configuración del servicio y waypoint debe ser uniforme en todos los clústeres.
* No hay failover L7 entre clústeres (la política L7 se aplica en el clúster de destino).
* No hay soporte para direccionamiento directo de pods o servicios headless.
* Soporte solo para modelo de despliegue multi-primary.
* Soporte solo para modelo de despliegue de una red por clúster.

También buscamos mejorar nuestra documentación de referencia, guías, pruebas y rendimiento.

Si desea probar el multiclúster ambient, por favor siga [esta guía](/docs/ambient/install/multicluster).
Recuerde, esta característica está en estado alpha y no está lista para uso en producción.
Damos la bienvenida a sus reportes de errores, pensamientos, comentarios y casos de uso -- puede contactarnos en [GitHub](https://github.com/istio/istio) o [Slack](https://istio.slack.com/).


