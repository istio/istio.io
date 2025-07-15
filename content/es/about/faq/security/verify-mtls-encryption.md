---
title: ¿Cómo puedo verificar que el tráfico utiliza el cifrado TLS mutuo?
weight: 25
---

Si instaló Istio con `values.global.proxy.privileged=true`, puede usar `tcpdump` para determinar el estado del cifrado. También en Kubernetes 1.23 y versiones posteriores, como alternativa a la instalación de Istio como privilegiado, puede usar `kubectl debug` para ejecutar `tcpdump` en un [contenedor efímero](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container). Consulte [Migración de TLS mutuo de Istio](/es/docs/tasks/security/authentication/mtls-migration) para obtener instrucciones.
