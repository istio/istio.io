---
title: ¿Por qué Istio no puede propagar cabeceras en lugar de la aplicación?
weight: 20
---

Aunque un sidecar de Istio procesará tanto las solicitudes entrantes como las salientes para una instancia de aplicación asociada, no tiene una forma implícita de correlacionar
las solicitudes salientes con la solicitud entrante que las causó. La única forma en que se puede lograr esta correlación es si la aplicación
propaga información relevante (es decir, cabeceras) de la solicitud entrante a las solicitudes salientes. La propagación de cabeceras se puede lograr a través de bibliotecas de cliente
o manualmente. Se proporciona una discusión adicional en [¿Qué se requiere para el seguimiento distribuido con Istio?](/es/about/faq/#how-to-support-tracing).
