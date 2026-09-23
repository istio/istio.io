---
---
{{< warning >}}
La configuración predeterminada del chart utiliza los tokens seguros de terceros para las
proyecciones de tokens de la cuenta de servicio que utilizan los proxies de Istio para autenticarse con el
control plane de Istio. Antes de proceder a instalar cualquiera de los charts a continuación, debes
verificar si los tokens de terceros están habilitados en tu cluster siguiendo los pasos
descritos [aquí](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens).
Si los tokens de terceros no están habilitados, debes agregar la opción
`--set global.jwtPolicy=first-party-jwt` a los comandos de instalación de Helm.
Si la `jwtPolicy` no se establece correctamente, los pods asociados con `istiod`,
las gateways o los workloads con proxies de Envoy inyectados no se implementarán debido
a que falta el volumen `istio-token`.
{{< /warning >}}
