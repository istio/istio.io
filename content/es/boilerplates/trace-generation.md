---
---
Para ver los datos de seguimiento, debes enviar solicitudes a tu servicio. El número de solicitudes depende de la tasa de muestreo de Istio y se puede configurar mediante la [API de Telemetría](/es/docs/tasks/observability/telemetry/). Con la tasa de muestreo predeterminada del 1%, debes enviar al menos 100 solicitudes antes de que el primer seguimiento sea visible.
Para enviar 100 solicitudes al servicio `productpage`, usa el siguiente comando:

{{< text bash >}}
$ for i in $(seq 1 100); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done
{{< /text >}}
