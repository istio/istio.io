---
title: Solución de problemas de conectividad de MySQL
description: Solución de problemas de conectividad de MySQL debido al modo PERMISSIVE.
weight: 95
keywords: [mysql,mtls]
---

Es posible que MySQL no se pueda conectar después de instalar Istio. Esto se debe a que MySQL es un protocolo [primero del servidor](/es/docs/ops/deployment/application-requirements/#server-first-protocols),
lo que puede interferir con la detección de protocolos de Istio. En particular, el uso del modo mTLS `PERMISSIVE` puede causar problemas.
Es posible que vea mensajes de error como `ERROR 2013 (HY000): Lost connection to MySQL server at
'reading initial communication packet', system error: 0`.

Esto se puede solucionar asegurándose de que se utilice el modo `STRICT` o `DISABLE`, o de que todos los clientes estén configurados
para enviar mTLS. Consulte [protocolos primero del servidor](/es/docs/ops/deployment/application-requirements/#server-first-protocols) para obtener más información.
