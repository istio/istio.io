---
title: "Resumen de IstioCon China 2023"
description: Un rápido resumen de Istio en KubeCon + CloudNativeCon + Open Source Summit China en Shanghái.
publishdate: 2023-09-29
attribution: "Comité del Programa de IstioCon China 2023"
keywords: [Istio Day,IstioCon,Istio,conference,KubeCon,CloudNativeCon]
---

Es genial poder reunirnos de nuevo en persona de forma segura. Después de dos años de ejecutar solo eventos virtuales, hemos llenado el calendario para 2023. [Istio Day Europe](/blog/2023/istio-at-kubecon-eu/) se llevó a cabo en abril, e [Istio Day North America](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) viene este noviembre.

IstioCon está comprometido con el service mesh líder de la industria que proporciona una plataforma para explorar los conocimientos obtenidos de despliegues de Istio del mundo real, participar en actividades interactivas prácticas y conectarse con los mantenedores de todo el ecosistema de Istio.

Junto con nuestro evento [IstioCon 2023 virtual](https://events.istio.io/), [IstioCon China 2023](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/co-located-events/istiocon-cn/) se llevó a cabo el 26 de septiembre en Shanghái, China. Como parte de KubeCon + CloudNativeCon + Open Source Summit China, el evento fue organizado y hosted por los mantenedores de Istio y la CNCF. Estábamos muy orgullosos de tener un programa sólido para IstioCon en Shanghái y complacidos de reunir a miembros de la comunidad china de Istio. El evento fue un testimonio de la inmensa popularidad de Istio en el ecosistema de Asia-Pacífico.

{{< image link="./group-pic.jpg"
    caption="IstioCon China 2023"
    >}}

IstioCon China comenzó con una keynote de apertura de los miembros del Comité del Programa Jimmy Song y Zhonghu Xu. El evento estuvo repleto de gran contenido, desde nuevas características hasta charlas de usuarios finales, con un enfoque importante en el nuevo Istio ambient mesh.

{{< image width="75%"
    link="./opening-keynote.jpg"
    caption="IstioCon China 2023, Bienvenida"
    >}}

El discurso de bienvenida fue seguido por una keynote patrocinada de Justin Pettit de Google, sobre "Istio Ambient Mesh como una Infraestructura Gestionada" que resaltó la importancia y prioridad del modelo ambient en la comunidad de Istio, especialmente para nuestros principales patrocinadores como Google Cloud.

{{< image width="75%"
    link="./sponsored-keynote-google.jpg"
    caption="IstioCon China 2023, Keynote Patrocinada de Google Cloud"
    >}}

Perfectamente ubicados después de la keynote, Huailong Zhang de Intel y Yuxing Zeng de Alibaba discutieron configuraciones para la coexistencia de Ambient y Sidecar: un tema muy relevante para los usuarios existentes que quieren experimentar con el nuevo modelo ambient.

{{< image width="75%"
    link="./ambient-l4.jpg"
    caption="IstioCon China 2023, Profundización en flujos de red de Istio y configuraciones para la coexistencia de Ambient y Sidecar"
    >}}

El nuevo data plane de Istio de Huawei basado en eBPF tiene la intención de implementar las capacidades de L4 y L7 en el kernel, para evitar el cambio entre estado de kernel y modo usuario y reducir la latencia del data plane. Esto fue explicado por una charla interesante de Xie SongYang y Zhonghu Xu. Chun Li e Iris Ding de Intel también integraron eBPF con Istio, con su charla "Aprovechando eBPF para la redirección de tráfico en el modo ambient de Istio", lo que llevó a más discusiones interesantes. DaoCloud también tuvo presencia en el evento, con Kebe Liu compartiendo la innovación de Merbridge en eBPF y Xiaopeng Han presentando sobre MirageDebug para el desarrollo localizado de Istio.

{{< image width="75%"
    link="./users-engaging.jpg"
    alt="interacción con la audiencia"
    >}}

La charla de Jimmy Song de Tetrate, sobre la unión perfecta de diferentes herramientas de GitOps y Observabilidad, también fue muy bien recibida. Chaomeng Zhang de Huawei presentó sobre cómo cert-manager ayuda a mejorar la seguridad y flexibilidad del sistema de gestión de certificados de Istio, y Xi Ning Wang y Zehuan Shi de Alibaba Cloud compartieron la idea de usar VK (Virtual Kubelet) para implementar serverless mesh.

Mientras Shivanshu Raj Shrivastava dio una introducción perfecta a WebAssembly a través de su charla "Extendiendo y Personalizando Istio con Wasm", Zufar Dhiyaulhaq de GoTo Financial, Indonesia compartió la práctica de usar Coraza Proxy Wasm para extender Envoy e implementar rápidamente Web Application Firewalls personalizados.
Huabing Zhao de Tetrate compartió las prácticas de gobernanza de servicios Dubbo de Aeraki Mesh con Qin Shilin de Boss Direct. Mientras que la multi-tenencia es siempre un tema candente con Istio, John Zheng de HP describió en detalle sobre la gestión multi-tenante en HP OneCloud Platform.

Las diapositivas para todas las sesiones se pueden encontrar en el [programa de IstioCon China 2023](https://istioconchina2023.sched.com/) y todas las presentaciones estarán disponibles en el Canal de YouTube de CNCF pronto para la audiencia en otras partes del mundo.

## En el piso de exhibición

Istio tuvo un kiosco a tiempo completo en el pabellón de proyectos en KubeCon + CloudNativeCon + Open Source Summit China 2023, con la mayoría de las preguntas siendo sobre ambient mesh. Muchos de nuestros miembros y mantenedores ofrecieron apoyo en el kiosco, donde ocurrieron muchas discusiones interesantes.

{{< image width="75%"
    link="./istio-support-at-the-booth.jpg"
    caption="KubeCon + CloudNativeCon + Open Source Summit China 2023, Kiosco de Istio"
    >}}

Otro punto destacado fue que los miembros del Comité Directivo de Istio y autores de los libros de Istio "Cloud Native Service Mesh Istio" e "Istio: the Definitive Guide", Zhonghu Xu y Chaomeng Zhang, pasaron tiempo en el kiosco de Istio interactuando con nuestros usuarios y contribuyentes.

{{< image width="75%"
    link="./meet-the-authors.jpg"
    caption="Conoce a los autores"
    >}}

Nos gustaría expresar nuestro sincero agradecimiento a nuestro patrocinador diamante Google Cloud, ¡por apoyar a IstioCon 2023!

{{< image width="40%"
    link="./diamond-sponsor.jpg"
    caption="IstioCon 2023, Nuestro Patrocinador Diamante"
    >}}

Por último, pero no menos importante, nos gustaría agradecer a los miembros de nuestro Comité del Programa de IstioCon China por todo su arduo trabajo y apoyo.

{{< image width="75%"
    link="./istiocon-program-committee.jpg"
    caption="IstioCon China 2023, Miembros del Comité del Programa (No aparece en la foto: Iris Ding)"
    >}}

[¡Nos vemos a todos en Chicago en noviembre!](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/)
