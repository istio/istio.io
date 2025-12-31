---
title: "Trayendo gestión de tráfico consciente de IA a Istio: Soporte de Gateway API Inference Extension"
description: Una forma más inteligente y dinámica de optimizar el enrutamiento de tráfico de IA basado en métricas en tiempo real y las características únicas de las cargas de trabajo de inferencia.
publishdate: 2025-07-28
attribution: "Lior Lieberman (Google), Keith Mattix (Microsoft), Aslak Knutsen (Red Hat)"
keywords: [istio,AI,inference,gateway-api-inference-extension]
---

El mundo de la inferencia de IA en Kubernetes presenta desafíos únicos que las arquitecturas tradicionales de enrutamiento de tráfico no fueron diseñadas para gestionar. Mientras que Istio ha sobresalido durante mucho tiempo en la gestión del tráfico de microservicios con sofisticadas características de balanceo de carga, seguridad y observabilidad, las demandas de las cargas de trabajo de Modelos de Lenguaje Grande (LLM) requieren funcionalidad especializada.

Por eso nos emociona anunciar el soporte de Istio para la extensión de Gateway API Inference, trayendo enrutamiento inteligente consciente de modelos y LoRA a Istio.

## Por qué las cargas de trabajo de IA necesitan un tratamiento especial

Los servicios web tradicionales típicamente gestionan solicitudes rápidas y sin estado medidas en milisegundos. Las cargas de trabajo de inferencia de IA operan en un paradigma completamente diferente que desafía los enfoques convencionales de balanceo de carga de varias formas fundamentales.

### El desafío de escala y duración

A diferencia de las respuestas API típicas que se completan en milisegundos, las solicitudes de inferencia de IA a menudo tardan significativamente más en procesarse - a veces varios segundos o incluso minutos. Esta diferencia dramática en el tiempo de procesamiento significa que las decisiones de enrutamiento tienen mucho más impacto que en los servicios web tradicionales. Una sola solicitud mal enrutada puede atar recursos costosos de GPU durante períodos extendidos, creando efectos en cascada en todo el sistema.

Las características de la carga útil son igualmente desafiantes. Las solicitudes de inferencia de IA frecuentemente involucran cargas útiles sustancialmente más grandes, especialmente cuando se trata de sistemas de Generación Aumentada por Recuperación (RAG), conversaciones de múltiples turnos con contexto extenso, o entradas multimodales que incluyen imágenes, audio o video. Estas cargas útiles grandes requieren diferentes estrategias de almacenamiento en búfer, transmisión y tiempos de espera que las APIs HTTP tradicionales.

### Patrones de consumo de recursos

Quizás más críticamente, una sola solicitud de inferencia puede consumir todos los recursos de una GPU durante el procesamiento. Esto es fundamentalmente diferente del servicio de solicitudes tradicional donde múltiples solicitudes pueden procesarse concurrentemente en los mismos recursos de cómputo. Cuando una GPU está completamente comprometida con una solicitud, las solicitudes adicionales deben hacer cola, haciendo que la decisión de programación y enrutamiento sea mucho más impactante que aquellas para cargas de trabajo de API estándar.

Esta exclusividad de recursos significa que los algoritmos simples de round-robin o de menos conexiones pueden crear desequilibrios severos. Enviar solicitudes a un servidor que ya está procesando una tarea de inferencia compleja no solo agrega latencia, puede causar contención de recursos que impacta el rendimiento para todas las solicitudes en cola.

### Consideraciones de estado y gestión de memoria

Los modelos de IA a menudo mantienen cachés en memoria que impactan significativamente el rendimiento. Los cachés KV almacenan cálculos intermedios de atención para tokens procesados previamente, sirviendo como el consumidor principal de memoria GPU durante la generación y a menudo convirtiéndose en el cuello de botella más común. Cuando la utilización del caché KV se acerca a los límites, el rendimiento se degrada dramáticamente, haciendo que el enrutamiento consciente del caché sea esencial.

Además, muchos despliegues modernos de IA usan adaptadores afinados como [LoRA](https://arxiv.org/abs/2106.09685) (Adaptación de Bajo Rango) para personalizar el comportamiento del modelo para usuarios, organizaciones o casos de uso específicos. Estos adaptadores consumen memoria GPU y tiempo de carga cuando se cambian. Un servidor de modelo que ya tiene el adaptador LoRA requerido cargado puede procesar solicitudes inmediatamente, mientras que los servidores sin el adaptador enfrentan una costosa sobrecarga de carga que puede tomar segundos en completarse.

### Dinámicas de cola y criticidad

Las cargas de trabajo de inferencia de IA también introducen el concepto de criticidad de solicitud que es menos común en servicios tradicionales. Las aplicaciones interactivas en tiempo real (como chatbots o generación de contenido en vivo) requieren baja latencia y deben ser priorizadas, mientras que los trabajos de procesamiento por lotes o cargas de trabajo experimentales pueden tolerar mayor latencia o incluso ser descartadas durante la sobrecarga del sistema.

Los balanceadores de carga tradicionales carecen del contexto para tomar estas decisiones basadas en criticidad. No pueden distinguir entre una consulta de soporte al cliente sensible al tiempo y un trabajo por lotes en segundo plano, lo que lleva a una asignación de recursos subóptima durante períodos de alta demanda.

Aquí es donde el enrutamiento consciente de inferencia se vuelve crítico. En lugar de tratar todos los backends como cajas negras equivalentes, necesitamos decisiones de enrutamiento que entiendan el estado actual y las capacidades de cada servidor de modelo, incluyendo su profundidad de cola, utilización de memoria, adaptadores cargados y capacidad para manejar solicitudes de diferentes niveles de criticidad.

## Gateway API Inference Extension: Una solución nativa de Kubernetes

La [Extensión de Inferencia de Gateway API de Kubernetes](https://gateway-api-inference-extension.sigs.k8s.io) ha introducido soluciones a estos desafíos, construyendo sobre la base probada de Gateway API de Kubernetes mientras agrega inteligencia específica de IA. En lugar de requerir que las organizaciones parcheen soluciones personalizadas o abandonen su infraestructura existente de Kubernetes, la extensión proporciona un enfoque estandarizado y neutral al proveedor para la gestión inteligente de tráfico de IA.

La extensión introduce dos Definiciones de Recursos Personalizados clave que trabajan juntas para abordar los desafíos de enrutamiento que hemos delineado. El recurso **InferenceModel** proporciona una abstracción para que los propietarios de cargas de trabajo de inferencia de IA definan endpoints de modelo lógicos, mientras que el recurso **InferencePool** da a los operadores de plataforma las herramientas para gestionar la infraestructura backend con conciencia de cargas de trabajo de IA.

Al extender el modelo familiar de Gateway API en lugar de crear un paradigma completamente nuevo, la extensión de inferencia permite a las organizaciones aprovechar su experiencia existente en Kubernetes mientras obtienen las capacidades especializadas que las cargas de trabajo de IA demandan. Este enfoque asegura que los equipos puedan adoptar el enrutamiento inteligente de inferencia alineado con conocimiento y herramientas de redes familiares.

Nota: InferenceModel probablemente cambiará en futuras versiones de Gateway API Inference Extension.

### InferenceModel

El recurso InferenceModel permite a los propietarios de cargas de trabajo de inferencia definir endpoints de modelo lógicos que abstraen las complejidades del despliegue backend.

{{< text yaml >}}
apiVersion: inference.networking.x-k8s.io/v1alpha2
kind: InferenceModel
metadata:
  name: customer-support-bot
  namespace: ai-workloads
spec:
  modelName: customer-support
  criticality: Critical
  poolRef:
    name: llama-pool
  targetModels:
    - name: llama-3-8b-customer-v1
      weight: 80
    - name: llama-3-8b-customer-v2
      weight: 20
{{< /text >}}

Esta configuración expone un modelo de customer-support que enruta inteligentemente entre dos variantes backend, habilitando despliegues seguros de nuevas versiones de modelo mientras mantiene la disponibilidad del servicio.

### InferencePool

El InferencePool actúa como un servicio backend especializado que entiende las características de las cargas de trabajo de IA:

{{< text yaml >}}
apiVersion: inference.networking.x-k8s.io/v1alpha2
kind: InferencePool
metadata:
  name: llama-pool
  namespace: ai-workloads
spec:
  targetPortNumber: 8000
  selector:
    app: llama-server
    version: v1
  extensionRef:
    name: llama-endpoint-picker
{{< /text >}}

Cuando se integra con Istio, este pool descubre automáticamente servidores de modelo a través del descubrimiento de servicios de Istio.

## Cómo funciona el enrutamiento de inferencia en Istio

La implementación de Istio se basa en la base probada de gestión de tráfico del service mesh. Cuando una solicitud entra a la malla a través de un Gateway de Kubernetes, sigue las reglas de coincidencia de HTTPRoute estándar de Gateway API. Sin embargo, en lugar de usar algoritmos de balanceo de carga tradicionales, el backend es elegido por un servicio Endpoint Picker (EPP).

El EPP evalúa múltiples factores para seleccionar el backend óptimo:

* **Evaluación de criticidad de solicitud**: Las solicitudes críticas reciben enrutamiento prioritario a servidores disponibles, mientras que solicitudes de menor criticidad (Standard o Sheddable) pueden ser descartadas durante períodos de alta utilización.

* **Análisis de utilización de recursos**: La extensión monitorea el uso de memoria GPU, particularmente la utilización del caché KV, para evitar abrumar servidores que se están acercando a los límites de capacidad.

* **Afinidad de adaptador**: Para modelos que usan adaptadores LoRA, las solicitudes se enrutan preferentemente a servidores que ya tienen el adaptador requerido cargado, eliminando la costosa sobrecarga de carga.

* **Balanceo de carga consciente de caché de prefijo**: Las decisiones de enrutamiento consideran estados de caché KV distribuidos a través de servidores de modelo, y priorizan servidores de modelo que ya tienen el prefijo en su caché.

* **Optimización de profundidad de cola**: Al rastrear las longitudes de cola de solicitudes a través de los backends, el sistema evita crear puntos calientes que aumentarían la latencia general.

Este enrutamiento inteligente opera de forma transparente dentro de la arquitectura existente de Istio, manteniendo compatibilidad con características como TLS mutuo, políticas de acceso y rastreo distribuido.

### Flujo de solicitud de enrutamiento de inferencia

{{< image width="100%"
    link="./inference-request-flow.svg"
    alt="Flujo de una solicitud de inferencia con enrutamiento de gateway-api-inference-extension."
    >}}

## El camino por delante

La hoja de ruta futura incluye características relacionadas con Istio como:

* **Soporte para Waypoints** - A medida que Istio continúa evolucionando hacia la arquitectura ambient mesh, el enrutamiento consciente de inferencia se integrará en los proxies waypoint para proporcionar aplicación de políticas centralizada y escalable para cargas de trabajo de IA.

Más allá de las innovaciones específicas de Istio, la comunidad de Gateway API Inference Extension también está desarrollando activamente varias capacidades avanzadas que mejorarán aún más el enrutamiento para cargas de trabajo de inferencia de IA en Kubernetes:

* **Integración HPA para métricas de IA**: Autoescalado Horizontal de Pods basado en métricas específicas de modelo en lugar de solo CPU y memoria.

* **Soporte de entrada multimodal**: Enrutamiento optimizado para grandes entradas y salidas multimodales (imágenes, audio, video) con capacidades inteligentes de almacenamiento en búfer y transmisión.

* **Soporte de aceleradores heterogéneos**: Enrutamiento inteligente a través de diferentes tipos de aceleradores (GPUs, TPUs, chips de IA especializados) con balanceo de carga consciente de latencia y costos.

## Comenzando con Istio Inference Extension

¿Listo para probar el enrutamiento consciente de inferencia? ¡La implementación está oficialmente disponible comenzando con Istio 1.27!

Para instalación y guías, por favor siga la guía específica de Istio en el [sitio web de Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/guides/#__tabbed_3_2).

## Impacto y beneficios de rendimiento

Las evaluaciones tempranas muestran mejoras significativas de rendimiento con enrutamiento consciente de inferencia, incluyendo latencia p90 sustancialmente más baja a tasas de consulta más altas y latencias de cola de extremo a extremo reducidas en comparación con el balanceo de carga tradicional.

Para resultados de benchmark detallados y metodología, vea la [evaluación de rendimiento de Gateway API Inference Extension](https://kubernetes.io/blog/2025/06/05/introducing-gateway-api-inference-extension/#benchmarks) con datos de prueba usando GPUs H100 y despliegues vLLM.

La integración con la infraestructura existente de Istio significa que estos beneficios vienen con sobrecarga operacional mínima, y sus configuraciones existentes de monitoreo, seguridad y gestión de tráfico continúan funcionando sin cambios.

## Conclusión

Gateway API Inference Extension representa un paso significativo adelante en hacer que Kubernetes esté verdaderamente listo para IA, y la implementación de Istio trae esta inteligencia a la capa de service mesh donde puede tener el máximo impacto. Al combinar enrutamiento consciente de inferencia con las capacidades probadas de seguridad, observabilidad y gestión de tráfico de Istio, estamos habilitando a las organizaciones para ejecutar cargas de trabajo de IA con la misma excelencia operacional que esperan de sus servicios tradicionales.

---

*¿Tiene una pregunta o quiere involucrarse? [Únase al Slack de Kubernetes](https://slack.kubernetes.io/) y luego encuéntrenos en el canal [#gateway-api-inference-extension](https://kubernetes.slack.com/archives/C08E3RZMT2P) o [discuta en el Slack de Istio](https://slack.istio.io).*


