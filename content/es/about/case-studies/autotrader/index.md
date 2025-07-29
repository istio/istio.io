---
title: "El pionero de Istio, AutoTrader UK, sigue beneficiándose"
linkTitle: "El pionero de Istio, AutoTrader UK, sigue beneficiándose"
quote: "Decidimos probar Istio para ver cómo funcionaba, y terminamos entregando en aproximadamente una semana más de lo que habíamos hecho en los últimos cuatro meses tratando de implementarlo nosotros mismos."
author:
    name: "Karl Stoney"
    image: "/img/authors/karl-stoney.png"
companyName: "Auto Trader UK"
companyURL: "https://autotrader.co.uk/"
logo: "/logos/autotrader.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
weight: 10
---

Auto Trader UK comenzó en 1977 como la principal revista del mercado automotriz en el Reino Unido. Cuando pasó a tener presencia en línea cerca de finales del siglo XX, creció hasta convertirse en el mercado automotriz digital más grande del Reino Unido.

El patrimonio de TI que respalda a Auto Trader UK es vasto. Hoy en día, administran alrededor de 50 aplicaciones orientadas al cliente respaldadas por unos 400 microservicios que procesan más de 30.000 solicitudes por segundo. Su infraestructura se ejecuta en Google Kubernetes Engine (GKE) y utiliza la service mesh de Istio. Como una importante historia de éxito de Istio, Auto Trader UK ha recibido mucha atención por su migración a la nube pública desde 2018.

## Desafío

Los requisitos cambiantes precipitaron la migración de Auto Trader UK a aplicaciones en contenedores utilizando Istio como service mesh. Una de las razones más apremiantes fue el reciente enfoque en el RGPD. AutoTrader no estaba satisfecho con la seguridad perimetral típica. Aspiraba a cifrar también todo el tráfico entre microservicios, incluso aquellos en la misma red local, utilizando TLS mutuo. El esfuerzo parecía significativo para una infraestructura de nube privada local principalmente personalizada que operaba a la gran escala de Auto Trader.

Había otra motivación para habilitar mTLS para todo el tráfico; Auto Trader UK planeaba trasladar la mayor parte de su infraestructura a la nube pública. Un [mTLS sólido de extremo a extremo](/es/docs/tasks/security/authentication/mtls-migration/) sería importante para proteger todo su ecosistema de microservicios.

## Solución: Istio y Google Kubernetes Engine (GKE)

El equipo de la plataforma de Auto Trader UK trabajó en una implementación de prueba de concepto de mTLS para la nube privada local. Como era de esperar, la implementación fue una tarea laboriosa. Decidieron experimentar con una solución basada en contenedores que pudiera aprovechar una service mesh como Istio para administrar mTLS para una porción clave de extremo a extremo de su arquitectura de microservicios. AutoTrader no tenía la ambición de construir y administrar Kubernetes por sí mismos, por lo que decidieron ejecutar su experimento en GKE.

El experimento con contenedores fue un éxito. La implementación del cifrado estaba llevando semanas de esfuerzo en la nube privada, pero solo días en el proyecto en contenedores. El camino de la migración a los servicios en contenedores estaba claro.

{{< quote caption="Karl Stoney, líder de infraestructura de entrega en Auto Trader UK" >}}
Decidimos probar Istio para ver cómo funcionaba, y terminamos entregando en aproximadamente una semana más de lo que habíamos hecho en los últimos cuatro meses tratando de implementarlo nosotros mismos.
{{< /quote >}}

## ¿Por qué Istio?

Si bien la fácil transición a mTLS para todos los microservicios fue un fuerte incentivo, Istio también cuenta con el respaldo de muchas grandes organizaciones. Auto Trader UK ya estaba trabajando con Google Cloud, por lo que saber que Google era un fuerte contribuyente y usuario de Istio les dio la confianza de que tenía soporte a largo plazo y que crecería en el futuro.

El éxito temprano con los experimentos en GKE con Istio condujo a una rápida aceptación por parte del negocio. Junto con un camino fácil hacia mTLS, comenzaron a habilitar importantes capacidades de observabilidad que redujeron significativamente el riesgo de la migración a la nube. A medida que Istio ha evolucionado, el equipo de la plataforma ha podido exponer capacidades básicas como reintentos sólidos, detección de valores atípicos y división del tráfico con un esfuerzo mínimo.

## Resultados: Confianza y observabilidad

Istio le dio a Auto Trader UK la confianza para implementar cada vez más aplicaciones en la nube pública. Istio les permitió considerar los servicios en agregados en lugar de solo como instancias individuales. Con una mayor observabilidad, tenían una nueva forma de administrar y pensar en la infraestructura. De repente, tuvieron información sobre el rendimiento y la seguridad. Mientras tanto, Istio les estaba ayudando a descubrir errores existentes que habían estado allí todo el tiempo, sin que se dieran cuenta. Al corregir pequeñas fugas de memoria y pequeños errores en las aplicaciones existentes, pudieron lograr mejoras significativas en el rendimiento de su arquitectura general.

### Surgimiento de un equipo de entrega de plataforma

No solo pudieron implementar rápidamente, sino que también empaquetaron una solución de Kubernetes e Istio como un producto interno para que otros equipos de productos lo consumieran. Un equipo de diez personas ahora administra una plataforma de entrega que atiende a más de 200 desarrolladores.

Istio y Kubernetes permitieron la mejor implementación de aplicaciones y la gestión de recursos que el equipo buscaba, pero Istio también aportó información fenomenal sobre el rendimiento de las aplicaciones. La observabilidad fue clave; Auto Trader UK ahora mide la utilización precisa de los recursos y las transacciones de los microservicios. Con estas métricas de servicio, pueden dimensionar correctamente las implementaciones para reducir y administrar los costos de la nube.

Si bien no fue una migración completamente transparente, los beneficios de Istio y Kubernetes alentaron a todos los equipos de productos a migrar. Con menos dependencias que administrar y muchas funciones proporcionadas automáticamente por Istio, los requisitos multifuncionales se cumplen con un esfuerzo casi nulo por parte de los equipos de proyecto. Los equipos pueden implementar aplicaciones web a nivel mundial en minutos, y la nueva infraestructura maneja fácilmente entre 200 y 250 implementaciones por día.

### Habilitación de CI/CD

Incluso una aplicación completamente nueva se puede implementar en producción en solo cinco minutos. La implementación rápida para las aplicaciones existentes ha cambiado las metodologías de lanzamiento en Auto Trader UK. Con más confianza en la observabilidad y la reversión, más equipos están adoptando prácticas de CD. El monitoreo afinado con Istio permite al equipo de implementación identificar de manera rápida y precisa los problemas con las nuevas implementaciones. Los equipos individuales pueden ver sus propios paneles de rendimiento. Si ven nuevos errores, los cambios se pueden revertir inmediatamente a través de las herramientas de CI/CD.

Auto Trader UK tomó un gran patrimonio de TI totalmente personalizado y lo cambió sistemáticamente a microservicios en una nube pública. Su implementación de Istio fue una parte clave del éxito de la migración y ha abierto a toda su organización a un mejor proceso, una mejor visibilidad y mejores aplicaciones.
