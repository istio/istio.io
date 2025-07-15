---
title: "¡Feliz séptimo cumpleaños, Istio!"
description: "Celebrando el impulso y el emocionante futuro de Istio."
publishdate: 2024-05-24
attribution: "Lin Sun (Solo.io), para el Comité Directivo de Istio"
keywords: [istio,birthday,momentum,future]
---

{{< image width="80%"
    link="./7th-birthday.png"
    alt="¡Feliz séptimo cumpleaños, Istio!"
    >}}

Un día como hoy en 2017, [Google e IBM anunciaron el lanzamiento de la service mesh Istio](https://techcrunch.com/2017/05/24/google-ibm-and-lyft-launch-istio-an-open-source-platform-for-managing-and-securing-microservices/). Istio
es una tecnología abierta que permite a los desarrolladores conectar, gestionar y proteger sin problemas redes de diferentes
servicios, independientemente de la plataforma, el origen o el proveedor. ¡Casi no podemos creer que Istio cumpla siete años hoy! Para
celebrar el séptimo cumpleaños del proyecto, queríamos destacar el impulso de Istio y su emocionante futuro.

## Rápida adopción entre los usuarios

Istio, el proyecto de service mesh más adoptado del mundo, ha ido ganando un impulso significativo desde
su creación en 2017. El año pasado, Istio se unió a Kubernetes, Prometheus y otros baluartes del ecosistema
nativo de la nube con [su graduación en la CNCF](https://www.cncf.io/announcements/2023/07/12/cloud-native-computing-foundation-reaffirms-istio-maturity-with-project-graduation/).
Los usuarios finales van desde startups nativas digitales hasta las instituciones financieras y empresas de telecomunicaciones más grandes del mundo, con [casos de estudio](/about/case-studies/)
de empresas como eBay, T-Mobile, Airbnb, Splunk, FICO, T-Mobile, Salesforce y muchas otras.

El control plane y el sidecar de Istio son las imágenes número 3 y 4 más descargadas en Docker Hub, cada una con más de [10 mil millones de descargas](https://hub.docker.com/search?q=istio).

{{< image width="80%"
    link="./dockerhub.png"
    alt="¡Descargas de Istio en Docker Hub!"
    >}}

Tenemos más de 35,000 estrellas de GitHub en el [repositorio principal de Istio](https://github.com/istio/istio/), con un crecimiento continuo. Gracias a todos los que destacaron el repositorio istio/istio.

{{< image width="80%"
    link="./github-stars.png"
    alt="¡Estrellas de GitHub del repositorio istio/istio!"
    >}}

Les pedimos a algunos de nuestros usuarios su opinión con motivo del séptimo cumpleaños de Istio:

{{< quote >}}
**Hoy, Istio sirve como la columna vertebral de la service mesh de Airbnb, gestionando todo nuestro tráfico entre cientos de miles de workloads. Cinco años después de adoptar Istio, siempre hemos estado contentos
con esa decisión. Es realmente increíble ser parte de esta comunidad vibrante y solidaria. ¡Feliz cumpleaños, Istio!**

— Weibo He, Ingeniero de Software Senior en Airbnb
{{< /quote >}}

{{< quote >}}
**Istio ha impulsado nuestra capacidad para desplegar y probar rápidamente microservicios en un entorno aislado similar a la producción
junto con los servicios dependientes. Este enfoque, conocido como Isolates, permite a los desarrolladores de eBay identificar defectos antes en el ciclo de vida del desarrollo
, aumentar la estabilidad de los entornos en vivo al reducir la inestabilidad y generar confianza en las implementaciones
de producción automatizadas. En última instancia, esto ha acelerado el proceso de desarrollo y ha mejorado la tasa de éxito de las implementaciones de producción.**

— Sudheendra Murthy, Ingeniero Principal y Arquitecto de Service Mesh en eBay
{{< /quote >}}

{{< quote >}}
**Istio mejora la seguridad de nuestra plataforma en la nube al tiempo que simplifica la observabilidad mediante la integración del rastreo
distribuido y OpenTelemetry. Esta combinación proporciona
características de seguridad robustas y conocimientos profundos sobre el rendimiento del sistema, lo que permite un monitoreo y
solución de problemas más efectivos de nuestros servicios distribuidos.**

— Sathish Krishnan, Ingeniero Distinguido en UBS
{{< /quote >}}

{{< quote >}}
**La adopción de Istio ha sido un cambio de juego para nuestra organización de ingeniería en nuestro viaje de adopción de una
arquitectura basada en microservicios. Su enfoque de "baterías incluidas" nos ha permitido gestionar fácilmente el enrutamiento del tráfico, obtener una visibilidad profunda de nuestras interacciones de servicio a
servicio con el rastreo distribuido y la extensibilidad a través de complementos WASM. Su completo conjunto de características
lo ha convertido en una parte esencial de nuestra infraestructura y ha permitido a nuestros ingenieros desacoplar el código de la aplicación
de la plomería de la infraestructura.**

— Shray Kumar, Ingeniero de Software Principal en Bluecore
{{< /quote >}}

{{< quote >}}
**Istio es increíble, lo he estado usando durante 4 o 5 años y me resultó muy cómodo para gestionar miles de
gateways para decenas de miles de pods con una latencia muy baja. Si necesitas configurar una infraestructura muy segura, Istio es un gran amigo. Además, es
excelente para infraestructuras que exigen mucha seguridad y necesitan estar alineadas con los estándares PCI/HIPAA/SoC2.**

— Ezequiel Arielli, Jefe de Plataforma en la Nube en SIGMA Financial AI
{{< /quote >}}

{{< quote >}}
**Istio nos ayuda a proteger nuestros entornos de una manera estandarizada en todas nuestras implementaciones para nuestros diversos
clientes. La flexibilidad y personalización de Istio realmente
nos ayuda a construir mejores aplicaciones al delegar el cifrado, la autorización y la autenticación a la service mesh
y no tener que implementar eso en nuestra base de código de aplicación.**

— Joel Millage, Ingeniero de Software en BCubed
{{< /quote >}}

{{< quote >}}
**Usamos Istio en Predibase ampliamente para simplificar la comunicación entre nuestra malla multi-cluster que ayuda a implementar
y entrenar modelos LLM de código abierto ajustados con baja latencia y conmutación por error. Con Istio, obtenemos una gran cantidad de funcionalidades listas para usar que de otro modo
nos llevaría semanas implementar.**

— Gyanesh Mishra, Ingeniero de Infraestructura en la Nube en Predibase
{{< /quote >}}

{{< quote >}}
**Istio es sin duda la plataforma de Service Mesh más completa y con más funciones del mercado. Este éxito es el resultado directo de una comunidad comprometida que se ayuda a sí misma y siempre está
incluida en las direcciones del proyecto. ¡Felicitaciones por el aniversario, Istio!**

— Daniel Requena, SRE en iFood
{{< /quote >}}

{{< quote >}}
**Hemos estado usando Istio en producción durante años, es un componente clave de nuestra infraestructura que nos permite
conectar de forma segura microservicios y proporcionar gestión de tráfico de entrada/salida y observabilidad de primera clase.
La comunidad es excelente y cada versión trae muchas características interesantes.**

— Frédéric Gaudet, SRE Senior en BlablaCar
{{< /quote >}}

## Increíble diversidad de contribuyentes y proveedores

Durante el año pasado, nuestra comunidad ha observado un tremendo crecimiento tanto en el número de empresas
contribuyentes como en el número de contribuyentes. ¿Recuerdas que Istio tenía 500 contribuyentes cuando cumplió tres años?
¡Hemos tenido más de 1,700 contribuyentes en el último año!

Con el equipo de Open Service Mesh de Microsoft uniéndose a
la comunidad de Istio, agregamos Azure a la [lista de nubes y proveedores de Kubernetes empresariales](/about/ecosystem/) que brindan soluciones compatibles con Istio, incluidos Google Cloud, Red Hat OpenShift, VMware Tanzu, Huawei Cloud, DaoCloud, Oracle Cloud, Tencent Cloud, Akamai Cloud y Alibaba Cloud. También estamos encantados de ver al equipo de Amazon Web Services publicar el [EKS Blueprint para Istio](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/)
debido a la alta demanda de los usuarios que desean ejecutar Istio en AWS.

Los proveedores de software de red especializados también están impulsando a Istio, con Solo.io, Tetrate y F5 Networks ofreciendo soluciones empresariales de Istio que se ejecutarán en cualquier entorno.

A continuación se muestran las principales empresas contribuyentes del último año, con Solo.io, Google y DaoCloud ocupando los tres primeros
lugares. Si bien la mayoría de estas empresas son proveedores de Istio, ¡Salesforce y Ericsson son usuarios finales que ejecutan Istio en producción!

{{< image width="80%"
    link="./contribution.png"
    alt="¡Principales empresas contribuyentes de Istio durante el último año!"
    >}}

Aquí hay algunas reflexiones de los líderes de nuestra comunidad:

{{< quote >}}
**La adopción de la service mesh ha aumentado constantemente en los últimos años a medida que la adopción nativa de la nube ha madurado
en todas las industrias. Istio ha ayudado a impulsar parte de esta maduración desde que se
graduaron el año pasado en la CNCF y les deseamos un fantástico cumpleaños. Esperamos ver y apoyar este
crecimiento continuo a medida que el equipo de Istio agrega nuevas características como el modo ambient y simplifica la experiencia de la service mesh.**

— Chris Aniszczyk, CTO de la CNCF
{{< /quote >}}

{{< quote >}}
**Las Service Meshes son fundamentales para las arquitecturas de microservicios, un sello distintivo de lo nativo de la nube. El cumpleaños de Istio celebra la proliferación e
importancia no solo de la observabilidad y la gestión del tráfico, sino también de la creciente demanda de comunicaciones seguras por defecto
a través del cifrado, la autenticación mutua y muchos otros principios básicos de seguridad que simplifican la
experiencia de adopción, integración e implementación.**

— Emily Fox, presidenta del TOC de la CNCF e Ingeniera de Software Principal Senior en Red Hat
{{< /quote >}}

{{< quote >}}
**En mi opinión, Istio no es una service mesh. Es una comunidad colaborativa de usuarios y contribuyentes que resulta que
entregan la service mesh más popular del mundo. ¡Feliz cumpleaños a esta increíble comunidad! Han sido siete años fantásticos, y
espero celebrar muchos más con mis amigos y colegas de todo el mundo en la comunidad de Istio.**

— Mitch Connors, miembro del Comité de Supervisión Técnica de Istio e Ingeniero Principal en Microsoft
{{< /quote >}}

{{< quote >}}
**Ha sido un privilegio y una experiencia gratificante ser parte del equipo de la service mesh más popular del mundo durante
los últimos dos años. Feliz de
ver a Istio crecer de un proyecto de incubación de la CNCF a un proyecto graduado, y aún más feliz de ver el impulso y la pasión con
los que se realizó la última y mejor versión 1.22. Deseando muchos más versiones exitosas en los próximos años.**

— Faseela K, miembro del Comité Directivo de Istio y Desarrolladora Nativa de la Nube en Ericsson
{{< /quote >}}

{{< quote >}}
**Lo que hace que Istio sea único es la comunidad llena de desarrolladores, usuarios y proveedores de todo el mundo que trabajan
juntos para hacer de Istio la mejor y más poderosa service mesh abierta de la industria. Es la fuerza de la comunidad la que
ha hecho que Istio tenga tanto éxito y ahora, bajo la CNCF, espero ver a Istio como el estándar de facto de la service mesh
para todas las aplicaciones nativas de la nube.**

— Neeraj Poddar, miembro del Comité de Supervisión Técnica de Istio y Vicepresidente de Ingeniería en Solo.io
{{< /quote >}}

{{< quote >}}
**Ha sido un privilegio haber trabajado con la comunidad de Istio durante los últimos 5 años. Ha habido una
abundancia de contribuyentes cuya dedicación, pasión y trabajo duro han hecho que mi tiempo en el proyecto sea verdaderamente
agradable. La comunidad tiene muchos usuarios que brindan comentarios para ayudar a hacer de Istio la mejor service mesh. Sigo
asombrado por lo que hace la comunidad y espero ver qué éxitos tendremos en el futuro.**

— Eric Van Norman, miembro del Comité de Supervisión Técnica de Istio e Ingeniero de Software Asesor en IBM
{{< /quote >}}

{{< quote >}}
**Istio es la columna vertebral de la infraestructura de la service mesh de Salesforce, que hoy en día impulsa unos pocos billones de solicitudes por día en todos nuestros servicios. Resolvemos muchos problemas complicados con la malla. Es genial ser parte de este viaje y contribuir a la comunidad. Istio ha madurado hasta convertirse en una service mesh confiable a lo largo de los años y, al mismo tiempo, continúa innovando. ¡Estamos entusiasmados con lo que vendrá en el futuro!**

— Rama Chavali, líder del Grupo de Trabajo de Redes de Istio y Arquitecto de Ingeniería de Software en Salesforce
{{< /quote >}}

## Innovación técnica continua

Creemos firmemente que la diversidad impulsa la innovación. Lo que más nos asombra es la innovación continua de la
comunidad de Istio, desde facilitar las actualizaciones hasta adoptar la API de Gateway de Kubernetes, agregar el nuevo modo de data plane
ambient sin sidecar, hasta hacer que Istio sea fácil de usar y lo más transparente posible.

El modo ambient de Istio se introdujo en septiembre de 2022, diseñado para operaciones simplificadas,
mayor compatibilidad de aplicaciones y menor costo de infraestructura. El modo ambient introduce
proxies de nodo de capa 4 (L4) ligeros y compartidos y proxies opcionales de capa 7 (L7), eliminando la necesidad de proxies
sidecar tradicionales del data plane. La innovación principal detrás del modo ambient es que divide el procesamiento de L4 y L7
en dos capas distintas. Este enfoque por capas te permite adoptar Istio de forma incremental, lo que permite una
transición suave de ninguna malla, a una superposición segura (L4), a un procesamiento L7 completo opcional, por namespace,
según sea necesario, en toda tu flota.

Como parte de la [versión 1.22 de Istio](/news/releases/1.22.x/announcing-1.22/), [el modo ambient ha alcanzado la beta](/blog/2024/ambient-reaches-beta/)
y puedes ejecutar Istio sin sidecars en producción con precauciones.

Aquí hay algunas reflexiones y buenos deseos de nuestros contribuyentes y usuarios:

{{< quote >}}
**Auto Trader ha estado usando Istio en producción, ¡desde antes de que estuviera listo para la producción! Ha mejorado
significativamente nuestras capacidades operativas, estandarizando la forma en que protegemos, configuramos y monitoreamos nuestros servicios. Las actualizaciones han evolucionado de tareas abrumadoras a casi
no eventos, y la introducción de Ambient es una prueba del compromiso continuo con la simplificación, lo que hace que sea
más fácil que nunca para los nuevos usuarios obtener un valor real con un esfuerzo mínimo.**

— Karl Stoney, Arquitecto Técnico en AutoTrader UK
{{< /quote >}}

{{< quote >}}
**Istio es un componente central de la pila nativa de la nube para la nube de Akamai, que proporciona una service mesh segura para
productos y servicios que entregan millones de RPS y cientos de Gigabytes de rendimiento por cluster. Esperamos con interés la hoja de ruta futura para el proyecto y estamos entusiasmados
de evaluar nuevas características como Ambient Mesh a finales de este año.**

— Alex Chircop, Arquitecto Jefe de Producto en Akamai
{{< /quote >}}

{{< quote >}}
**Las capacidades de red y seguridad de Istio se han convertido en un componente fundamental de nuestras operaciones de infraestructura. La introducción del modo ambient de Istio ha simplificado significativamente la gestión y
reducido el tamaño de nuestros nodos de cluster de Kubernetes en aproximadamente un 20%. Migramos con éxito nuestro sistema de producción
para usar el data plane ambient.**

— Saarko Eilers, Gerente de Operaciones de Infraestructura en EISST International Ltd
{{< /quote >}}

{{< quote >}}
**¡Feliz cumpleaños a Istio! Ha sido un honor ser parte de la gran comunidad a lo largo de
los años, especialmente mientras continuamos construyendo la mejor service mesh del mundo con el modo ambient.**

— John Howard, el contribuyente más prolífico de Istio, miembro del Comité de Supervisión Técnica de Istio y Arquitecto Senior en Solo.io
{{< /quote >}}

{{< quote >}}
**Es genial ver que un proyecto maduro como Istio continúa evolucionando y floreciendo. Convertirse en un proyecto graduado de la CNCF ha atraído a una
ola de nuevos desarrolladores que contribuyen a su éxito continuo. Mientras tanto, el soporte de ambient mesh y la API de Gateway
promete marcar el comienzo de una nueva era de adopción de la service mesh. ¡Estoy emocionado de ver lo que está por venir!**

— Justin Pettit, miembro del Comité Directivo de Istio e Ingeniero Senior en Google
{{< /quote >}}

{{< quote >}}
**¡Feliz cumpleaños al increíble proyecto Istio que no solo ha revolucionado la forma en que abordamos la tecnología de
service mesh, sino que también ha cultivado una comunidad vibrante e inclusiva! Ser testigo de la evolución de Istio de un proyecto de incubación de la CNCF a un proyecto
graduado ha sido notable. El reciente lanzamiento de Istio 1.22 subraya su crecimiento continuo y su compromiso con la
excelencia, ofreciendo características mejoradas y un rendimiento mejorado. Esperando el próximo gran paso para el proyecto.**

— Iris Ding, miembro del Comité Directivo de Istio e Ingeniera de Software en Intel
{{< /quote >}}

{{< quote >}}
**Ha sido un privilegio ser parte del proyecto Istio desde el principio, viendo cómo él y la comunidad maduran y crecen a lo largo de los años. A nivel personal, ¡Istio ha sido fundamental en mi propia carrera durante los últimos ocho años! Creo firmemente que lo mejor de Istio está por venir, y en los próximos años veremos un crecimiento, madurez y adopción continuos. Saludos a la maravillosa comunidad por alcanzar este hito juntos.**

— Zack Butcher, miembro del Comité Directivo de Istio e Ingeniero Fundador y Principal en Tetrate
{{< /quote >}}

## Aprende más sobre Istio

Si eres nuevo en Istio, aquí tienes algunos recursos para ayudarte a aprender más:

- Echa un vistazo al [sitio web del proyecto](https://istio.io) y al [repositorio de GitHub](https://github.com/istio/istio/).
- Lee la [documentación](/es/docs/).
- Únete al [Slack](https://slack.istio.io/) de la comunidad.
- Sigue el proyecto en [Twitter](https://twitter.com/IstioMesh) y [LinkedIn](https://www.linkedin.com/company/istio).
- Asiste a las [reuniones de la comunidad de usuarios](https://github.com/istio/community/blob/master/README.md#community-meeting).
- Únete a la [reunión del grupo de trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings).
- Conviértete en un contribuyente y desarrollador de Istio enviando una [solicitud de membresía](https://github.com/istio/community/blob/master/ROLES.md#member), después de que se haya fusionado una pull request tuya.

Si ya eres parte de la comunidad de Istio, por favor, deséale al proyecto Istio un feliz séptimo cumpleaños y comparte tus
pensamientos sobre el proyecto en las redes sociales. ¡Gracias por tu ayuda y apoyo!
