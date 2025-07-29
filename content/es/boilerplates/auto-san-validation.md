---
---
{{< tip >}}
Istio tiene `auto_sni` y `auto_san_validation` habilitados de forma predeterminada. Esto significa que, siempre que no haya un `sni` explícito establecido en tu `DestinationRule`, el SNI del socket de transporte para las nuevas conexiones ascendentes se establecerá en función del encabezado host/autoridad HTTP descendente. Si no hay `subjectAltNames` establecidos en la `DestinationRule` cuando `sni` no está configurado, se activará `auto_san_validation` y el certificado presentado por el upstream para las nuevas conexiones ascendentes se validará automáticamente en función del encabezado host/autoridad HTTP descendente.
{{< /tip >}}
