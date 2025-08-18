---
---
La revisión a la que apunta la etiqueta `default` se considera la ***revisión predeterminada*** y tiene un significado semántico adicional. La revisión predeterminada
realiza las siguientes funciones:

- Inyecta sidecars para el selector de namespace `istio-injection=enabled`, el selector de objetos `sidecar.istio.io/inject=true`
  y los selectores `istio.io/rev=default`
- Valida los recursos de Istio
- Roba el bloqueo de líder de las revisiones no predeterminadas y realiza responsabilidades de meshsingleton (como actualizar los estados de los recursos)

Para hacer que una revisión `{{< istio_full_version_revision >}}` sea la predeterminada, ejecuta:
