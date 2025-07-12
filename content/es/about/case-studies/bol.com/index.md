---
title: "Bol.com escala el comercio electrónico con Istio"
linkTitle: "Bol.com escala el comercio electrónico con Istio"
quote: "La implementación de Istio es una obviedad. Lo instalas y funciona."
author:
    name: "Roland Kool"
    image: "/img/authors/roland-kool.png"
companyName: "bol.com"
companyURL: "https://bol.com/"
logo: "/logos/bol.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 30
---

Bol.com es el minorista en línea más grande de los Países Bajos, y vende de todo, desde libros y productos electrónicos hasta equipos de jardinería. Fundada originalmente en 1999, ha crecido hasta atender a más de 11 millones de clientes en los Países Bajos y Bélgica. Es comprensible que su pila de tecnología e infraestructura de TI hayan crecido y se hayan desarrollado sustancialmente a lo largo de los años.

La infraestructura detrás de su operación solía estar alojada por un tercero, pero finalmente bol.com decidió construir y automatizar su propia infraestructura. A fines de la década de 2010, bol.com comenzó a migrar a la nube. A medida que más y más servicios se abrían paso hacia la nube, los equipos se empoderaron para construir e implementar sus propios servicios e infraestructura basados en la nube.

## Desafío

A medida que comenzaron a migrar las operaciones a la nube, bol.com enfrentó inevitables dolores de crecimiento. Comenzaron a mover aplicaciones a un cluster de Kubernetes, agregando más y más pods con el tiempo. Parecía que el espacio de direcciones del cluster tenía mucho espacio. Desafortunadamente, el escalado para la demanda se convirtió rápidamente en un problema. Inicialmente configuraron el cluster con un CIDR de servicio con espacio para unas 1.000 direcciones, but solo un año después, ya estaban al 80% de su capacidad.

Roland Kool es uno de los ingenieros de sistemas del equipo de bol.com que abordó este problema. Ante el conocimiento de que el espacio de direcciones IP disponible en su cluster de Kubernetes no se mantendría al día con las crecientes necesidades, el equipo necesitaba una solución que permitiera el desbordamiento en clusteres adicionales. Además, esta nueva implementación de Kubernetes de múltiples clusteres traería nuevos desafíos de red, ya que las aplicaciones necesitarían un nuevo enfoque para el descubrimiento de servicios, el equilibrio de carga y la comunicación segura.

## Solución: Múltiples clusteres con una service mesh

La solución parecía ser la introducción de clusteres adicionales, pero se encontraron con problemas con los requisitos de seguridad y las políticas de red que aseguraban el tráfico entre los servicios.

Este desafío se vio exacerbado por la necesidad de proteger la información de identificación personal (PII). Debido a regulaciones europeas como el RGPD, cada servicio que toca PII debe ser identificado y el acceso debe ser estrictamente controlado.

Dado que las políticas de red son locales del cluster, no funcionan a través de los límites del cluster. Todas esas políticas de red por cluster se volvieron complicadas rápidamente. Necesitaban una solución que les permitiera aplicar la seguridad en una capa superior.

El [modelo de implementación de múltiples clusteres](/es/docs/ops/deployment/deployment-models/#multiple-clusters) de Istio terminó siendo la solución perfecta. Las [políticas de autorización](/es/docs/reference/config/security/authorization-policy/) podrían usarse para permitir de forma segura que los workloads de diferentes clusteres se comuniquen entre sí. Con Istio, el equipo de Kool pudo pasar de las políticas de red de la capa 3 o 4 de OSI a las [políticas de autorización](/es/docs/tasks/security/authorization/authz-http/) implementadas en la capa 7. Este movimiento fue posible gracias al sólido soporte de identidad de Istio, la autenticación de servicio a servicio y la seguridad con TLS mutuo (mTLS).

Estos cambios le dieron a bol.com la capacidad de escalar agregando nuevos clusteres de Kubernetes mientras mantenía el descubrimiento de servicios, el equilibrio de carga y las políticas de seguridad requeridas.

## ¿Por qué Istio?

Cuando bol.com comenzó a migrar a Kubernetes, Istio solo estaba en la versión 0.2. No parecía estar listo para la producción, por lo que siguieron adelante sin Istio. Primero comenzaron a analizar seriamente Istio alrededor de la versión 1.0, pero se encontraron con demasiados problemas con la implementación y la puesta en marcha. Sin un caso de uso urgente, dejaron de lado la idea.

Sin embargo, finalmente, no fueron solo los problemas de escalado los que llevaron a bol.com de vuelta a una solución de Istio. Además de necesitar que los clusteres de Kubernetes se comunicaran de forma segura entre sí, también se enfrentaban a nuevos requisitos regulatorios que requerirían comunicaciones seguras con varios servicios y API de terceros. Estos controles no podían basarse en reglas de firewall y rangos de IP, que están sujetos a cambios constantes; debían basarse en la identidad de la aplicación.

Su solución aprovechó la [gateway de salida de Istio](/es/docs/tasks/traffic-management/egress/egress-gateway/). Esto les permite aplicar controles de autorización que pueden permitir o denegar el tráfico en función de atributos como la identidad o el namespace de el workload del cliente, el nombre de host de destino e incluso atributos como la URL de la solicitud HTTP.

Bol.com necesitaba una service mesh que admitiera implementaciones de múltiples clusteres, e Istio encajaba perfectamente. Además, Istio proporcionó el control detallado que necesitaban para cumplir con sus requisitos particulares.

## Resultados: Habilitación de DevOps

"La implementación de Istio es una obviedad", explicó Roland Kool. "Lo instalas y funciona".

Después de instalar Istio, pasaron a la implementación de las características de la service mesh que les importaban. La implementación de sidecars requirió un trabajo adicional de los equipos individuales y el apoyo del equipo responsable de la implementación de Istio.

Uno de los mayores cambios para Kool y el equipo de bol.com fue que de repente fue mucho más fácil implementar políticas de autorización en torno a los servicios. La implementación de Istio en bol.com se encuentra actualmente en aproximadamente un 95% de adopción y continúa creciendo. Puede ser difícil complacer a todos los desarrolladores, pero el equipo de implementación de Istio ha trabajado arduamente para que sea simple de adoptar y fácil de integrar.

Los desarrolladores han proporcionado buenos comentarios y han adoptado con entusiasmo muchas de las capacidades de Istio. Están satisfechos con lo fácil que es ahora hacer que las aplicaciones se comuniquen entre sí a través de los clusteres. Todas estas conexiones son fáciles de configurar y administrar, gracias a Istio.

La infraestructura de bol.com continúa evolucionando y, gracias a la observabilidad que ofrece, Istio es una parte clave de esa hoja de ruta. Al [integrar Istio con Prometheus](/es/docs/ops/integrations/prometheus/), pueden recopilar las métricas y los diagnósticos necesarios para comprender hacia dónde debe llevarlos esa hoja de ruta. Los planes futuros ahora incluyen la consolidación de los servicios de equilibrio de carga, nuevos métodos de prueba, seguimiento distribuido y la instalación de Istio en más de la infraestructura de la empresa.
