---
title: "Comunicaciones seguras de aplicaciones con TLS mutuo e Istio"
description: Profundización en la seguridad de comunicaciones de aplicaciones, mTLS e Istio para lograr mTLS de extremo a extremo entre sus aplicaciones.
publishdate: 2023-10-17
attribution: "Lin Sun (Solo.io), Yuval Kohavi (Solo.io)"
keywords: [istio,mtls,tls]
---

Una de las mayores razones por las que los usuarios adoptan service mesh es para habilitar comunicaciones seguras
entre aplicaciones usando TLS mutuo (mTLS) basado en identidades criptográficamente verificables. En este blog, discutiremos los requisitos de comunicación segura
entre aplicaciones, cómo mTLS habilita y cumple todos esos requisitos, junto con
pasos simples para comenzar a habilitar mTLS entre sus aplicaciones usando Istio.

## ¿Qué necesita para asegurar las comunicaciones entre sus aplicaciones?

Las aplicaciones modernas nativas de la nube están frecuentemente distribuidas a través de múltiples clústeres de Kubernetes o máquinas virtuales. Nuevas versiones se están preparando frecuentemente y pueden escalar rápida y dinámicamente basándose en solicitudes de usuario. A medida que las aplicaciones modernas ganan eficiencia en la utilización de recursos al no depender de la co-ubicación, es primordial poder aplicar políticas de acceso y asegurar las comunicaciones entre estas aplicaciones distribuidas debido al aumento de múltiples puntos de entrada que resultan en una superficie de ataque más grande. Ignorar esto es invitar a un riesgo empresarial masivo por pérdida de datos, robo de datos, datos falsificados o simple mal manejo.

Los siguientes son los requisitos clave comunes para comunicaciones seguras entre aplicaciones:

### Identidades

La identidad es un componente fundamental de cualquier arquitectura de seguridad. Antes de que sus
aplicaciones puedan enviar sus datos de forma segura, las **identidades** deben establecerse para las
aplicaciones. Este proceso de *establecer una identidad* se llama **validación de identidad** - involucra
alguna **autoridad** bien conocida y confiable que realiza una o más
verificaciones en la carga de trabajo de la aplicación para establecer que es lo que afirma ser. Una vez
que la autoridad está satisfecha, otorga a la carga de trabajo una identidad.

Considere el acto de recibir un pasaporte - solicitará uno a alguna autoridad, esa
autoridad probablemente le pedirá varias validaciones de identidad diferentes que demuestren que usted es
quien dice ser - un certificado de nacimiento, dirección actual, registros médicos, etc. Una vez que haya
satisfecho todas las validaciones de identidad, (con suerte) recibirá el documento de
identidad. Puede dar ese documento de identidad a otra persona como prueba de que ha satisfecho
todas los requisitos de validación de identidad de la autoridad emisora, y si confían en la
autoridad emisora (y en el documento de identidad en sí), pueden confiar en lo que dice sobre usted (o pueden contactar a la autoridad confiable y verificar el documento).

Una identidad podría tomar cualquier forma, pero, como con cualquier forma de documento de identidad, cuanto más débiles sean las validaciones de identidad, más fácil es falsificar, y menos útil es ese documento de identidad para cualquiera
que lo use para tomar una decisión. Por eso, en computación, las identidades criptográficamente verificables son
tan importantes - están firmadas por una autoridad verificable, similar a
su pasaporte y licencia de conducir. Las identidades basadas en cualquier cosa menos son una debilidad de seguridad
que es relativamente fácil de explotar.

Su sistema puede tener identidades derivadas de propiedades de red como direcciones IP con
cachés de identidad distribuidos que rastrean el mapeo entre identidades y estas propiedades de red.
Estas identidades no tienen garantías fuertes como identidades criptográficamente verificables
porque las direcciones IP podrían reasignarse a diferentes cargas de trabajo y los cachés de identidad pueden
no siempre actualizarse a lo último.

Usar identidades criptográficamente verificables para sus aplicaciones es deseable, porque intercambiar
identidades criptográficamente verificables para aplicaciones durante el establecimiento de conexión es
inherentemente más confiable y seguro que sistemas dependientes de mapear direcciones IP a identidades.
Estos sistemas dependen de cachés de identidad distribuidos con problemas de consistencia eventual y obsolescencia
que podrían crear una debilidad estructural en Kubernetes, donde altas tasas de rotación automatizada de pods son
la norma.

### Confidencialidad

Cifrar los datos transmitidos entre aplicaciones es crítico - porque en un mundo donde las brechas
son comunes, costosas y efectivamente triviales, depender enteramente de entornos internos *seguros* u
otros perímetros de seguridad ha dejado de ser adecuado desde hace tiempo. Para prevenir un
[ataque de hombre en el medio](https://en.wikipedia.org/wiki/Man-in-the-middle_attack), requiere un canal de cifrado único para un par origen-destino porque desea una fuerte garantía de unicidad de identidad para evitar [problemas de diputado confundido](https://en.wikipedia.org/wiki/Confused_deputy_problem).
En otras palabras, no es suficiente simplemente cifrar el canal - debe cifrarse usando claves únicas directamente derivadas de las identidades únicas de origen y destino para que solo el origen y
destino puedan descifrar los datos. Además, puede necesitar personalizar el cifrado, por ejemplo eligiendo
cifrados específicos, de acuerdo con lo que requiera su equipo de seguridad.

### Integridad

Los datos cifrados enviados por la red desde el origen al destino no pueden ser modificados por ninguna
identidad que no sea el origen y destino una vez que se envían. En otras palabras, los datos recibidos son
los mismos que los datos enviados. Si no tiene [integridad de datos](https://en.wikipedia.org/wiki/Data_integrity),
alguien en el medio podría modificar algunos bits o todo el contenido de los datos durante la
comunicación entre el origen y el destino.

### Aplicación de política de acceso

Los propietarios de aplicaciones necesitan aplicar políticas de acceso a sus aplicaciones y hacer que se apliquen
correctamente, consistentemente y sin ambigüedades. Para aplicar política para ambos extremos de un canal de comunicación, necesitamos una identidad de aplicación para cada extremo. Una vez que tenemos una identidad criptográficamente verificable con una cadena de procedencia inequívoca para ambos extremos de un canal de comunicación potencial, podemos
comenzar a aplicar políticas sobre quién puede comunicarse con qué. El TLS estándar, el protocolo criptográfico ampliamente utilizado que asegura la comunicación entre clientes (por ejemplo, navegadores web) y servidores
(por ejemplo, servidores web), solo realmente verifica y requiere una identidad para un lado - el servidor. Pero
para una aplicación integral de políticas de extremo a extremo, es crítico tener una identidad confiable, verificable e inequívoca para ambos lados - cliente y servidor. Este es un requisito común para aplicaciones internas - imagine por ejemplo un escenario donde solo una aplicación `frontend` debería llamar al
método **GET** para una aplicación backend `checkout`, pero no debería tener permitido llamar al método `POST` o
`DELETE`. O un escenario donde solo las aplicaciones que tienen un token JWT emitido por un
emisor JWT particular pueden llamar al método `GET` para una aplicación `checkout`. Al aprovechar identidades criptográficas en ambos extremos, podemos asegurar que se apliquen políticas de acceso poderosas correctamente, de forma segura y confiable, con un rastro de auditoría validable.

### Cumplimiento FIPS

[Federal Information Processing Standards (FIPS)](https://www.nist.gov/standardsgov/compliance-faqs-federal-information-processing-standards-fips)
son estándares y pautas para sistemas informáticos federales que son desarrollados por
[National Institute of Standards and Technology (NIST)](https://www.nist.gov/). No todos
requieren cumplimiento FIPS, pero el cumplimiento FIPS significa cumplir con todos los requisitos de seguridad necesarios
establecidos por el gobierno de los EE.UU. para proteger información sensible. Es requerido cuando se trabaja
con el gobierno federal. Para seguir las pautas desarrolladas por el gobierno de EE.UU. relacionadas con
ciberseguridad, muchos en el sector privado usan voluntariamente estos estándares FIPS.

Para ilustrar los requisitos de aplicaciones seguras anteriores (identidad, confidencialidad e integridad),
usemos el ejemplo de que la aplicación `frontend` llama a la aplicación `checkout`. Recuerde, puede pensar en **ID** en el diagrama como cualquier tipo de documento de identidad como un pasaporte emitido por el gobierno,
identificador con foto:

{{< image width="100%"
    link="requirements-flow.png"
    caption="Requisitos cuando el frontend llama a la aplicación checkout"
    >}}

## ¿Cómo satisface mTLS los requisitos anteriores?

La especificación de TLS 1.3 (la versión TLS más reciente al momento de escribir) [especificación](https://datatracker.ietf.org/doc/html/rfc8446)'s
objetivo principal es proporcionar un canal seguro entre dos pares comunicantes.
El canal seguro TLS tiene las siguientes propiedades:

1. Autenticación: el lado del servidor del canal está siempre autenticado, el lado del cliente está
opcionalmente autenticado. Cuando el cliente también está
autenticado, el canal seguro se convierte en un canal TLS mutuo.
1. Confidencialidad: Los datos están cifrados y solo visibles para el cliente y el servidor. Los datos deben
cifrarse usando claves que estén inequívocamente ligadas criptográficamente a los documentos de identidad de origen y destino para proteger de manera confiable el tráfico de la capa de aplicación.
1. Integridad: los datos enviados por el canal no pueden modificarse sin detección. Esto está garantizado por
el hecho de que solo el origen y destino tienen la clave para cifrar y descifrar los datos para una sesión dada.

### Internos de mTLS

Hemos establecido que las identidades criptográficamente verificables son clave para asegurar canales y
soportar la aplicación de políticas de acceso, y hemos establecido que mTLS es un protocolo probado en batalla
que requiere algunas garantías extremadamente importantes para usar identidades criptográficamente verificables
en ambos extremos de un canal - profundicemos en algunos detalles sobre cómo funciona realmente el protocolo mTLS bajo
el capó.

#### Protocolo de handshake

El [protocolo de handshake](https://datatracker.ietf.org/doc/html/rfc8446#section-4) autentica a los
pares comunicantes, negocia modos criptográficos y parámetros, y establece material de clave compartido. En otras palabras, el papel del handshake es verificar las identidades de los pares comunicantes
y negociar una clave de sesión, para que el resto de la conexión pueda cifrarse basándose en la
clave de sesión. Cuando sus aplicaciones hacen una conexión mTLS, el servidor y el cliente negocian un conjunto de cifrado, que dicta qué algoritmo de cifrado usarán sus aplicaciones para el resto de la
conexión y sus aplicaciones también negocian la clave de sesión criptográfica a usar. Todo el
handshake está diseñado para resistir manipulación - la interferencia de cualquier entidad que no posea la
misma identidad criptográficamente verificable única como el documento de identidad del origen y/o destino será
rechazada. Por esta razón, es importante verificar todo el handshake y verificar su integridad
antes de que cualquier par comunicante continúe con los datos de aplicación.

El handshake puede pensarse como teniendo tres fases según la
[visión general del protocolo de handshake](https://datatracker.ietf.org/doc/html/rfc8446#section-2) en la especificación TLS 1.3
- nuevamente, usemos el ejemplo de una aplicación `frontend` llamando a una aplicación backend
`checkout`:

1. Fase 1: `frontend` y `checkout` negocian los parámetros criptográficos y claves de cifrado
que pueden usarse para proteger el resto del handshake y datos de tráfico.
1. Fase 2: todo en esta fase y después está cifrado. En esta fase, `frontend` y `checkout` establecen otros parámetros de handshake, y si el cliente también está
autenticado - es decir, mTLS.
1. Fase 3: `frontend` autentica `checkout` a través de su identidad criptográficamente verificable (y, en mTLS, `checkout` autentica `frontend` de la misma manera).

Hay algunas diferencias principales desde TLS 1.2 relacionadas con el handshake, consulte la especificación TLS 1.3 para [más detalles](https://datatracker.ietf.org/doc/html/rfc8446#section-1.2):

1. Todos los mensajes de handshake (fase 2 y 3) están cifrados **usando las claves de cifrado negociadas en la fase 1**.
1. Se han eliminado algoritmos de cifrado simétrico heredados.
1. Se agregó un modo de tiempo de ida y vuelta cero (0-RTT), ahorrando una ida y vuelta en la configuración de conexión.

#### Protocolo de registro

Habiendo negociado la versión del protocolo TLS, clave de sesión y [HMAC](https://en.wikipedia.org/wiki/HMAC)
durante la fase de handshake, los pares ahora pueden intercambiar de forma segura datos cifrados que son fragmentados por el [protocolo de registro](https://datatracker.ietf.org/doc/html/rfc8446#section-5). Es crítico (y
requerido como parte de la especificación) usar exactamente los mismos parámetros negociados del handshake para
cifrar el tráfico para asegurar la confidencialidad e integridad del tráfico.

Poniendo los dos protocolos de la especificación TLS 1.3 juntos y usando las aplicaciones `frontend` y
`checkout` para ilustrar el flujo como sigue:

{{< image width="100%"
    link="mtls-flow.png"
    caption="Flujos de mTLS cuando el frontend llama a la aplicación checkout"
    >}}

¿Quién emite los certificados de identidad para `frontend` y `checkout`? Comúnmente son emitidos por una
[autoridad certificadora (CA)](https://en.wikipedia.org/wiki/Certificate_authority) que tiene
su propio [certificado raíz](https://en.wikipedia.org/wiki/Root_certificate) o usa un certificado intermedio
de su CA raíz. Un certificado raíz es básicamente un certificado de clave pública que
identifica una CA raíz, que probablemente ya tiene en su organización. El certificado raíz se
distribuye a `frontend` (o `checkout`) además de su propio certificado de identidad firmado por la raíz. Así es como
funciona la PKI (Infraestructura de Clave Pública) cotidiana básica - una CA tiene la responsabilidad de validar el
documento de identidad de una entidad, y luego le otorga un documento de identidad infalse en forma de certificado.

Puede depender de su CA y CAs intermedias como fuente de **verdad** de identidad de manera estructural
que mantiene alta disponibilidad y garantías de identidad persistentemente verificables y estables de una manera
que un caché distribuido masivo de mapas de IP e identidad simplemente no puede. Cuando los certificados de identidad de `frontend` y
`checkout` son emitidos por el mismo certificado raíz, `frontend` y `checkout`
pueden verificar las identidades de sus pares de manera consistente y confiable independientemente del clúster o nodos o escala
donde se ejecuten.

Aprendió sobre cómo mTLS proporciona identidad criptográfica, confidencialidad e integridad, ¿qué
hay de la escalabilidad a medida que crece a miles o más aplicaciones entre múltiples clústeres? Si
establece un único certificado raíz entre múltiples clústeres, el sistema no necesita preocuparse cuando
su aplicación recibe una solicitud de conexión de otro clúster siempre que sea confiable por el certificado
raíz - el sistema sabe que la identidad en la conexión está criptográficamente verificada. A medida que el pod de su
aplicación cambia IP o se redespliega a un clúster o red diferente, su aplicación (o
componente actuando en su nombre) simplemente origina el tráfico con su certificado confiable acuñado
por la CA al destino. Pueden ser 500+ saltos de red o puede ser directo; sus políticas de acceso para
su aplicación se aplican de la misma manera independientemente de la topología, sin necesidad de
mantener un seguimiento del caché de identidad y calcular qué dirección IP mapea a qué pod de aplicación.

¿Qué hay del cumplimiento FIPS? Según la especificación TLS 1.3, las aplicaciones compatibles con TLS deben implementar el
conjunto de cifrado `TLS_AES_128_GCM_SHA256`, y se recomienda implementar `TLS_AES_256_GCM_SHA384`, ambos
también están en las [pautas para TLS](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-52r2.pdf)
de NIST. Los certificados de servidor RSA o ECDSA también son recomendados tanto por la especificación TLS 1.3 como por
la pauta de NIST para TLS. Siempre que use mTLS y módulos criptográficos compatibles con FIPS 140-2 o 140-3
para sus conexiones mTLS, estará en el camino correcto para la
[validación FIPS 140-2 o 140-3](https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules).

## ¿Qué podría salir mal?

Es crítico implementar mTLS exactamente como la especificación TLS 1.3 lo dicta. Sin usar
mTLS apropiado siguiendo la especificación TLS, aquí hay algunas cosas que pueden salir mal sin
detección:

### ¿Qué pasa si alguien en medio de la conexión captura silenciosamente los datos cifrados?

Si la conexión no sigue exactamente los protocolos de handshake y registro como se describe en la especificación TLS, por ejemplo, la conexión sigue el protocolo de handshake pero no usa la
clave de sesión y parámetros negociados del handshake en el protocolo de registro, puede que tenga el
handshake de su conexión no relacionado con el protocolo de registro donde las identidades podrían ser diferentes entre
el handshake y los protocolos de registro. TLS requiere que los protocolos de handshake y registro compartan la misma conexión porque separarlos aumenta la superficie de ataque para ataques de hombre en el medio.

Una conexión mTLS tiene una seguridad de extremo a extremo consistente desde el inicio del handshake hasta el final. Los
datos cifrados se cifran con la clave de sesión negociada usando la clave pública en el
certificado. Solo el origen y el destino pueden descifrar los datos con la clave privada. En otras
palabras, solo el propietario del certificado que tiene la clave privada puede descifrar los datos. A menos que un
hacker tenga control de la clave privada del certificado, no tiene forma de jugar
con la conexión mTLS para ejecutar con éxito un ataque de hombre en el medio.

### ¿Qué pasa si la identidad del origen o destino no es criptográficamente segura?

Si la identidad se basa en propiedades de red como dirección IP, que podría reasignarse a
otros pods, la identidad no puede validarse usando técnicas criptográficas. Dado que este tipo de
identidad no se basa en identidad criptográfica, su sistema probablemente tiene un caché de identidad para rastrear
el mapeo entre la identidad, las etiquetas de red del pod, la dirección IP correspondiente y el
info del nodo Kubernetes donde se despliega el pod. Con un caché de identidad, podría encontrarse con direcciones IP de pod
siendo reutilizadas e identidad confundida donde la política no se aplica correctamente cuando el
caché de identidad está desincronizado por un corto período de tiempo. Por ejemplo, si no tiene identidad criptográfica
en la conexión entre los pares, su sistema tendría que obtener la identidad del
caché de identidad que podría estar desactualizado o incompleto.

Estos cachés de identidad que mapean identidad a IPs de carga de trabajo no son [ACID](https://en.wikipedia.org/wiki/ACID)
(Atomicidad, Consistencia, Aislamiento y Durabilidad) y usted quiere que su sistema de seguridad se aplique
a algo con garantías fuertes. Considere las siguientes propiedades y preguntas que puede querer
preguntarse:

- Obsolescencia: ¿Cómo puede un par verificar que una entrada en el caché está **actualizada**?
- Incompletitud: Si hay una pérdida de caché y el sistema no cierra la conexión, ¿se vuelve
la red inestable cuando solo el **sincronizador** de caché está fallando?
- ¿Qué pasa si algo simplemente no tiene una IP? Por ejemplo, un servicio AWS Lambda no tiene por
defecto una IP pública.
- No transaccional: Si lee la identidad dos veces, ¿verá el mismo valor? Si no es
cuidadoso en su implementación de política de acceso o auditoría, esto puede causar problemas reales.
- ¿Quién vigilará a los guardianes mismos? ¿Hay prácticas establecidas para proteger
el caché como lo tiene una CA? ¿Qué prueba tiene de que el caché no ha sido manipulado? ¿Está
forzado a razonar sobre (y auditar) la seguridad de alguna infraestructura compleja que no es su CA?

Algunos de los anteriores son peores que otros. Puede aplicar el principio **failing closed** pero eso no resuelve todos los anteriores.

Las identidades también se usan en la aplicación de políticas de acceso como política de autorización, y estas
políticas de acceso están en la ruta de solicitud donde su sistema tiene que tomar decisiones rápido para permitir o
denegar el acceso. Cuando las identidades se confunden, las políticas de acceso podrían eludirse sin
ser detectadas o auditadas. Por ejemplo, su caché de identidad puede tener la IP previamente
asignada de su pod `checkout` asociada como una de las identidades `checkout`. Si el pod `checkout` se
recicla y la misma dirección IP se acaba de asignar a uno de los pods `frontend`, ese pod `frontend` podría tener la identidad de `checkout` antes de que se actualice el caché, lo que podría causar que se apliquen políticas de acceso incorrectas.

Ilustremos el problema de obsolescencia del caché de identidad asumiendo el siguiente despliegue de multi-clúster a gran escala:

1. 100 clústeres donde cada clúster tiene 100 nodos con 20 pods por nodo. El número total de pods es 200,000.
1. El 0.25% de los pods están rotando en todo momento (rollout, reinicios, recuperación, rotación de nodos, ...), cada rotación es una ventana de 10 segundos.
1. 500 pods que están rotando se distribuyen a 10,000 nodos (cachés) cada 10 segs
1. Si el sincronizador de caché se estanca, ¿qué % obsoleto está el sistema después de 5 minutos - potencialmente ¡hasta **7.5%**!

Lo anterior asume que el sincronizador de caché está en estado estable. Si el sincronizador de caché tiene un apagón parcial, afectaría su comprobación de salud que aumenta la tasa de rotación, llevando a inestabilidad en cascada.

La CA también podría ser [comprometida](https://en.wikipedia.org/wiki/Certificate_authority#CA_compromise)
por un atacante que afirma presentar a otra persona y engañar a la CA para que emita un certificado. El
atacante entonces puede usar ese certificado para comunicarse con otros pares. Aquí es donde
la [revocación de certificado](https://en.wikipedia.org/wiki/Certificate_authority#Certificate_revocation) puede remediar la situación revocando el
certificado para que ya no sea válido. De lo contrario, el atacante puede explotar el certificado comprometido hasta su vencimiento. Es crítico mantener la clave privada para los certificados raíz en un HSM
que se mantiene [offline](https://en.wikipedia.org/wiki/Online_and_offline) y usar certificados
intermedios para firmar certificados de carga de trabajo. En el caso de que la CA tenga un apagón parcial o se estanque por 5
minutos, no podrá obtener certificados de carga de trabajo nuevos o renovados, pero los previamente emitidos
y certificados válidos continúan proporcionando garantías de identidad fuertes para sus cargas de trabajo. Para
mayor confiabilidad en la emisión, puede desplegar CAs intermedias en diferentes zonas y regiones.

## mTLS en Istio

### Habilitar mTLS

Habilitar mTLS en Istio para aplicaciones intra-malla es muy simple. Todo lo que necesita es agregar sus
aplicaciones a la malla, lo que puede hacerse etiquetando su namespace para inyección de sidecar
o ambient. En el caso del sidecar, se requeriría un rollout restart para que el sidecar sea inyectado
a los pods de su aplicación.

### Identidad criptográfica

En el entorno Kubernetes, [Istio](/docs/concepts/security/#istio-identity)
crea la identidad de una aplicación basándose en su cuenta de servicio. El certificado de identidad se proporciona a
cada pod de aplicación en la malla después de agregar su aplicación a la malla.

Por defecto, el certificado de identidad de su pod expira en 24 horas e Istio rota el
certificado de identidad del pod cada 12 horas para que en caso de compromiso (por ejemplo, CA comprometida o
clave privada robada para el pod), el certificado comprometido solo funcione por un período de tiempo muy limitado
hasta que expire el certificado y por lo tanto limite el
daño que puede causar.

### Aplicar mTLS estricto

El comportamiento predeterminado de mTLS es mTLS siempre que sea posible pero no estrictamente aplicado. Para aplicar estrictamente
que su aplicación acepte solo tráfico mTLS, puede usar la política de
[PeerAuthentication](/docs/reference/config/security/peer_authentication/) de Istio, para toda la malla o
por namespace o carga de trabajo. Además, también puede aplicar la
[AuthorizationPolicy](/docs/reference/config/security/authorization-policy/) de Istio para controlar el acceso a sus cargas de trabajo.

### Versión TLS

La versión TLS 1.3 es la predeterminada en Istio para la comunicación de aplicaciones intra-malla con los
[conjuntos de cifrado predeterminados](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/transport_sockets/tls/v3/common.proto) de Envoy
(por ejemplo `TLS_AES_256_GCM_SHA384` para Istio 1.19.0). Si necesita una versión TLS más antigua, puede
[configurar una versión mínima del protocolo TLS diferente para toda la malla](/docs/tasks/security/tls-configuration/workload-min-tls-version/) para sus cargas de trabajo.

## Conclusión

El protocolo TLS, establecido por el Internet Engineering Task Force (IETF), es uno de los protocolos de seguridad de datos más ampliamente revisados, aprobados por expertos y probados en batalla en existencia. TLS también es
ampliamente usado globalmente - cada vez que visita cualquier sitio web asegurado, compra con confianza en parte
debido al icono de candado para indicar que está conectado de forma segura a un sitio confiable
usando TLS. El protocolo TLS 1.3 fue diseñado con autenticación de extremo a extremo,
confidencialidad e integridad para asegurar que la identidad y comunicaciones de su aplicación no estén
comprometidas, y para prevenir ataques de hombre en el medio. Para lograrlo (y ser
considerado TLS compatible con estándares), no solo es importante autenticar correctamente a los
pares comunicantes sino también crítico cifrar el tráfico usando las claves establecidas del
handshake. Ahora que sabe que mTLS sobresale en satisfacer sus requisitos de comunicación de aplicaciones seguras
(identidades criptográficas, confidencialidad, integridad y aplicación de políticas de acceso),
puede simplemente usar Istio para actualizar su comunicación de aplicaciones intra-malla con mTLS de forma inmediata - ¡con muy poca configuración!

*Un gran agradecimiento a Louis Ryan, Ben Leggett, John Howard, Christian Posta, Justin Pettit quienes
contribuyeron con tiempo significativo en revisar y proponer actualizaciones al blog!*
