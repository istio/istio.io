---
title: ¿Por qué no funciona mi configuración de CORS?
weight: 40
---

Después de aplicar la [configuración de CORS](/es/docs/reference/config/networking/virtual-service/#CorsPolicy), es posible que descubra que aparentemente no sucedió nada y se pregunte qué salió mal.
CORS es un concepto HTTP comúnmente mal entendido que a menudo genera confusión al configurar.

Para entender esto, es útil dar un paso atrás y ver [qué es CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) y cuándo debe usarse.
De forma predeterminada, los navegadores tienen restricciones sobre las solicitudes de "origen cruzado" iniciadas por scripts.
Esto evita, por ejemplo, que un sitio web `attack.example.com` realice una solicitud de JavaScript a `bank.example.com` y robe la información confidencial de un usuario.

Para permitir esta solicitud, `bank.example.com` debe permitir que `attack.example.com` realice solicitudes de origen cruzado.
Aquí es donde entra en juego CORS. Si estuviéramos sirviendo `bank.example.com` en un cluster habilitado para Istio, podríamos configurar una `corsPolicy` para permitir esto:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: bank
spec:
  hosts:
  - bank.example.com
  http:
  - corsPolicy:
      allowOrigins:
      - exact: https://attack.example.com
...
{{< /text >}}

En este caso, permitimos explícitamente un único origen; los comodines son comunes para las páginas no confidenciales.

Una vez que hacemos esto, un error común es enviar una solicitud como `curl bank.example.com -H "Origin: https://attack.example.com"`, y esperar que la solicitud sea rechazada.
Sin embargo, curl y muchos otros clientes no verán una solicitud rechazada, porque CORS es una restricción del navegador.
La configuración de CORS simplemente agrega encabezados `Access-Control-*` en la respuesta; depende del cliente (navegador) rechazar la solicitud si la respuesta no es satisfactoria.
En los navegadores, esto se hace mediante una [solicitud de verificación previa](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests).
