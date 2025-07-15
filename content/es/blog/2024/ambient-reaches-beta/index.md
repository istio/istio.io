---
title: "Dile adiós a tus sidecars: el modo ambient de Istio alcanza la Beta en la v1.22"
description: "Las características de capa 4 y capa 7 ya están listas para producción."
publishdate: 2024-05-13
attribution: "Lin Sun (Solo.io), para los Comités Directivo y de Supervisión Técnica de Istio"
keywords: [ambient,sidecars]
---

Hoy, el nuevo y revolucionario modo de {{< gloss >}}data plane{{< /gloss >}} ambient de Istio ha alcanzado la Beta.
El modo ambient está diseñado para operaciones simplificadas, una compatibilidad de aplicaciones más amplia y un costo de infraestructura reducido.
Te ofrece un data plane sin sidecar que se integra en tu infraestructura,
todo ello manteniendo las características principales de Istio de seguridad zero-trust, telemetría y gestión del tráfico.

El modo ambient [se anunció en septiembre de 2022](/blog/2022/introducing-ambient-mesh/).
Desde entonces, nuestra comunidad ha dedicado 20 meses de arduo trabajo y colaboración, con
contribuciones de Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat y muchos otros.
El estado Beta en la 1.22 indica que las características del modo ambient ya están listas para los workloads de producción, con las precauciones adecuadas.
Este es un hito enorme para Istio, que lleva las características de la malla de capa 4 y capa 7 a la
preparación para producción sin sidecars.

## ¿Por qué el modo ambient?

Al escuchar los comentarios de los usuarios de Istio, observamos una creciente demanda de capacidades de malla para las aplicaciones, pero
escuchamos que a muchos de ustedes les resultaba difícil superar la sobrecarga de recursos y la complejidad operativa de los sidecars. Los desafíos que los usuarios de sidecar
compartieron con nosotros incluyen cómo Istio puede romper las aplicaciones después de agregar los sidecars, el gran consumo de CPU y memoria por parte de los
sidecars, y la inconveniencia del requisito de reiniciar los pods de las aplicaciones con cada nueva versión del proxy.

Como comunidad, diseñamos el modo ambient para abordar estos problemas, aliviando las barreras anteriores
de complejidad que enfrentaban los usuarios que buscaban implementar una service mesh. El nuevo conjunto de características
se denominó 'modo ambient' ya que fue diseñado para ser transparente para tu aplicación, asegurando que no se requiriera ninguna configuración adicional
para adoptarlo, y no requería que los usuarios reiniciaran las aplicaciones.

En el modo ambient es trivial agregar o eliminar aplicaciones de la malla. Ahora puedes simplemente [etiquetar un namespace](/es/docs/ambient/usage/add-workloads/), y todas las aplicaciones
en ese namespace se agregan a la malla. Esto asegura inmediatamente todo el tráfico con mTLS, todo sin sidecars o la necesidad de
reiniciar las aplicaciones.

Consulta el [blog Introducing Ambient Mesh](/blog/2022/introducing-ambient-mesh/)
para obtener más información sobre por qué creamos el modo ambient.

## ¿Cómo facilita la adopción el modo ambient?

El modo ambient de Istio introduce proxies de nodo de capa 4 (L4) ligeros y compartidos y proxies opcionales de capa 7 (L7), eliminando la necesidad de
proxies sidecar tradicionales del data plane. La innovación principal detrás del modo ambient es que divide el procesamiento de L4 y L7
en dos capas distintas. Este enfoque por capas te permite adoptar Istio de forma incremental, permitiendo una transición
suave de ninguna malla, a una superposición segura (L4), a un procesamiento completo opcional de L7, por namespace, según sea necesario, en toda
tu flota.

El modo ambient funciona sin necesidad de ninguna modificación en tus implementaciones de Kubernetes existentes. Puedes etiquetar un namespace para
agregar todas sus workloads a la malla, o incluir ciertas implementaciones según sea necesario. Al utilizar el modo ambient, los usuarios
evitan algunos de los elementos previamente restrictivos del modelo de sidecar. Los protocolos de envío primero del servidor ahora
funcionan, la mayoría de los puertos reservados ahora están disponibles y se elimina la capacidad de los contenedores para omitir el sidecar, ya sea
maliciosamente o no.

El proxy de nodo L4 ligero y compartido se llama *[ztunnel](/es/docs/ambient/overview/#ztunnel)* (túnel de zero-trust). Ztunnel reduce drásticamente la sobrecarga de
ejecutar una malla al eliminar la necesidad de aprovisionar en exceso la memoria y la CPU dentro de un cluster para manejar las cargas esperadas. En
algunos casos de uso, los ahorros pueden superar el 90% o más, sin dejar de proporcionar seguridad de zero-trust mediante TLS mutuo con
identidad criptográfica, políticas de autorización L4 simples y telemetría.

Los proxies L7 se llaman *[waypoints](/es/docs/ambient/overview/#waypoint-proxies)*. Los waypoints procesan funciones L7 como el enrutamiento de tráfico, la aplicación de políticas de autorización
enriquecidas y la resiliencia de nivel empresarial. Los waypoints se ejecutan fuera de las implementaciones de tu aplicación y pueden escalar de forma independiente
según tus necesidades, que podrían ser para todo el namespace o para múltiples servicios dentro de un namespace. En comparación con los
sidecars, no necesitas un waypoint por pod de aplicación, y puedes escalar tu waypoint de manera efectiva en función de su alcance,
ahorrando así cantidades significativas de CPU y memoria en la mayoría de los casos.

La separación entre la capa de superposición segura L4 y la capa de procesamiento L7 permite la adopción incremental del data plane
en modo ambient, en contraste con la inyección binaria "todo o nada" anterior de los sidecars. Los usuarios pueden comenzar con la superposición segura L4, que
ofrece la mayoría de las características para las que la gente implementa Istio (mTLS, política de autorización y telemetría).
El manejo complejo de L7, como reintentos, división del tráfico, balanceo de carga y recopilación de observabilidad, se puede habilitar caso por caso.

## ¿Qué está en el alcance de la Beta?

Te recomendamos que explores las siguientes funciones Beta del modo ambient en producción con las precauciones adecuadas, después de validarlas
en entornos de prueba:

- [Instalación de Istio con soporte para el modo ambient](/es/docs/ambient/install/).
- [Agregar tus workloads a la malla](/es/docs/ambient/usage/add-workloads/) para obtener TLS mutuo con identidad criptográfica, [políticas de autorización L4](/es/docs/ambient/usage/l4-policy/) y telemetría.
- [Configuración de waypoints](/es/docs/ambient/usage/waypoint/) para [usar funciones L7](/es/docs/ambient/usage/l7-features/) como el desvío de tráfico, el enrutamiento de solicitudes y la aplicación de políticas de autorización enriquecidas.
- Conexión del ingress gateway de Istio a los workloads en modo ambient, compatible con todas las API de Istio existentes.
- Uso de `istioctl` para operar waypoints y solucionar problemas de ztunnel y waypoints.

### Características Alpha

Muchas otras características que queremos incluir en el modo ambient se han implementado, pero permanecen en estado Alpha en esta versión. Por favor, ayuda
a probarlas, para que puedan ser promovidas a Beta en la 1.23 o posterior:

- Instalaciones multi-cluster
- Proxy de DNS
- Interoperabilidad con sidecars
- IPv6/Dual stack
- Soporte de SOCKS5 (para salida)
- API clásicas de Istio (`VirtualService` y `DestinationRule`)

### Hoja de ruta

Tenemos una serie de características que aún no están implementadas en el modo ambient, pero que están planificadas para las próximas versiones:

- Tráfico de egress controlado
- Soporte multi-red
- Mejorar los mensajes de `status` en los recursos para ayudar a solucionar problemas y comprender la malla
- Soporte de VM

## ¿Y qué hay de los sidecars?

Los sidecars no van a desaparecer y siguen siendo ciudadanos de primera clase en Istio. Puedes seguir usando sidecars, y seguirán siendo
totalmente compatibles. Para cualquier característica fuera del alcance de Alpha o Beta para el modo ambient, debes considerar usar el modo
sidecar hasta que la característica se agregue al modo ambient. Algunos casos de uso, como el desvío de tráfico basado en etiquetas de origen, seguirán
siendo mejor implementados usando el modo sidecar. Si bien creemos que la mayoría de los casos de uso se atenderán mejor con una malla en
modo ambient, el proyecto Istio sigue comprometido con el soporte continuo del modo sidecar.

## Prueba el modo ambient hoy

Con la versión 1.22 de Istio y la versión Beta del modo ambient, ahora es más fácil que nunca probar Istio en tus propias
workloads. Sigue la [guía de inicio](/es/docs/ambient/getting-started/) para explorar el modo ambient, o lee nuestras nuevas [guías de usuario](/es/docs/ambient/usage/)
para aprender a adoptar gradualmente el modo ambient para TLS mutuo y política de autorización L4, gestión del tráfico, política de autorización
L7 enriquecida y más. Puedes interactuar con los desarrolladores en el canal #ambient en [el Slack de Istio](https://slack.istio.io),
o usar el foro de discusión en [GitHub](https://github.com/istio/istio/discussions) para cualquier pregunta que puedas tener.
