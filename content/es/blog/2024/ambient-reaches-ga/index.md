---
title: "Rápido, seguro y simple: el modo ambient de Istio alcanza la disponibilidad general en la v1.24"
description: "Nuestra última versión indica que el modo ambient, la service mesh sin sidecars, está lista para todos."
publishdate: 2024-11-07
attribution: "Lin Sun (Solo.io), para los Comités Directivo y de Supervisión Técnica de Istio"
keywords: [ambient,sidecars]
---

Estamos orgullosos de anunciar que el modo de data plane ambient de Istio ha alcanzado la Disponibilidad General (GA), con el ztunnel, los waypoints y las API marcados como Estables por el TOC de Istio. Esto marca la etapa final en la [progresión de fases de características](/es/docs/releases/feature-stages/) de Istio, lo que indica que el modo ambient está totalmente listo para un amplio uso en producción.

Ambient mesh — y su implementación de referencia con el modo ambient de Istio — [se anunció en septiembre de 2022](/blog/2022/introducing-ambient-mesh/). Desde entonces, nuestra comunidad ha dedicado 26 meses de arduo trabajo y colaboración, con contribuciones de Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat y muchos otros. El estado Estable en la 1.24 indica que las características del modo ambient ya están totalmente listas para workloads de producción amplias. Este es un hito enorme para Istio, que lleva a Istio a la preparación para producción sin sidecars y [ofrece a los usuarios una opción](/es/docs/overview/data plane-modes/).

## ¿Por qué ambient mesh?

Desde el lanzamiento de Istio en 2017, hemos observado una demanda clara y creciente de capacidades de malla para aplicaciones, pero escuchamos que a muchos usuarios les resultaba difícil superar la sobrecarga de recursos y la complejidad operativa de los sidecars. Los desafíos que los usuarios de Istio compartieron con nosotros incluyen cómo los sidecars pueden romper las aplicaciones después de que se agregan, el gran requisito de CPU y memoria para un proxy con cada workload, y la inconveniencia de necesitar reiniciar los pods de la aplicación con cada nueva versión de Istio.

Como comunidad, diseñamos ambient mesh desde cero para abordar estos problemas, aliviando las barreras anteriores de complejidad que enfrentaban los usuarios que buscaban implementar una service mesh. El nuevo concepto se denominó 'ambient mesh' ya que fue diseñado para ser transparente para tu aplicación, sin infraestructura de proxy ubicada junto con los workloads del usuario, sin cambios sutiles en la configuración necesarios para la incorporación y sin necesidad de reiniciar la aplicación.
En el modo ambient es trivial agregar o eliminar aplicaciones de la malla. Todo lo que necesitas hacer es [etiquetar un namespace](/es/docs/ambient/usage/add-workloads/), y todas las aplicaciones en ese namespace se agregan instantáneamente a la malla. Esto asegura inmediatamente todo el tráfico dentro de ese namespace con cifrado TLS mutuo estándar de la industria, ¡sin necesidad de otra configuración o reinicios!
Consulta el [blog Introducing Ambient Mesh](/blog/2022/introducing-ambient-mesh/) para obtener más información sobre por qué creamos el modo ambient de Istio.

## ¿Cómo facilita la adopción el modo ambient?

La innovación principal detrás de ambient mesh es que divide el procesamiento de capa 4 (L4) y capa 7 (L7) en dos capas distintas. El modo ambient de Istio está impulsado por proxies de nodo L4 ligeros y compartidos y proxies L7 opcionales, lo que elimina la necesidad de proxies sidecar tradicionales del data plane. Este enfoque por capas te permite adoptar Istio de forma incremental, lo que permite una transición suave de ninguna malla, a una superposición segura (L4), a un procesamiento L7 completo opcional, por namespace, según sea necesario, en toda tu flota.

Al utilizar ambient mesh, los usuarios evitan algunos de los elementos previamente restrictivos del modelo de sidecar. Los protocolos de envío primero del servidor ahora funcionan, la mayoría de los puertos reservados ahora están disponibles y se elimina la capacidad de los contenedores para omitir el sidecar, ya sea maliciosamente o no.

El proxy de nodo L4 ligero y compartido se llama *[ztunnel](/es/docs/ambient/overview/#ztunnel)* (túnel de zero-trust). ztunnel reduce drásticamente la sobrecarga de ejecutar una malla al eliminar la necesidad de aprovisionar en exceso la memoria y la CPU dentro de un cluster para manejar las cargas esperadas. En algunos casos de uso, los ahorros pueden superar el 90% o más, sin dejar de proporcionar seguridad de zero-trust mediante TLS mutuo con identidad criptográfica, políticas de autorización L4 simples y telemetría.

Los proxies L7 se llaman *[waypoints](/es/docs/ambient/overview/#waypoint-proxies)*. Los waypoints procesan funciones L7 como el enrutamiento de tráfico, la aplicación de políticas de autorización enriquecidas y la resiliencia de nivel empresarial. Los waypoints se ejecutan fuera de las implementaciones de tu aplicación y pueden escalar de forma independiente según tus necesidades, que podrían ser para todo el namespace o para múltiples servicios dentro de un namespace. En comparación con los sidecars, no necesitas un waypoint por pod de aplicación, y puedes escalar tu waypoint de manera efectiva en función de su alcance, ahorrando así cantidades significativas de CPU y memoria en la mayoría de los casos.

La separación entre la capa de superposición segura L4 y la capa de procesamiento L7 permite la adopción incremental del data plane en modo ambient, en contraste con la inyección binaria "todo o nada" anterior de los sidecars. Los usuarios pueden comenzar con la superposición segura L4, que ofrece la mayoría de las características para las que la gente implementa Istio (mTLS, política de autorización y telemetría). El manejo complejo de L7, como reintentos, división del tráfico, balanceo de carga y recopilación de observabilidad, se puede habilitar caso por caso.

## Rápida exploración y adopción del modo ambient

La imagen de ztunnel en Docker Hub ha alcanzado más de [1 millón de descargas](https://hub.docker.com/search?q=istio), con ~63,000 extracciones solo en la última semana.

{{< image width="100%"
    link="./ztunnel-image.png"
    alt="¡Descargas de la imagen ztunnel de Istio en Docker Hub!"
    >}}

Les pedimos a algunos de nuestros usuarios su opinión sobre la GA del modo ambient:

{{< quote >}}
**La implementación de Istio de una service mesh con su diseño de ambient mesh ha sido una gran adición a nuestros clusteres de Kubernetes para simplificar las responsabilidades del equipo y la arquitectura de red general de la malla. Junto con el proyecto Gateway API, me ha dado una excelente manera de permitir que los desarrolladores satisfagan sus necesidades de red al mismo tiempo que solo delegan el control necesario. Si bien es un proyecto en rápida evolución, ha sido sólido y confiable en producción y será nuestra opción predeterminada para implementar controles de red en una implementación de Kubernetes en el futuro.**

— [Daniel Loader](https://uk.linkedin.com/in/danielloader), Ingeniero de Plataforma Principal en Quotech

{{< /quote >}}

{{< quote >}}
**Es increíblemente fácil instalar ambient mesh con el contenedor del chart de Helm. Migrar es tan simple como configurar un waypoint gateway, actualizar las etiquetas en un namespace y reiniciar. Estoy deseando deshacerme de los sidecars y recuperar recursos. Además, actualizaciones más fáciles. ¡No más reinicios de implementaciones!**

— [Raymond Wong](https://www.linkedin.com/in/raymond-wong-43baa8a2/), Arquitecto Senior en Forbes
{{< /quote >}}

{{< quote >}}
**El modo ambient de Istio ha servido a nuestro sistema de producción desde que se convirtió en Beta. Estamos satisfechos con su estabilidad y simplicidad y esperamos beneficios y características adicionales que vienen junto con el estado de GA. ¡Gracias al equipo de Istio por los grandes esfuerzos!**

— Saarko Eilers, Gerente de Operaciones de Infraestructura en EISST International Ltd
{{< /quote >}}

{{< quote >}}
**Al cambiar de AWS App Mesh a Istio en modo ambient, pudimos reducir aproximadamente el 45% de los contenedores en ejecución simplemente eliminando los sidecars y los DaemonSets del agente SPIRE. Obtuvimos muchos beneficios, como la reducción de los costos de cómputo o los costos de observabilidad relacionados con los sidecars, la eliminación de muchas de las condiciones de carrera relacionadas con el inicio y el apagado de los sidecars, además de todos los beneficios listos para usar simplemente con la migración, como mTLS, conciencia zonal y balanceo de workload.**

— [Ahmad Al-Masry](https://www.linkedin.com/in/ahmad-al-masry-9ab90858/), Gerente de Ingeniería de DevSecOps en Harri
{{< /quote >}}

{{< quote >}}
**Elegimos Istio porque estamos entusiasmados con ambient mesh. A diferencia de otras opciones, con Istio, la transición de sidecar a sin sidecar no es un salto de fe. Podemos construir nuestra infraestructura de service mesh con Istio sabiendo que el camino hacia sin sidecar es una puerta de dos vías.**

— [Troy Dai](https://www.linkedin.com/in/troydai/), Ingeniero de Software Senior en Coinbase
{{< /quote >}}

{{< quote >}}
**¡Extremadamente orgulloso de ver el crecimiento rápido y constante del modo ambient hasta GA, y toda la increíble colaboración que tuvo lugar en los últimos meses para que esto sucediera! Esperamos descubrir cómo la nueva arquitectura revolucionará el mundo de las telecomunicaciones.**

— [Faseela K](https://www.linkedin.com/in/faseela-k-42178528/), Desarrolladora Nativa de la Nube en Ericsson
{{< /quote >}}

{{< quote >}}
**Estamos entusiasmados de ver evolucionar el data plane de Istio con el lanzamiento de GA del modo ambient y lo estamos evaluando activamente para nuestra plataforma de infraestructura de próxima generación. La comunidad de Istio es dinámica y acogedora, y ambient mesh es un testimonio de que la comunidad adopta nuevas ideas y trabaja pragmáticamente para mejorar la experiencia del desarrollador que opera Istio a escala.**

— [Tyler Schade](https://www.linkedin.com/in/tylerschade/), Ingeniero Distinguido en GEICO Tech
{{< /quote >}}

{{< quote >}}
**Con el modo ambient de Istio alcanzando la GA, finalmente tenemos una solución de service mesh que no está ligada al ciclo de vida del pod, abordando una limitación importante de los modelos basados en sidecar. Ambient mesh proporciona una arquitectura más ligera y escalable que simplifica las operaciones y reduce nuestros costos de infraestructura al eliminar la sobrecarga de recursos de los sidecars.**

— [Bartosz Sobieraj](https://www.linkedin.com/in/bartoszsobieraj/), Ingeniero de Plataforma en Spond
{{< /quote >}}

{{< quote >}}
**Nuestro equipo eligió Istio por sus características de service mesh y su fuerte alineación con la Gateway API para crear una solución de alojamiento robusta basada en Kubernetes. A medida que integramos aplicaciones en la malla, enfrentamos desafíos de recursos con los proxies sidecar, lo que nos llevó a hacer la transición al modo ambient en Beta para mejorar la escalabilidad y la seguridad. Comenzamos con la seguridad y observabilidad de L4 a través de ztunnel, obteniendo cifrado automático del tráfico dentro del cluster y monitoreo transparente del flujo de tráfico. Al habilitar selectivamente las características de L7 y desacoplar el proxy de las aplicaciones, logramos una escalabilidad perfecta y una utilización y latencia de recursos reducidas. Este enfoque permitió a los desarrolladores centrarse en el desarrollo de aplicaciones, lo que resultó en una plataforma más resistente, segura y escalable impulsada por el modo ambient.**

— [Jose Marques](https://www.linkedin.com/in/jdcmarques/), DevOps Senior en Blip.pt
{{< /quote >}}

{{< quote >}}
**Estamos usando Istio para garantizar un tráfico mTLS L4 estricto en nuestra malla y estamos entusiasmados con el modo ambient. En comparación con el modo sidecar, es un ahorro masivo de recursos y, al mismo tiempo, hace que la configuración de las cosas sea aún más simple y transparente.**

— [Andrea Dolfi](https://www.linkedin.com/in/andrea-dolfi-58b427128/), Ingeniero de DevOps
{{< /quote >}}

## ¿Qué está dentro del alcance?

La disponibilidad general del modo ambient significa que las siguientes cosas ahora se consideran estables:

- [Instalación de Istio con soporte para el modo ambient](/es/docs/ambient/install/), con Helm o `istioctl`.
- [Agregar tus workloads a la malla](/es/docs/ambient/usage/add-workloads/) para obtener TLS mutuo con identidad criptográfica, [políticas de autorización L4](/es/docs/ambient/usage/l4-policy/) y telemetría.
- [Configuración de waypoints](/es/docs/ambient/usage/waypoint/) para [usar funciones L7](/es/docs/ambient/usage/l7-features/) como el desvío de tráfico, el enrutamiento de solicitudes y la aplicación de políticas de autorización enriquecidas.
- Conexión del ingress gateway de Istio a los workloads en modo ambient, compatible con las API de Kubernetes Gateway y todas las API de Istio existentes.
- Uso de waypoints para el egress controlado de la malla
- Uso de `istioctl` para operar waypoints y solucionar problemas de ztunnel y waypoints.

Consulta la [página de estado de las características](/es/docs/releases/feature-stages/#ambient-mode) para obtener más información.

### Hoja de ruta

¡No nos quedamos quietos! Hay una serie de características en las que seguimos trabajando para futuras versiones, incluidas algunas que se encuentran actualmente en Alpha/Beta.

En nuestras próximas versiones, esperamos avanzar rápidamente en las siguientes extensiones al modo ambient:

- Soporte completo para la interoperabilidad del modo sidecar y ambient
- Instalaciones multi-cluster
- Soporte multi-red
- Soporte de VM

## ¿Y qué hay de los sidecars?

Los sidecars no van a desaparecer y siguen siendo ciudadanos de primera clase en Istio. Puedes seguir usando sidecars, y seguirán siendo totalmente compatibles. Si bien creemos que la mayoría de los casos de uso se atenderán mejor con una malla en modo ambient, el proyecto Istio sigue comprometido con el soporte continuo del modo sidecar.

## Prueba el modo ambient hoy

Con la versión 1.24 de Istio y el lanzamiento de GA del modo ambient, ahora es más fácil que nunca probar Istio en tus propias workloads.

- Sigue la [guía de inicio](/es/docs/ambient/getting-started/) para explorar el modo ambient.
- Lee nuestras [guías de usuario](/es/docs/ambient/usage/) para aprender a adoptar gradualmente el modo ambient para TLS mutuo y política de autorización L4, gestión del tráfico, política de autorización L7 enriquecida y más.
- Explora el [nuevo panel de Kiali 2.0](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e) para visualizar tu malla.

Puedes interactuar con los desarrolladores en el canal #ambient en [el Slack de Istio](https://slack.istio.io), o usar el foro de discusión en [GitHub](https://github.com/istio/istio/discussions) para cualquier pregunta que puedas tener.
