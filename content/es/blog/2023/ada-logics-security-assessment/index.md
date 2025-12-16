---
title: "Istio publica los resultados de la auditoría de seguridad de 2022"
description: La revisión de seguridad de Istio encuentra un CVE en la biblioteca estándar de Go.
publishdate: 2023-01-30
attribution: "Craig Box (ARMO), para el Grupo de Trabajo de Seguridad de Productos de Istio"
keywords: [istio,security,audit,ada logics,assessment,cncf,ostif]
---

Istio es un proyecto en el que los ingenieros de plataforma confían para aplicar las políticas de seguridad en sus entornos de Kubernetes de producción. Prestamos mucha atención a la seguridad en nuestro código y mantenemos un [programa de vulnerabilidades](/docs/releases/security-vulnerabilities/) robusto. Para validar nuestro trabajo, periódicamente invitamos a una revisión externa del proyecto, y nos complace publicar [los resultados de nuestra segunda auditoría de seguridad](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf).

La evaluación de los auditores fue que **"Istio es un proyecto bien mantenido que tiene un enfoque fuerte y sostenible de la seguridad"**. No se encontraron problemas críticos; lo más destacado del informe fue el descubrimiento de una vulnerabilidad en el lenguaje de programación Go.

Queremos agradecer a la [Cloud Native Computing Foundation](https://cncf.io/) por financiar este trabajo, como un beneficio que se nos ofreció después de [unirnos a la CNCF en agosto](https://www.cncf.io/blog/2022/09/28/istio-sails-into-the-cloud-native-computing-foundation/). Fue [organizado por OSTIF](https://ostif.org/the-audit-of-istio-is-complete) y [realizado por ADA Logics](https://adalogics.com/blog/istio-security-audit).

## Alcance y hallazgos generales

[Istio recibió su primera evaluación de seguridad en 2020](/blog/2021/ncc-security-assessment/), y su plano de datos, el [proxy Envoy](https://envoyproxy.io/), fue [evaluado independientemente en 2018 y 2021](https://github.com/envoyproxy/envoy#security-audit). Por lo tanto, el Grupo de Trabajo de Seguridad de Productos de Istio y ADA Logics decidieron el siguiente alcance:

* Producir un modelo de amenazas formal, para guiar esta y futuras auditorías de seguridad
* Realizar una auditoría manual del código en busca de problemas de seguridad
* Revisar las correcciones de los problemas encontrados en la auditoría de 2020
* Revisar y mejorar el conjunto de pruebas de fuzzing de Istio
* Realizar una revisión SLSA de Istio

Una vez más, no se encontraron problemas críticos en la revisión. La evaluación encontró 11 problemas de seguridad; dos altos, cuatro medios, cuatro bajos y uno informativo. Todos los problemas reportados han sido corregidos.

{{< quote >}}
**"Istio es un proyecto muy bien mantenido y seguro con una base de código sólida, prácticas de seguridad bien establecidas y un equipo de seguridad de productos receptivo." - ADA Logics**
{{< /quote >}}

Además de sus observaciones anteriores, los auditores señalan que Istio sigue un alto nivel de estándares de la industria en el manejo de la seguridad. En particular, destacan que:

* El Grupo de Trabajo de Seguridad de Productos de Istio responde rápidamente a las divulgaciones de seguridad
* La documentación sobre la seguridad del proyecto es completa, está bien escrita y actualizada
* Las divulgaciones de vulnerabilidades de seguridad siguen los estándares de la industria y los avisos de seguridad son claros y detallados
* Las correcciones de seguridad incluyen pruebas de regresión

## Resolución y aprendizajes

### Vulnerabilidad de contrabando de solicitudes en Go

Los auditores descubrieron una situación en la que Istio podría aceptar tráfico usando HTTP/2 Over Cleartext (h2c), un método para realizar una conexión no cifrada con HTTP/1.1 y luego actualizar a HTTP/2. La [biblioteca Go para conexiones h2c](https://pkg.go.dev/golang.org/x/net/http2/h2c) lee toda la solicitud en la memoria, y señala que si desea evitar esto, la solicitud debe envolverse en un `MaxBytesHandler`.

Al corregir este error, John Howard, miembro del TOC de Istio, notó que la corrección recomendada introduce una [vulnerabilidad de contrabando de solicitudes](https://portswigger.net/web-security/request-smuggling). Por lo tanto, el equipo de Go publicó [CVE-2022-41721](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-41721) — ¡la única vulnerabilidad descubierta por esta auditoría!

Istio ha sido modificado desde entonces para deshabilitar el soporte de actualización h2c por completo.

### Mejoras en la recuperación de archivos

La clase de problemas más común encontrada estuvo relacionada con Istio recuperando archivos a través de una red (por ejemplo, el Operador de Istio instalando gráficos de Helm, o el descargador de módulos WebAssembly):

* Un gráfico de Helm diseñado maliciosamente podría agotar el espacio en disco (#1) o sobrescribir otros archivos en el pod del Operador (#2)
* Los manejadores de archivos no se cerraban en caso de error y podrían agotarse (#3)
* Los archivos diseñados maliciosamente podrían agotar la memoria (#4 y #5)

Para ejecutar estas rutas de código, un atacante necesitaría suficientes privilegios para especificar una URL para un gráfico de Helm o un módulo WebAssembly. Con ese acceso, no necesitarían un exploit: ya podrían causar que se instale un gráfico arbitrario en el clúster o que se cargue un módulo WebAssembly arbitrario en la memoria en los servidores proxy.

Tanto los auditores como los mantenedores señalan que el Operador no se recomienda como método de instalación, ya que esto requiere que se ejecute un controlador de alto privilegio en el clúster.

### Otros problemas

Los problemas restantes encontrados fueron:

* En algún código de prueba, o donde un componente del plano de control se conecta a otro componente a través de localhost, no se aplicaban las configuraciones mínimas de TLS (#6)
* Las operaciones que fallaban podrían no devolver códigos de error (#7)
* Se estaba utilizando una biblioteca obsoleta (#8)
* Condiciones de carrera [TOC/TOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use) en una biblioteca utilizada para copiar archivos (#9)
* Un usuario podría agotar la memoria del Servicio de Tokens de Seguridad si se ejecuta en modo Debug (#11)

Consulte [el informe completo](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf) para obtener más detalles.

### Revisión del informe de 2020

Se encontró que todos los 18 problemas reportados en la primera evaluación de seguridad de Istio habían sido corregidos.

### Fuzzing

El [proyecto OSS-Fuzz](https://google.github.io/oss-fuzz/) ayuda a los proyectos de código abierto a realizar [pruebas de fuzzing](https://en.wikipedia.org/wiki/Fuzzing) gratuitas. Istio está integrado en OSS-Fuzz con 63 fuzzers ejecutándose continuamente: este soporte fue [construido por ADA Logics y el equipo de Istio a fines de 2021](https://adalogics.com/blog/fuzzing-istio-cve-CVE-2022-23635).

{{< quote >}}
**"[Nosotros] comenzamos la evaluación de fuzzing priorizando las partes críticas de seguridad de Istio. Encontramos que muchas de estas tenían una cobertura de prueba impresionante con poco o ningún margen de mejora." - ADA Logics**
{{< /quote >}}

La evaluación señala que "Istio se beneficia en gran medida de tener un conjunto sustancial de pruebas de fuzzing que se ejecutan continuamente en OSS-Fuzz", e identificó algunas APIs en código crítico de seguridad que se beneficiarían de más fuzzing. Se contribuyeron seis nuevos fuzzers como resultado de este trabajo; al final de la auditoría, las nuevas pruebas se habían ejecutado más de **3 mil millones** de veces.

### SLSA

[Supply chain Levels for Software Artifacts](https://slsa.dev/) (SLSA) es una lista de verificación de estándares y controles para prevenir la manipulación, mejorar la integridad y asegurar los paquetes de software y la infraestructura. Está organizado en una serie de niveles que proporcionan garantías de integridad crecientes.

Istio actualmente no genera artefactos de procedencia, por lo que no cumple con los requisitos para ningún nivel SLSA. [El trabajo para alcanzar el nivel 1 de SLSA está actualmente en curso](https://github.com/istio/istio/issues/42517). Si desea involucrarse, únase al [Slack de Istio](https://slack.istio.io/) y comuníquese con nuestro [grupo de trabajo de Test and Release](https://istio.slack.com/archives/C6FCV6WN4).

## Participe

Si desea involucrarse con la seguridad de productos de Istio, o convertirse en un mantenedor, ¡nos encantaría tenerte! [Únase a nuestras reuniones públicas](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) para plantear problemas o aprender sobre lo que estamos haciendo para mantener Istio seguro.

