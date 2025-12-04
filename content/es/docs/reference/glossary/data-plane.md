---
title: data plane
test: n/a
---

El data plane es la parte de la mesh que maneja y enruta directamente el tráfico entre instancias de workload.

En modo {{< gloss >}}sidecar{{< /gloss >}}, el data plane de Istio usa proxies [Envoy](/es/docs/reference/glossary/#envoy) desplegados como sidecars para mediar y controlar todo el tráfico que los servicios de tu meshenvían y reciben.

En modo {{< gloss >}}ambient{{< /gloss >}}, el data plane de Istio usa proxies {{< gloss >}}ztunnel{{< /gloss >}} a nivel de nodo desplegados como un DaemonSet para mediar y controlar todo el tráfico que los servicios de tu meshenvían y reciben.
