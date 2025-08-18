---
---
Reetiquetar manualmente los namespaces al moverlos a una nueva revisión puede ser tedioso y propenso a errores.
Las [etiquetas de revisión](/es/docs/reference/commands/istioctl/#istioctl-tag) resuelven este problema.
Las [etiquetas de revisión](/es/docs/reference/commands/istioctl/#istioctl-tag) son identificadores estables que apuntan a revisiones y se pueden usar para evitar reetiquetar namespaces. En lugar de reetiquetar el namespace, un operador de mesh puede simplemente cambiar la etiqueta para que apunte a una nueva revisión. Todos los namespaces etiquetados con esa etiqueta se actualizarán al mismo tiempo.
