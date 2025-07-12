---
title: ¿Cómo puedo usar las comprobaciones de estado de liveness y readiness de Kubernetes para las comprobaciones de estado de los pods cuando TLS mutuo está habilitado?
weight: 50
---

Si TLS mutuo está habilitado, las comprobaciones de estado HTTP y TCP del kubelet no funcionarán sin modificaciones, ya que el kubelet no tiene certificados emitidos por Istio.

Hay varias opciones:

1.  Usar la reescritura de sondeo para redirigir las solicitudes de liveness y readiness a la
    workload directamente. Consulte [Reescritura de sondeo](/es/docs/ops/configuration/mesh/app-health-check/#probe-rewrite)
    para obtener más información. Esto está habilitado de forma predeterminada y se recomienda.

1.  Usar un puerto separado para las comprobaciones de estado y habilitar TLS mutuo solo en el puerto de servicio normal. Consulte [Comprobación de estado de los servicios de Istio](/es/docs/ops/configuration/mesh/app-health-check/#separate-port) para obtener más información.

1.  Usar el modo [`PERMISSIVE`](/es/docs/tasks/security/authentication/mtls-migration) para el workload, para que pueda aceptar tanto tráfico de texto sin formato como de TLS mutuo. Tenga en cuenta que TLS mutuo no se aplica con esta opción.
