---
title: Versiones Soportadas
description: Las versiones de Istio soportadas actualmente.
weight: 35
aliases:
    - /about/supported-releases
    - /latest/about/supported-releases
owner: istio/wg-docs-maintainers
test: n/a
---

Esta página describe el estado, el calendario y la política de las versiones soportadas actualmente. Las versiones soportadas de Istio incluyen
las versiones que están dentro de la ventana de mantenimiento activo y reciben parches de seguridad y de corrección de errores. Las versiones de parche posteriores
de una versión menor no contienen cambios incompatibles con versiones anteriores.

- [Política de soporte](#support-policy)
- [Esquema de nomenclatura](#naming-scheme)
- [Desfase entre el control plane y el data plane](#control-planedata-plane-skew)
- [Estado de soporte de las versiones de Istio](#support-status-of-istio-releases)
- [Versiones soportadas sin vulnerabilidades y exposiciones comunes (CVEs) conocidas](#supported-releases-without-known-common-vulnerabilities-and-exposures-cves)
- [Versiones de Envoy soportadas](#supported-envoy-versions)

## Política de soporte {#support-policy}

Generamos nuevas compilaciones de Istio para cada commit. Aproximadamente una vez por trimestre, compilamos una versión menor y la sometemos a varias
pruebas adicionales, así como a la calificación de la versión. Publicamos versiones de parche para los problemas encontrados en las versiones menores.

Los distintos tipos de versiones representan diferentes niveles de calidad del producto y de asistencia por parte de la comunidad de Istio.
En este contexto, *soporte* significa que la comunidad generará versiones de parche para problemas críticos y ofrecerá asistencia
técnica. Por separado, terceros y partners pueden ofrecer soluciones de soporte a más largo plazo.

| Tipo              | Nivel de soporte                                                                                                                                | Calidad y uso recomendado                                                                                      |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| Compilación de desarrollo | Sin soporte                                                                                                                             | Peligrosa, puede no ser totalmente fiable. Útil para experimentar.                                             |
| Versión menor     | Soporte hasta 6 semanas después de la versión menor N+2 (p. ej., 1.11 tiene soporte hasta 6 semanas después de que se publique 1.13.0)           |
| Parche            | Igual que la versión menor correspondiente                                                                                                      | Se recomienda adoptar las versiones de parche tan pronto como estén disponibles para una versión determinada.  |
| Parche de seguridad | Igual que un parche, pero contiene una corrección de seguridad. A veces los parches de seguridad contienen código o correcciones adicionales además de las correcciones de seguridad. | Dada la naturaleza de las correcciones de seguridad, se recomienda **encarecidamente** adoptar los parches de seguridad tras su publicación. |

Puedes encontrar las versiones disponibles en la [página de versiones](https://github.com/istio/istio/releases),
y si te gusta la aventura, puedes obtener información sobre nuestras compilaciones de desarrollo en la [wiki de compilaciones de desarrollo](https://github.com/istio/istio/wiki/Dev%20Builds).
Puedes encontrar notas de versión generales de cada versión menor y de parche [aquí](/news).

## Esquema de nomenclatura {#naming-scheme}

Nuestro esquema de nomenclatura es el siguiente:

{{< text plain >}}
<major>.<minor>.<patch>
{{< /text >}}

donde `<minor>` aumenta con cada versión y `<patch>` cuenta el número de parches de la
versión `<minor>` actual. Un parche suele ser un cambio pequeño respecto a la versión `<minor>`.

## Desfase entre el control plane y el data plane {#control-planedata-plane-skew}

El control plane de Istio puede estar una versión por delante del data plane. Sin embargo, el data plane no puede estar por delante del control plane. Te recomendamos usar [revisiones](/es/docs/setup/upgrade/canary/) para que no haya ningún desfase.

Por ahora, la comunicación entre data planes es compatible entre todas las versiones; sin embargo, esto podría cambiar en el futuro.

## Estado de soporte de las versiones de Istio {#support-status-of-istio-releases}

{{< support_status_table >}}

## Versiones soportadas sin vulnerabilidades y exposiciones comunes (CVEs) conocidas {#supported-releases-without-known-common-vulnerabilities-and-exposures-cves}

{{< warning >}}
Istio no garantiza que las versiones menores que quedan fuera de la ventana de soporte tengan corregidas todas las CVEs conocidas.
Mantente actualizado y usa una versión soportada.
{{< /warning >}}

| Versiones menores | Versiones con parches sin CVEs conocidas |
|----------------|-------------------------------------|
| 1.31.x         | 1.31.2+                             |
| 1.30.x         | 1.30.6+                             |
| 1.29.x         | 1.29.9+                             |

## Versiones de Envoy soportadas {#supported-envoy-versions}

El data plane de Istio se basa en [Envoy](https://github.com/envoyproxy/envoy).

La relación entre las versiones de ambos proyectos:

| Versión de Istio | Rama de versión de Envoy |
|---------------|----------------------|
| 1.31.x        | release/v1.39        |
| 1.30.x        | release/v1.38        |
| 1.29.x        | release/v1.37        |
| 1.28.x        | release/v1.36        |

Puedes encontrar el commit exacto de Envoy que usa Istio [en el repositorio `istio/proxy`](https://github.com/istio/proxy/blob/{{< source_branch_name >}}/WORKSPACE#L26): busca la variable `ENVOY_SHA`.
