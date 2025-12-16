---
title: "Istio en KubeCon Europe 2023"
description: Un rápido resumen de Istio en KubeCon Europe, en el RAI de Ámsterdam.
publishdate: 2023-04-27
attribution: "Faseela K, para el Comité del Programa de Istio Day"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

La comunidad de código abierto y nativa de la nube se reunió del 18 al 21 de abril en Ámsterdam para la primera KubeCon de 2023. La conferencia de cuatro días, organizada por la Cloud Native Computing Foundation, fue especial para Istio, ya que evolucionamos de ser participantes en ServiceMeshCon a organizar nuestro primer evento oficial co-ubicado con el proyecto.

{{< image width="40%"
    link="./istio-day-welcome.jpg"
    caption="Istio Day Europe 2023, Bienvenida"
    >}}

Istio Day comenzó con una keynote de apertura de los presidentes del Comité del Programa, Mitch Connors y Faseela K. El evento estuvo repleto de gran contenido, desde nuevas características hasta charlas de usuarios finales, y el salón siempre estuvo abarrotado. La [keynote de apertura](https://youtu.be/h9EgMrJ0ahs) fue un rompehielos con algo de diversión de Istio en forma de un cuestionario interactivo, y reconocimiento a los esfuerzos diarios de nuestros contribuyentes, mantenedores, gestores de lanzamiento y usuarios.

{{< image width="75%"
    link="./opening-keynote.jpg"
    caption="Istio Day Europe 2023, Keynote de Apertura"
    >}}

Esto fue seguido por una sesión de [actualización de la hoja de ruta de 2023](https://youtu.be/GQccKyVe0R8) de los miembros del TOC Lin Sun y Louis Ryan. Tuvimos nuestra muy esperada sesión sobre [la postura de seguridad de Ambient Mesh](https://youtu.be/QnfrbbY_Hy4), de Christian Posta y John Howard, que generó algunas discusiones interesantes en la comunidad. Después de esto pasamos a nuestra primera [charla de usuario final de John Keates de Wehkamp](https://youtu.be/Gb_I2RJr8kQ), una empresa holandesa local, seguida por ponentes de Bloomberg, Alexa Griffith y Zhenni Fu, sobre [cómo aseguran su información financiera altamente privilegiada](https://youtu.be/f6jMix46ZD8) usando Istio. Istio Day fue testigo de más enfoque en seguridad, que se hizo aún más prominente cuando Zack Butcher habló sobre [usar Istio para cumplimiento de controles](https://youtu.be/gIntE4Nn5r4). También tuvimos charlas relámpago cubriendo [entornos de desarrollo de Istio más rápidos](https://youtu.be/Onsukvmmm50), [guía para aislamiento de recursos de Istio](https://youtu.be/TmlfQjChmNU) y [asegurando despliegues en nube híbrida](https://youtu.be/xejbMNbOwXk) de Mitch Connors, Zhonghu Xu y Matt Turner respectivamente.

{{< image width="75%"
    link="./istioday-hall.jpg"
    caption="Istio Day Europe 2023, Sesiones abarrotadas"
    >}}

Varios de nuestros miembros del ecosistema tuvieron anuncios relacionados con Istio en el evento. Microsoft anunció [Istio como add-on gestionado para Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/istio-about), y el soporte para Istio ahora está disponible de forma general en [D2iQ Kubernetes Platform](https://www.prnewswire.com/news-releases/d2iq-takes-multi-cloud-multi-cluster-fleet-management-to-the-next-level-with-kubernetes-platform-enhancements-301799358.html).

Tetrate anunció [Tetrate Service Express](https://tetrate.io/blog/introducing-tetrate-service-express/), una solución de automatización de conectividad, seguridad y resiliencia de servicios basada en Istio para Amazon EKS, y Solo.io anunció [Gloo Fabric](https://www.solo.io/blog/introducing-solo-gloo-fabric/), con capacidades de redes de aplicaciones basadas en Istio expandidas a aplicaciones basadas en VM, contenedores y serverless en entornos de nube.

La presencia de Istio en la conferencia no terminó con Istio Day. La keynote del segundo día comenzó con un [video de actualización del proyecto](https://twitter.com/linsun_unc/status/1648952723604221953) de Lin Sun. También fue un momento de orgullo para nosotros, cuando nuestro miembro del comité directivo Craig Box fue [reconocido como mentor de la CNCF](https://twitter.com/IstioMesh/status/1648722572366708739) en la keynote. La charla de la pista de mantenedores para Istio presentada por el miembro del TOC Neeraj Poddar captó gran atención mientras hablaba sobre los esfuerzos actuales en curso y la hoja de ruta futura de Istio. La charla, y el tamaño de la audiencia, subrayaron por qué Istio continúa siendo el service mesh más popular en la industria.

{{< image width="75%"
    link="./use-istio-in-production.jpg"
    caption="KubeCon Europe 2023, Pregunta: ¿Cuántos de ustedes usan Istio en producción?"
    >}}

Las siguientes sesiones en KubeCon se basaron en Istio y casi todas tuvieron una gran multitud asistiendo:
* [Future of Istio - Sidecar, Sidecarless or Both?](https://sched.co/1HySB)
* [Operate Multi Tenancy Istio with ArgoCD in production](https://sched.co/1Hyd1)
* [Create Istio Filters with Any Programming Language](https://sched.co/1HybK)
* [Automated Cloud-Native Incident Response with Kubernetes and Service Mesh](https://sched.co/1HyZ9)
* [Autoscaling Elastic Kubernetes Infrastructure for Stateful Applications Using Proxyless gRPC and Istio](https://sched.co/1HyXz)
* [Developing a Mental Model of Istio: From Kubernetes to Sidecars to Ambient](https://sched.co/1HyZj)
* [Future of ServiceMesh - Sidecar, Sidecarless or Proxyless? - Panel Discussion](https://sched.co/1Hydb)
* [The Top 10 List of Istio Security Risks and Mitigation Strategies](https://sched.co/1HyPQ)

Istio tuvo un kiosco a tiempo completo en el pabellón de proyectos de KubeCon, con la mayoría de las preguntas siendo sobre el estado de nuestra graduación de la CNCF. ¡Estamos muy emocionados de saber que nuestros usuarios están esperando ansiosamente noticias de nuestra graduación, y prometemos que estamos trabajando activamente hacia ella!

{{< image width="75%"
    link="./istio-booth.jpg"
    caption="KubeCon Europe 2023, Kiosco de Istio"
    >}}

Muchos de nuestros miembros del TOC y mantenedores también ofrecieron apoyo en el kiosco, donde ocurrieron muchas discusiones interesantes alrededor de Istio Ambient Mesh también.

{{< image width="75%"
    link="./toc-members-at-kiosk.jpg"
    caption="KubeCon Europe, Más apoyo en el Kiosco de Istio"
    >}}

Otro punto destacado fue que los miembros del TOC y directivos de Istio y autores Lin Sun y Christian Posta firmaron copias del libro "Istio Ambient Explained".

{{< image width="75%"
    link="./ambient-mesh-book-authors.jpg"
    caption="KubeCon Europe 2023, Firma de libros de Ambient Mesh por los autores"
    >}}

Por último, pero no menos importante, nos gustaría expresar nuestro sincero agradecimiento a nuestro patrocinador platino [Tetrate](http://tetrate.io/), ¡por apoyar a Istio Day!

2023 va a ser realmente grande para Istio, con más eventos planeados para los próximos meses. ¡Manténganse atentos para actualizaciones sobre IstioCon 2023 y la presencia de Istio en KubeCon en China y Norteamérica!
