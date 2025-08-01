---
title: Si TLS mutuo está habilitado globalmente, ¿pueden los servicios que no son de Istio acceder a los servicios de Istio?
weight: 30
---
Cuando TLS mutuo `STRICT` está habilitado, los workloads que no son de Istio no pueden comunicarse con los servicios de Istio, ya que no tendrán un certificado de cliente de Istio válido.

Si necesita permitir estos clientes, el modo TLS mutuo se puede configurar en `PERMISSIVE`, lo que permite tanto texto sin formato como TLS mutuo.
Esto se puede hacer para workloads individuales o para toda la mesh.

Consulte [Política de autenticación](/es/docs/tasks/security/authentication/authn-policy) para obtener más detalles.
