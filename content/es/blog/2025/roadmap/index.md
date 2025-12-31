---
title: "Hoja de ruta de Istio para 2025-2026"
description: Mirando hacia adelante a lo que sigue para Istio.
publishdate: 2025-07-25
attribution: "Mitch Connors, para el TOC de Istio"
keywords: [Istio,roadmap,ambient]
---

Durante los próximos 12 meses, nos enfocaremos en mejorar la paridad entre el modo sidecar y el modo ambient, proporcionando un camino soportado para que los usuarios de sidecar migren al plano de datos ambient cuando estén listos. También renovaremos nuestra experiencia de contribuyente, simplificando el proceso para proponer e implementar nuevas características, y dando reconocimiento a nuestros contribuyentes más valiosos. Planeamos hacer crecer nuestro ecosistema agregando o actualizando la integración de Istio con varios proyectos populares nativos de la nube y construir más casos de estudio para Istio.

## Mirando atrás

Desde 2023, el proyecto Istio se ha enfocado en madurez e innovación, solidificando nuestra posición como el mejor service mesh independientemente de sidecars o ambient. Estos esfuerzos incluyeron nuestra graduación de la CNCF en julio de 2023, la promoción de Telemetry API y Gateway API a Stable en Istio 1.22, y la promoción del modo ambient a Stable en Istio 1.24. Como parte de que el modo ambient de Istio alcanzara GA, hemos observado más y más usuarios explorándolo y adoptándolo, algunos de los usuarios son usuarios completamente nuevos de Istio, mientras que otros son usuarios de sidecars de Istio. Algunos de ellos ejecutaron ambient en producción y hablaron sobre sus experiencias en KubeCon EU en abril de este año. Estos esfuerzos han hecho de Istio el service mesh de elección para desarrolladores nativos de la nube alrededor del mundo, y hemos estado emocionados de aceptar primeras contribuciones de código de 154 personas en los últimos 12 meses.

## Temas de 2025

### Migración de sidecar a ambient

Con la promoción del modo ambient a Stable, Istio ahora puede reclamar ser el service mesh más rápido y eficiente, así como el más ampliamente usado, mientras es más fácil de operar que nunca. Con la graduación, hemos visto un aumento sustancial en el interés, y un número correspondiente de solicitudes para una guía de migración integral para usuarios existentes de sidecar. Mientras que nuestros esfuerzos previos para estabilizar el modo ambient han estado dirigidos a nuevos usuarios de Istio, es claro que ha llegado el momento de proporcionar una rampa de acceso para que nuestra base de usuarios existente migre a ambient mesh. Aunque las bases técnicas para esta migración han estado en su lugar durante algún tiempo (y algunos usuarios valientes han migrado por su cuenta), haremos nuevas inversiones en herramientas para evaluar su preparación para migrar, interoperabilidad segura para rollback, y documentación para guiar a los usuarios en cada paso del camino.

Además de pruebas, herramientas y documentación, los usuarios que migran entre planos de datos deberían razonablemente esperar que las características de Istio que conocen y aman continúen funcionando en su nuevo entorno. Por esta razón, estamos invirtiendo en cerrar las brechas de funcionalidad más significativas entre el modo sidecar y ambient, específicamente agregando soporte para gestión de tráfico multiclúster y extensibilidad, sobre lo cual puede leer más abajo.

Como hemos declarado en años anteriores, no tenemos intención de terminar el soporte para el modo sidecar mientras haya usuarios para él. Migrar a ambient mesh es completamente voluntario, y esperamos que muchos usuarios usen sidecars durante años por venir.

### Mesh ambient multiclúster

La gestión de tráfico multiclúster ha sido durante mucho tiempo una de las características empresariales más valoradas de Istio, y estamos trabajando arduamente para llevar este valor a los usuarios del modo ambient en 2025. Con una malla multiclúster, las interrupciones o anomalías de servicio en un clúster pueden causar dinámicamente que las solicitudes fallen a otros clústeres, potencialmente en otras regiones o nubes. Esto da a los usuarios la capacidad de ejecutar servicios de alta disponibilidad en configuración activo-activo, optimizando la utilización de cómputo y los costos de tráfico desde un único plano de control. La malla ambient multiclúster estará disponible como Alpha en Istio 1.27, que planeamos lanzar en agosto.

### El futuro de la extensibilidad

El proyecto Istio ha ofrecido varias APIs para extensibilidad desde su lanzamiento, y ninguna de ellas ha podido madurar a Stable. De las que están en uso hoy, los Filtros de Envoy son una herramienta poderosa para ajustar la configuración interna del proxy y modificar el flujo de tráfico, pero son muy difíciles de usar y representan un riesgo significativo durante las actualizaciones, que pueden cambiar las integraciones de filtros de formas que no siempre se pueden predecir. WebAssembly (Wasm) emergió en 2019 como una herramienta poderosa para modificación Turing-completa del tráfico, pero el soporte de la comunidad para compiladores y bibliotecas Wasm fuera del ecosistema de Istio ha disminuido sustancialmente desde ese momento, haciendo difícil para los usuarios usar Wasm de forma segura con Istio.

Mientras planeamos para 2025 y más allá, es claro que necesitamos un camino hacia un modelo de extensibilidad maduro para usuarios tanto de sidecars como del modo ambient. Planeamos abordar los casos de uso más comunes para extensibilidad, como limitación de tasa local, con APIs de primera clase, reduciendo la frecuencia con la que los usuarios requieren extensibilidad. Sin embargo, reconocemos que las redes son complejas y siempre habrá casos que nuestras APIs no cubren, cuando los usuarios necesitan una opción de "romper el vidrio". La arquitectura del modo ambient proporciona algunas opciones, como aprovechar el patrón waypoint para lograr inserción de servicio, agregando proxies arbitrarios a la cadena de red, que luego pueden realizar modificaciones arbitrarias. Otro desarrollo similar es [el filtro ext-proc de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ext_proc/v3/ext_proc.proto), que envía solicitudes a un servicio arbitrario para modificación antes de reenviarlas a su destino.

Con varias opciones sobre la mesa para extensibilidad, ¿quién decidirá cuál es la mejor? Como siempre, la decisión final recae en ustedes, nuestros usuarios. Por favor compartan sus pensamientos con nosotros sobre el futuro del proyecto en el canal de extensibilidad en [slack.istio.io](https://slack.istio.io/).

## Nueva y mejorada experiencia de contribuyente

La comunidad de Istio está llena de muchos contribuyentes talentosos cuyos esfuerzos diarios hacen posible este proyecto, ¡y la lista de contribuyentes siempre está creciendo! Sin embargo, como todos los proyectos de código abierto, siempre necesitamos nuevos contribuyentes, y reconocemos que enviar su primer PR a Istio es más difícil de lo que debería ser. En 2025, nuestro objetivo es hacer que escribir su primera contribución a Istio sea más fácil que nunca con una integración mejorada con GitHub Codespaces, ¡y triaje regular de buenos primeros issues! Si está interesado en contribuir, siempre podemos usar ayuda en Issues etiquetados como User Experience y Documentation. Si desea involucrarse más, considere unirse a nuestra rotación de gestor de lanzamiento, que le proporcionará dos lanzamientos como sombra antes de asumir las responsabilidades primarias de gestión de lanzamiento. ¡También buscaremos proporcionar mejor reconocimiento a nuestros contribuyentes a través de un programa renovado de líderes de grupos de trabajo, donde los principales contribuyentes pueden ser reconocidos por su experiencia! Con estas iniciativas, creemos que estamos configurando la comunidad de Istio para crecer durante años por venir.

## Conclusión

Esta hoja de ruta describe un futuro cercano emocionante para Istio, enfocándose en un camino de migración sin problemas del modo sidecar al modo ambient, capacidades multiclúster mejoradas y un enfoque refinado de extensibilidad. También estamos comprometidos a fomentar un entorno más acogedor y gratificante para nuestros invaluables contribuyentes. Estas iniciativas solidifican la posición de Istio como el service mesh líder, listo para empoderar a los desarrolladores nativos de la nube con eficiencia, control y una comunidad próspera sin igual.


