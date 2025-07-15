---
title: "Istio publica los resultados de la auditoría de seguridad de ztunnel"
description: Pasa con gran éxito.
publishdate: 2025-04-18
attribution: "Craig Box - Solo.io, para el Grupo de Trabajo de Seguridad de Productos de Istio"
keywords: [istio,security,audit,ztunnel,ambient]
---

El modo ambient de Istio divide el service mesh en dos capas distintas: el procesamiento de capa 7 (el "[waypoint proxy](/es/docs/ambient/usage/waypoint/)"), que sigue siendo impulsado por el proxy Envoy tradicional; y una superposición segura (el "túnel de zero-trust" o "[ztunnel](https://github.com/istio/ztunnel)"), que es [una nueva base de código](/blog/2023/rust-based-ztunnel/), escrita desde cero en Rust.

Nuestra intención es que el proyecto ztunnel sea seguro para instalarlo por defecto en todos los clusteres de Kubernetes y, para ello, debe ser seguro y tener un buen rendimiento.

Demostramos exhaustivamente el rendimiento de ztunnel, demostrando que es [la forma de mayor ancho de banda para lograr una red segura de zero-trust en Kubernetes](/blog/2025/ambient-performance/), proporcionando un mayor rendimiento de TCP que incluso los data planes en el kernel como IPsec y WireGuard, y que su rendimiento ha aumentado en un 75% en las últimas 4 versiones.

Hoy, nos complace validar la seguridad de ztunnel, publicando [los resultados de una auditoría de la base de código](https://ostif.org/wp-content/uploads/2025/04/Istio-Ztunnel-Final-Summary-Report-1.pdf) realizada por [Trail of Bits](https://www.trailofbits.com/).

Nos gustaría agradecer a la [Cloud Native Computing Foundation](https://cncf.io/) por financiar este trabajo y a [OSTIF por su coordinación](https://ostif.org/istio-ztunnel-audit-complete/).

## Alcance y hallazgos generales

Istio ha sido evaluado en [2020](/blog/2021/ncc-security-assessment/) y [2023](/blog/2023/ada-logics-security-assessment/), con proxy Envoy [recibiendo una evaluación independiente](https://github.com/envoyproxy/envoy#security-audit). El alcance de esta revisión fue el nuevo código en el modo ambient de Istio, el componente ztunnel: específicamente el código relacionado con la autorización L4, el proxy de solicitudes entrantes, la seguridad de la capa de transporte (TLS) y la gestión de certificados.

Los auditores declararon que "la base de código de ztunnel está bien escrita y estructurada", y no encontraron ninguna vulnerabilidad en el código. Sus tres hallazgos, uno de severidad media y dos informativos, se refieren a recomendaciones sobre factores externos, incluida la cadena de suministro de software y las pruebas.

## Resolución y mejoras sugeridas

### Mejora de la gestión de dependencias

En el momento de la auditoría, el informe de [auditoría de cargo](https://crates.io/crates/cargo-audit) para las dependencias de ztunnel mostraba tres versiones con avisos de seguridad actuales. No se sugirió que se pudiera acceder a ninguna ruta de código vulnerable en las dependencias de ztunnel, y los mantenedores actualizarían regularmente las dependencias a las últimas versiones apropiadas. Para agilizar esto, hemos [adoptado el Dependabot de GitHub](https://github.com/istio/ztunnel/pull/1400) para actualizaciones automáticas.

Los auditores señalaron el riesgo de que las cajas de Rust en la cadena de dependencias de ztunnel no tuvieran mantenimiento o fueran mantenidas por un solo propietario. Esta es una situación común en el ecosistema de Rust (y de hecho en todo el código abierto). Reemplazamos las dos cajas que se identificaron explícitamente.

### Mejora de la cobertura de las pruebas

El equipo de Trail of Bits descubrió que la mayor parte de la funcionalidad de ztunnel está bien probada, pero identificó algunas rutas de código de manejo de errores que no estaban cubiertas por las [pruebas de mutación](https://mutants.rs/).

Evaluamos las sugerencias y descubrimos que las lagunas en la cobertura destacadas por estos resultados se aplican al código de prueba y al código que no afecta a la corrección.

Si bien las pruebas de mutación son útiles para identificar áreas potenciales de mejora, el objetivo no es llegar a un punto en el que un informe no devuelva resultados. Las mutaciones pueden no desencadenar fallos de prueba en una serie de casos esperados, como un comportamiento sin un resultado "correcto" (por ejemplo, mensajes de registro), un comportamiento que solo afecta al rendimiento pero no a la corrección (medido fuera del alcance que conocen las herramientas), rutas de código que tienen múltiples formas de lograr el mismo resultado o código utilizado solo para pruebas. Las pruebas y la seguridad son una prioridad principal para el equipo de Istio y estamos mejorando constantemente nuestra cobertura de pruebas, utilizando herramientas como las pruebas de mutación y [desarrollando soluciones novedosas](https://blog.howardjohn.info/posts/ztunnel-testing/) para probar los proxies.

### Refuerzo del análisis de encabezados HTTP

Se utilizó una biblioteca de terceros para analizar el valor del encabezado HTTP [Forwarded](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Forwarded), que puede estar presente en las conexiones realizadas a ztunnel. Los auditores señalaron que el análisis de encabezados es un área común de ataque y expresaron su preocupación de que la biblioteca que utilizamos no fuera probada con fuzzing. Dado que solo usábamos esta biblioteca para analizar un encabezado, [escribimos un analizador personalizado para el encabezado Forwarded](https://github.com/istio/ztunnel/pull/1418), completo con un arnés de fuzzing para probarlo.

## Involúcrate

Con un rendimiento sólido y ahora una seguridad validada, el modo ambient continúa avanzando en el estado del arte en el diseño de service mesh. Te animamos a que lo pruebes hoy mismo.

Si deseas involucrarte en la seguridad de los productos de Istio o convertirte en un mantenedor, ¡nos encantaría tenerte! Únete a [nuestro espacio de trabajo de Slack](https://slack.istio.io/) o a [nuestras reuniones públicas](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) para plantear problemas o aprender sobre lo que estamos haciendo para mantener la seguridad de Istio.
