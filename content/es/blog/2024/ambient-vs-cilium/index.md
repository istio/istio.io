---
title: "Escalando en las nubes: Istio Ambient vs. Cilium"
description: "Un análisis profundo del rendimiento a escala."
publishdate: 2024-10-21
attribution: "Mitch Connors"
keywords: [istio,cilium,analysis]
---

Una pregunta común de los posibles usuarios de Istio es "¿cómo se compara Istio con Cilium?". Aunque Cilium originalmente solo proporcionaba funcionalidad L3/L4, incluida la network policy, las versiones recientes han agregado funcionalidad de service mesh usando Envoy, así como cifrado WireGuard. Al igual que Istio, Cilium es un proyecto Graduado de la CNCF y ha estado en la comunidad durante muchos años.

A pesar de ofrecer un conjunto de características similar en la superficie, los dos proyectos tienen arquitecturas sustancialmente diferentes, sobre todo el uso de eBPF y WireGuard por parte de Cilium para procesar y cifrar el tráfico L4 en el kernel, en contraste con el componente ztunnel de Istio para L4 en el espacio de usuario. Estas diferencias han dado lugar a una especulación sustancial sobre cómo se desempeñará Istio a escala en comparación con Cilium.

Si bien se han realizado muchas comparaciones sobre los modelos de tenencia, los protocolos de seguridad y el rendimiento básico de los dos proyectos, todavía no se ha publicado una evaluación completa a escala empresarial. En lugar de enfatizar el rendimiento teórico, pusimos a prueba el modo ambient de Istio y Cilium, centrándonos en métricas clave como la latencia, el rendimiento y el consumo de recursos. Aumentamos la presión con escenarios de carga realistas, simulando un entorno de Kubernetes bullicioso. Finalmente, aumentamos el tamaño de nuestro cluster de AKS a 1,000 nodos en 11,000 núcleos, para comprender cómo se desempeñan estos proyectos a escala. Nuestros resultados muestran áreas en las que cada uno puede mejorar, pero también indican que Istio es el claro ganador.

## Escenario de prueba

Para llevar a Istio y Cilium a sus límites, creamos 500 servicios diferentes, cada uno respaldado por 100 pods. Cada servicio se encuentra en un namespace separado, que también contiene un cliente generador de carga [Fortio](https://fortio.org/). Restringimos los clientes a un grupo de nodos de 100 máquinas de 32 núcleos, para eliminar el ruido de los clientes coubicados, y asignamos las 900 instancias restantes de 8 núcleos a nuestros servicios.

{{< image width="60%"
    link="./scale-scenario.png"
    alt="Escalando a 500 servicios con 50,000 pods."
    >}}

Para la prueba de Istio, utilizamos el modo ambient de Istio, con un [waypoint proxy](/es/docs/ambient/usage/waypoint/) en cada namespace de servicio y los parámetros de instalación predeterminados. Para que nuestros escenarios de prueba fueran similares, tuvimos que activar algunas características no predeterminadas en Cilium, incluido el cifrado WireGuard, los proxies L7 y Node Init. También creamos una Network Policy de Cilium en cada namespace, con reglas basadas en la ruta HTTP. En ambos escenarios, generamos rotación escalando un servicio a entre 85 y 115 instancias al azar cada segundo, y reetiquetando un namespace cada minuto. Para ver la configuración precisa que utilizamos y para reproducir nuestros resultados, consulta [mis notas](https://github.com/therealmitchconnors/tools/blob/2384dc26f114300687b21f921581a158f27dc9e1/perf/load/many-svc-scenario/README.md).

## Tarjeta de puntuación de escalabilidad

{{< image width="80%"
    link="./scale-scorecard.png"
    alt="Tarjeta de puntuación de escalabilidad: ¡Istio vs. Cilium!"
    >}}
Istio pudo entregar un 56% más de consultas con una latencia de cola un 20% más baja. El uso de CPU fue un 30% menor para Cilium, aunque nuestra medición no incluye los núcleos que Cilium usó para procesar el cifrado, que se realiza en el kernel.

Teniendo en cuenta el recurso utilizado, Istio procesó 2178 consultas por núcleo, frente a las 1815 de Cilium, una mejora del 20%.

* **La ralentización de Cilium:** Cilium, si bien cuenta con una latencia baja impresionante con los parámetros de instalación predeterminados, se ralentiza sustancialmente cuando se activan las características básicas de Istio, como la política L7 y el cifrado. Además, la utilización de memoria y CPU de Cilium se mantuvo alta incluso cuando no fluía tráfico en la mesh. Esto puede afectar la estabilidad y confiabilidad generales de tu cluster, especialmente a medida que crece.
* **Istio, el actor constante:** El modo ambient de Istio, por otro lado, mostró su fortaleza en la estabilidad y el mantenimiento de un rendimiento decente, incluso con la sobrecarga adicional del cifrado. Si bien Istio consumió más memoria y CPU que Cilium bajo prueba, su utilización de CPU se estabilizó en una fracción de la de Cilium cuando no estaba bajo carga.

## Tras bambalinas: ¿Por qué la diferencia?

La clave para comprender estas diferencias de rendimiento radica en la arquitectura y el diseño de cada herramienta.

* **El dilema del Control Plane de Cilium:** Cilium ejecuta una instancia del control plane en cada nodo, lo que genera una sobrecarga en el servidor de la API y una sobrecarga de configuración a medida que tu cluster se expande. Esto con frecuencia provocaba que nuestro servidor de API se bloqueara, seguido de que Cilium dejara de estar listo y todo el cluster dejara de responder.
* **La ventaja de la eficiencia de Istio:** Istio, con su control plane centralizado y su enfoque basado en la identidad, agiliza la configuración y reduce la carga en tu servidor de API y nodos, dirigiendo los recursos críticos al procesamiento y la seguridad de tu tráfico, en lugar de procesar la configuración. Istio aprovecha aún más los recursos no utilizados en el control plane al ejecutar tantas instancias de Envoy como necesite una workload, mientras que Cilium se limita a una instancia de Envoy compartida por nodo.

## Profundizando

Si bien el objetivo de este proyecto es comparar la escalabilidad de Istio y Cilium, varias limitaciones dificultan una comparación directa.

### capa 4 no siempre es capa 4

Si bien tanto Istio como Cilium ofrecen la aplicación de políticas L4, sus API e implementación difieren sustancialmente. Cilium implementa la NetworkPolicy de Kubernetes, que utiliza etiquetas y namespaces para bloquear o permitir el acceso desde y hacia direcciones IP. Istio ofrece una API de AuthorizationPolicy y toma decisiones de permitir y denegar basadas en la identidad TLS utilizada para firmar cada solicitud. La mayoría de las estrategias de defensa en profundidad deberán hacer uso tanto de la NetworkPolicy como de la política basada en TLS para una seguridad integral.

### No todo el cifrado es igual

Si bien Cilium ofrece IPsec para el cifrado compatible con FIPS, la mayoría de las otras características de Cilium, como la política L7 y el balanceo de carga, son incompatibles con IPsec. Cilium tiene una compatibilidad de características mucho mejor cuando se utiliza el cifrado WireGuard, pero WireGuard no se puede utilizar en entornos compatibles con FIPS. Istio, por otro lado, debido a que cumple estrictamente con los estándares del protocolo TLS, siempre utiliza mTLS compatible con FIPS de forma predeterminada.

### Costos ocultos

Mientras que Istio opera completamente en el espacio de usuario, el data plane L4 de Cilium se ejecuta en el kernel de Linux usando eBPF. Las métricas de Prometheus para el consumo de recursos solo miden los recursos del espacio de usuario, lo que significa que todos los recursos del kernel utilizados por Cilium no se tienen en cuenta en esta prueba.

## Recomendaciones: Elegir la herramienta adecuada para el trabajo

Entonces, ¿cuál es el veredicto? Bueno, depende de tus necesidades y prioridades específicas. Para clusteres pequeños con casos de uso puros de L3/L4 y sin requisitos de cifrado, Cilium ofrece una solución rentable y de alto rendimiento. Sin embargo, para clusteres más grandes y un enfoque en la estabilidad, la escalabilidad y las características avanzadas, el modo ambient de Istio, junto con una implementación alternativa de NetworkPolicy, es el camino a seguir. Muchos clientes eligen combinar las características L3/L4 de Cilium con las características L4/L7 y de cifrado de Istio para una estrategia de defensa en profundidad.

Recuerda, el mundo de las redes nativas de la nube está en constante evolución. Mantente atento a los desarrollos tanto en Istio como en Cilium, ya que continúan mejorando y abordando estos desafíos.

## Mantengamos la conversación

¿Has trabajado con el modo ambient de Istio o con Cilium? ¿Cuáles son tus experiencias y conocimientos? Comparte tus pensamientos en los comentarios a continuación. ¡Aprendamos unos de otros y naveguemos juntos por el apasionante mundo de Kubernetes!
