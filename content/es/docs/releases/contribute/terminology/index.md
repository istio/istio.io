---
title: Estándares de terminología
description: Explica los estándares de terminología utilizados en la documentación de Istio.
weight: 12
aliases:
    - /docs/welcome/contribute/style-guide.html
    - /docs/reference/contribute/style-guide.html
    - /about/contribute/terminology
    - /latest/about/contribute/terminology
keywords: [contribute, documentation, guide, code-block]
owner: istio/wg-docs-maintainers
test: n/a
---

Para ofrecer claridad a nuestros usuarios, usa de forma consistente en la documentación
los términos estándar de esta sección.

## Service

Evita usar el término **service**. La investigación muestra que distintas personas
entienden cosas diferentes con ese término. La siguiente tabla muestra alternativas
aceptables que aportan mayor especificidad y claridad a los lectores:

|Haz                                         | No hagas
|--------------------------------------------|-----------------------------------------
| El Workload A envía una solicitud al Workload B.  | El Service A envía una solicitud al Service B.
| Las nuevas instancias de workload se inician cuando ...      | Las nuevas instancias de service se inician cuando ...
| La aplicación consta de dos workloads. | El service consta de dos services.

El glosario establece la terminología acordada y proporciona definiciones para
evitar confusiones.

## Envoy

Es preferible usar “Envoy” porque es un término más concreto que “proxy” y resulta más
claro si se utiliza de forma consistente en toda la documentación.

Sinónimos:

- "Envoy sidecar” - ok
- "Envoy proxy” - ok
- "The Istio proxy” -- mejor evitarlo salvo que estés hablando de escenarios avanzados
  donde podría usarse otro proxy.
- "Sidecar”  -- principalmente restringido a documentación conceptual
- "Proxy" -- solo si el contexto es obvio

Términos relacionados:

- Proxy agent  - Es un componente de infraestructura menor y solo debería aparecer
  en documentación de bajo nivel/detalle. No es un nombre propio.

## Miscellaneous

|Haz             | No hagas
|----------------|------
| addon          | `add-on`
| Bookinfo       | `BookInfo`, `bookinfo`
| certificado    | `cert`, `certificate`
| ubicar / ubicado | `co-locate`, `co-located`
| configuración  | `config`
| eliminar       | `kill`
| Kubernetes     | `kubernetes`, `k8s`
| balanceo de carga | `load-balancing`, `load balancing`
| Mixer          | `mixer`
| multiclúster   | `multi-cluster`
| TLS mutuo (mTLS) | `mtls`
| service mesh   | `Service Mesh`
| sidecar        | `side-car`, `Sidecar`
