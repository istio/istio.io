---
---
Cuando se utiliza la etiqueta `default` junto con una instalación de Istio existente sin revisión, se recomienda eliminar la
`MutatingWebhookConfiguration` antigua (normalmente llamada `istio-sidecar-injector`) para evitar que tanto el
plano de control antiguo como el más nuevo intenten la inyección.
