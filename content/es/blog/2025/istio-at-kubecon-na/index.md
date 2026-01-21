---

title: "Istio en KubeCon + CloudNativeCon North America 2025: Una semana de momentum, comunidad e hitos"
description: "Aspectos destacados de Istio Day y KubeCon North America 2025 en Atlanta."
publishdate: 2025-11-25
attribution: "Faseela K, para el Comité Directivo de Istio"
keywords: ["Istio", "KubeCon", "service mesh", "Ambient Mesh", "Gateway API"]

---

{{< image width="75%" link="./kubecon-opening.jpg" caption="Istio en KubeCon NA 2025" >}}

KubeCon + CloudNativeCon North America 2025 iluminó Atlanta del **10 al 13 de noviembre**, reuniendo una de las mayores congregaciones de practicantes de código abierto, ingenieros de plataforma y mantenedores de todo el ecosistema nativo de la nube. Para la comunidad de Istio, la semana se caracterizó por salas llenas, largas conversaciones en pasillos y un genuino sentido de progreso compartido a través de service mesh, Gateway API, seguridad y plataformas impulsadas por IA.

Antes de que comenzara la conferencia principal, la comunidad inició las cosas con **Istio Day el 10 de noviembre**, un evento colocado lleno de sesiones técnicas profundas, historias de migración y discusiones mirando hacia el futuro que establecieron el tono para el resto de la semana.

## Istio Day en KubeCon NA

Istio Day reunió a profesionales, contribuyentes y usuarios para una tarde de aprendizaje, compartir y conversaciones abiertas sobre hacia dónde se dirige el service mesh—y Istio—a continuación.

{{< image width="75%" link="./istioday-opening.jpg" caption="IstioDay: North America" >}}

Istio Day abrió con [Bienvenida + Comentarios de Apertura](https://www.youtube.com/watch?v=f5BxnlFgToQ) de John Howard de Solo.io y Keith Mattix de Microsoft, estableciendo el tono para una tarde enfocada en la evolución real de la mesh y la creciente energía en toda la comunidad de Istio.

El día rápidamente se movió a IA aplicada con [¿Está su Service Mesh listo para IA?](https://www.youtube.com/watch?v=4ynwGx1QH5I), donde John Howard exploró cómo la gestión de tráfico, seguridad y observabilidad dan forma a las cargas de trabajo de IA de grado de producción.

{{< image width="75%" link="./istioday-talk.jpg" caption="IstioDay: ¿Está su Service Mesh listo para IA?" >}}

El momentum continuó con [Istio Ambient Goes Multicluster](https://www.youtube.com/watch?v=7dT2O8Bnvyo) cuando Jackie Maertens y Steven Jin Xuan de Microsoft demostraron cómo Ambient Mesh se comporta a través de clústeres distribuidos—destacando identidad, conectividad y simplificaciones operacionales en despliegues multiclúster.

Una explosión de energía vino con la charla relámpago [¿Validando sus configuraciones de Istio? Las pruebas ya están escritas](https://www.youtube.com/watch?v=ViUMfYzc8o0), donde Francisco Herrera Lira de Red Hat mostró cómo las herramientas de validación integradas pueden detectar problemas comunes de configuración antes de que lleguen a producción.

En [Optimizando el autoescalado de Istio: De centrado en recursos a consciente de conexiones](https://www.youtube.com/watch?v=wHvS_h7FBv4), Punakshi Chaand y Pankaj Sikka compartieron cómo Intuit mejoró la confiabilidad al ajustar los comportamientos de autoescalado basados en patrones de conexión en lugar de métricas de recursos crudas.

A continuación, [Ejecutando bases de datos en el Service Mesh de Istio](https://www.youtube.com/watch?v=3Jy9VKWgHww) con Tyler Schade y Michael Bolot de GEICO Tech desafió suposiciones largamente sostenidas, ofreciendo lecciones prácticas sobre asegurar y operar cargas de trabajo con estado dentro de una malla.

Modernizar los puntos de entrada de tráfico tomó el escenario cuando Lin Sun de Solo.io y Ahmad Al-Masry de Harri recorrieron [¿Es posible la migración sin tiempo de inactividad? Moviéndose de Ingress y Sidecars a Gateway API](https://www.youtube.com/watch?v=J0SEOc6M35E), enfocándose en estrategias de migración progresiva que evitan interrupciones durante cambios arquitectónicos.

La sesión final, [Migración de Istio de Credit Karma: 50k+ Pods, impacto mínimo, lecciones aprendidas](https://www.youtube.com/watch?v=OjT4NmO5MvM), vio a Sumit Vij y Mark Gergely delinear cómo ejecutaron una de las migraciones de Istio más grandes hasta la fecha con cuidadosa automatización y disciplina de despliegue.

El día cerró con [comentarios de John Howard y Keith Mattix](https://www.youtube.com/watch?v=KU30VVnoAf0), celebrando a los oradores, contribuyentes y una comunidad que continúa empujando los límites de lo que Istio hace posible.

## Istio en la conferencia principal de KubeCon

Fuera de Istio Day, el proyecto fue altamente visible a través de KubeCon, con mantenedores, usuarios finales y contribuyentes compartiendo profundizaciones técnicas, historias de producción e investigación de vanguardia.

Esta KubeCon fue especialmente significativa para la comunidad de Istio porque Istio apareció no solo a través de stands de expo y sesiones paralelas, sino también a lo largo de varios de los keynotes de KubeCon, donde las empresas mostraron cómo Istio juega un papel crítico en impulsar sus plataformas a escala.

{{< image width="75%" link="./istio-at-keynotes.png" caption="Istio en los Keynotes de KubeCon" >}}

El momentum de la semana alcanzó completamente su ritmo cuando la comunidad de Istio se reunió nuevamente con la [Actualización del Proyecto Istio](https://www.youtube.com/watch?v=vdCMLZ-4vUo), donde los líderes del proyecto compartieron los últimos lanzamientos, avances en la hoja de ruta y cómo Istio está cumpliendo las demandas emergentes de cargas de trabajo de IA, malla multiclúster y escala operacional.

En [Istio: Set Sailing With Istio Without Sidecars](https://www.youtube.com/watch?v=SwB7W8g9r6I), los asistentes exploraron cómo la arquitectura Ambient Mesh sin sidecars está pasando rápidamente de experimento a adopción, abriendo nuevas posibilidades para despliegues más simples y planos de datos más livianos.

La sesión [Lecciones aplicadas construyendo un proxy de IA de próxima generación](https://www.youtube.com/watch?v=qa5vSE86z-s&pp=0gcJCRUKAYcqIYzv) llevó a la multitud detrás de escena de cómo las tecnologías de malla se adaptan a patrones de tráfico impulsados por IA—aplicando la malla no solo a servicios, sino al servicio de modelos, inferencia y flujo de datos.

En **Dimensionamiento automático correcto para cargas de trabajo DaemonSet de Istio (Sesión de póster)**, los practicantes se reunieron para comparar estrategias para optimizar recursos del control plane, ajustando para alta escala y reduciendo costos sin sacrificar el rendimiento.

La narrativa de la evolución de la gestión de tráfico apareció prominentemente en [Gateway API: Table Stakes](https://www.youtube.com/watch?v=RWFDjA6ZeWc) y su hermano más rápido [¡Conozca antes de ir! Introducción acelerada a Gateway API](https://www.youtube.com/watch?v=Cd0hGGydUGo). Estas sesiones trajeron caminos fundamentales e introductorios al ingress y control de malla modernos.

Mientras tanto, [Return of the Mesh: Gateway API's Epic Quest for Unity](https://www.youtube.com/watch?v=tgs6Wq5UlBs) escaló esa conversación: cómo el tráfico, API, malla y enrutamiento convergen en una arquitectura que simplifica la complejidad en lugar de multiplicarla.

Para reflexión a largo plazo, [5 lecciones clave de 8 años construyendo Kgateway](https://www.youtube.com/watch?v=G3Iu2ezSkVE) entregó sabiduría duramente ganada de años de diseño de sistemas, refactorización y mejoras iterativas.

En [GAMMA en acción: Cómo Careem migró a Istio sin tiempo de inactividad](https://www.youtube.com/watch?v=igJXmbwMYAc&pp=0gcJCRUKAYcqIYzv), la historia de migración del mundo real—un importante despliegue de producción que se mantuvo activo durante la transición—proporcionó una hoja de ruta para equipos que buscan adopción segura de malla a escala.

La seguridad y los riesgos de despliegue tomaron el escenario central en [Domando riesgos de despliegue en aplicaciones web distribuidas: Un enfoque de despliegue gradual consciente de ubicación](https://www.youtube.com/watch?v=-fhXEJD-ycs), donde se expusieron estrategias para despliegues regionales, dirección de tráfico y minimización del impacto del usuario.

Finalmente, las operaciones y la realidad del día dos se abordaron en [Seguridad de extremo a extremo con gRPC en Kubernetes](https://www.youtube.com/watch?v=fhjiLyntYBg) y [De guardia de la manera fácil con agentes](https://www.youtube.com/watch?v=oDli4CBkky8), recordando a todos que la malla no es solo sobre arquitectura, sino sobre cómo los equipos ejecutan software de forma segura, confiable y con confianza.

## Espacios comunitarios: ContribFest, Maintainer Track y el Pabellón de Proyectos

En el Pabellón de Proyectos, el kiosco de Istio estaba constantemente zumbando, atrayendo usuarios con preguntas sobre Ambient Mesh, cargas de trabajo de IA y mejores prácticas de despliegue.

{{< image width="75%" link="./istio-kiosk.png" caption="Pabellón de Proyectos de Istio" >}}

El Maintainer Track reunió a los contribuyentes para colaborar en temas de la hoja de ruta, clasificar issues y discutir áreas clave de inversión para el próximo año.

{{< image width="75%" link="./istio-contributors.jpg" caption="Mantenedores de Istio" >}}

En el ContribFest, nuevos contribuyentes se unieron a los mantenedores para trabajar a través de buenos primeros issues, discutir caminos de contribución y preparar sus primeros PRs.

{{< image width="75%" link="./istio-contribfest.png" caption="Colaboración del ContribFest de Istio" >}}

## Mantenedores de Istio reconocidos en los Premios Comunitarios de la CNCF

Los [Premios Comunitarios de la CNCF](https://www.cncf.io/announcements/2025/11/12/cncf-honors-innovators-and-defenders-with-2025-community-awards-at-kubecon-cloudnativecon-north-america/) de este año fueron un momento de orgullo para el proyecto. Dos mantenedores de Istio recibieron reconocimiento bien merecido:

* John Howard — Premio Top Committer
* Daniel Hawton — Premio "Chop Wood, Carry Water"

{{< image width="75%" link="./cncf-awards.png" caption="Istio en los Premios Comunitarios de la CNCF" >}}

Más allá de estos premios, Istio también estuvo representado prominentemente en el liderazgo de la conferencia. Faseela K, una de las copresidentas de KubeCon NA y mantenedora de Istio, participó en un panel keynote sobre [Cloud Native para el Bien](https://youtu.be/1iFYEWx2zC8?si=JUa-8fwtYe5IefE7).

Durante los comentarios de cierre, también se anunció que Lin Sun, otra mantenedora de Istio de larga data, servirá como copresidenta de KubeCon próximamente, destacando la fuerte presencia de liderazgo del proyecto dentro de la CNCF.

{{< image width="75%" link="./kubecon-co-chairs.jpg" caption="Liderazgo de Istio en el escenario del Keynote" >}}

## Lo que escuchamos en Atlanta

A través de sesiones, kioscos y pasillos, surgieron algunos temas:

* Ambient Mesh está pasando de la exploración a la adopción en el mundo real.
* Las cargas de trabajo de IA están impulsando la innovación en patrones de tráfico de malla y prácticas operacionales.
* Los despliegues multiclúster se están volviendo comunes, con atención a la identidad, control y failover.
* Gateway API se está solidificando como una herramienta central para la gestión de tráfico moderna.
* Nuevos contribuyentes se están uniendo en números significativos, apoyados por ContribFest, orientación práctica y compromiso de la comunidad.

## Mirando hacia adelante

KubeCon NA 2025 mostró una comunidad que es vibrante, creciente y abordando algunos de los desafíos más difíciles en la infraestructura moderna de la nube—desde la gestión de tráfico de IA hasta migraciones sin tiempo de inactividad, desde escalar planos de control a escala planetaria hasta construir la próxima generación de malla sin sidecars.

A medida que miramos hacia 2026, la energía de Atlanta nos da confianza: el futuro del service mesh es brillante, y la comunidad de Istio está liderando el camino, juntos.

{{< image width="75%" link="./kubecon-eu-2026.png" caption="Nos vemos en Ámsterdam" >}}


