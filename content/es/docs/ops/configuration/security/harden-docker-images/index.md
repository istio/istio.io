---
title: Reforzar las imágenes de contenedor Docker
description: Usa imágenes de contenedor reforzadas para reducir la superficie de ataque de Istio.
weight: 80
aliases:
  - /help/ops/security/harden-docker-images
  - /docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
status: Beta
---

Las [imágenes por defecto](https://hub.docker.com/r/istio/base) de Istio se basan en `ubuntu` e incluyen algunas herramientas adicionales.
También hay disponible una imagen alternativa basada en [imágenes distroless](https://github.com/GoogleContainerTools/distroless).

Estas imágenes eliminan todos los ejecutables y bibliotecas no esenciales, lo que ofrece las siguientes ventajas:

- Se reduce la superficie de ataque, ya que incluyen el menor conjunto posible de vulnerabilidades.
- Las imágenes son más pequeñas, lo que permite un arranque más rápido.

Consulta también la sección [¿Por qué debería usar imágenes distroless?](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) del README oficial de distroless.

## Instalar imágenes distroless

Sigue los [pasos de instalación](/es/docs/setup/install/istioctl/) para configurar Istio.
Agrega la opción `variant` para usar las *imágenes distroless*.

{{< text bash >}}
$ istioctl install --set values.global.variant=distroless
{{< /text >}}

Si solo te interesa usar imágenes distroless para las imágenes de los proxies inyectados, también puedes usar el campo `image.imageType` de [Proxy Config](/es/docs/reference/config/networking/proxy-config/#ProxyImage).
Ten en cuenta que el flag `variant` anterior lo configura automáticamente por ti.

## Depuración

Las imágenes distroless no incluyen ninguna herramienta de depuración (¡ni siquiera un shell!).
Aunque esto es excelente para la seguridad, limita la posibilidad de hacer depuración ad hoc con `kubectl exec` en el contenedor del proxy.

Por suerte, los [contenedores efímeros](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) pueden ayudar en este caso.
`kubectl debug` puede adjuntar un contenedor temporal a un pod.
Si usas una imagen con herramientas adicionales, puedes depurar como antes:

{{< text shell >}}
$ kubectl debug --image istio/base --target istio-proxy -it app-65c6749c9d-t549t
Defaulting debug container name to debugger-cdftc.
If you don't see a command prompt, try pressing enter.
root@app-65c6749c9d-t549t:/# curl example.com
{{< /text >}}

Esto despliega un nuevo contenedor efímero con la imagen `istio/base`.
Es la misma imagen base que usan las imágenes de Istio que no son distroless, y contiene diversas herramientas útiles para depurar Istio.
Sin embargo, cualquier imagen sirve.
El contenedor también se adjunta al namespace de procesos del proxy sidecar (`--target istio-proxy`) y al namespace de red del pod.
