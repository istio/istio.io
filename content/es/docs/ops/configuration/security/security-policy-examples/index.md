---
title: Ejemplos de políticas de seguridad
description: Muestra ejemplos comunes del uso de las políticas de seguridad de Istio.
weight: 60
owner: istio/wg-security-maintainers
test: yes
---

## Contexto

Esta página muestra patrones comunes de uso de las políticas de seguridad de Istio. Pueden resultarte útiles en tu despliegue, o puedes usar esta página
como referencia rápida de políticas de ejemplo.

Las políticas que se muestran aquí son solo ejemplos y requieren cambios para adaptarlas a tu entorno real
antes de aplicarlas.

Lee también las tareas de [autenticación](/es/docs/tasks/security/authentication/authn-policy) y
[autorización](/es/docs/tasks/security/authorization) para seguir un tutorial práctico sobre el uso de la política de seguridad con
más detalle.

## Requerir un emisor de JWT distinto por host

La validación de JWT es habitual en el ingress gateway, y puede que quieras requerir emisores de JWT distintos para distintos
hosts. Puedes usar la política de autorización para una validación de JWT granular, además de la política de
[autenticación de solicitudes](/es/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

Usa la siguiente política si quieres permitir el acceso a los hosts indicados cuando el principal del JWT coincida. El acceso a otros hosts
siempre se denegará.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: jwt-per-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        # the JWT token must have issuer with suffix "@example.com"
        requestPrincipals: ["*@example.com"]
    to:
    - operation:
        hosts: ["example.com", "*.example.com"]
  - from:
    - source:
        # the JWT token must have issuer with suffix "@another.org"
        requestPrincipals: ["*@another.org"]
    to:
    - operation:
        hosts: [".another.org", "*.another.org"]
{{< /text >}}

## Aislamiento de namespaces

Las dos políticas siguientes habilitan mTLS estricto en el namespace `foo` y permiten el tráfico procedente del mismo namespace.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo-isolation
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
{{< /text >}}

## Aislamiento de namespaces con excepción para el ingress

Las dos políticas siguientes habilitan mTLS estricto en el namespace `foo` y permiten el tráfico procedente del mismo namespace y también
del ingress gateway.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}

## Requerir mTLS en la capa de autorización (defensa en profundidad) {#require-mtls-in-authorization-layer-defense-in-depth}

Configuraste `PeerAuthentication` en `STRICT`, pero quieres asegurarte de que el tráfico esté realmente protegido por mTLS con
una comprobación adicional en la capa de autorización, es decir, defensa en profundidad.

La siguiente política deniega la solicitud si el principal está vacío. El principal estará vacío si se usa texto plano.
En otras palabras, la política permite las solicitudes si el principal no está vacío.
`"*"` significa que coincide con cualquier valor no vacío y, usado con `notPrincipals`, significa que coincide con un principal vacío.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["*"]
{{< /text >}}

## Requerir una comprobación de autorización obligatoria con una política `DENY`

Puedes usar la política `DENY` si quieres requerir una comprobación de autorización obligatoria que deba cumplirse y que no se pueda
eludir con otra política `ALLOW` más permisiva. Esto funciona porque la política `DENY` tiene prioridad sobre la
política `ALLOW` y puede denegar una solicitud antes de que se evalúen las políticas `ALLOW`.

Usa la siguiente política para requerir una validación de JWT obligatoria, además de la política de [autenticación de solicitudes](/es/docs/tasks/security/authentication/authn-policy/#end-user-authentication).
La política deniega la solicitud si el principal de la solicitud está vacío. El principal de la solicitud estará vacío si falla la validación del JWT.
En otras palabras, la política permite las solicitudes si el principal de la solicitud no está vacío.
`"*"` significa que coincide con cualquier valor no vacío y, usado con `notRequestPrincipals`, significa que coincide con un principal de solicitud vacío.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
{{< /text >}}

Del mismo modo, usa la siguiente política para requerir el aislamiento obligatorio de namespaces y permitir también las solicitudes del ingress gateway.
La política deniega la solicitud si el namespace no es `foo` y el principal no es `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.
En otras palabras, la política solo permite la solicitud si el namespace es `foo` o si el principal es `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        notPrincipals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}
