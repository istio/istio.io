---
title: Endpoints de depuración
description: Acceso a los endpoints de depuración de istiod para monitoreo y resolución de problemas.
weight: 30
keywords: [integration,debug,authentication,istiod]
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod expone endpoints de depuración (por ejemplo, `/debug/syncz`, `/debug/registryz`, `/debug/config_dump`) en múltiples puertos, que proporcionan información de monitoreo y estado útil para las integraciones.

## Puertos y protocolos

- **Puerto 15010**: endpoints de depuración de XDS mediante gRPC en texto plano (`syncz`, `config_dump`)
- **Puerto 15012**: endpoints de depuración de XDS mediante gRPC con TLS/mTLS (`syncz`, `config_dump`) - recomendado para producción
- **Puerto 15014**: endpoints de depuración HTTP (texto plano)

## Requisitos de autenticación

Los endpoints de depuración requieren autenticación mediante tokens de cuenta de servicio de Kubernetes o credenciales JWT válidas. El token debe tener la audiencia `istio-ca` (configurable mediante la variable de entorno `TOKEN_AUDIENCES` en istiod).

**Puerto 15010 (gRPC en texto plano):** Cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true`, los endpoints de depuración requieren autenticación. Dado que este puerto es en texto plano (sin TLS), la verificación de autenticación efectivamente bloquea el acceso a menos que se deshabilite. Usa el puerto 15012 en su lugar para acceso autenticado de depuración de XDS.

**Puerto 15012 (gRPC con TLS):** Los endpoints de depuración de XDS están disponibles a través del puerto TLS seguro. La autenticación se realiza automáticamente mediante validación de certificados mTLS.

**Puerto 15014 (HTTP):** Autenticación mediante token portador (bearer token) en el encabezado Authorization u omisión de la autenticación mediante localhost.

La autenticación se controla mediante `ENABLE_DEBUG_ENDPOINT_AUTH` (habilitada de forma predeterminada). Para deshabilitar la autenticación por completo y restaurar el comportamiento heredado en texto plano, establece `ENABLE_DEBUG_ENDPOINT_AUTH=false` en istiod. Ten en cuenta que deshabilitar la autenticación puede exponer información sensible del clúster.

## Control de acceso basado en namespace

Cuando la autenticación está habilitada:

- Las cuentas de servicio del **namespace del sistema** (típicamente `istio-system`) tienen acceso completo a todos los endpoints de depuración para todos los proxies en todos los namespaces.
- Las cuentas de servicio de **namespaces que no son del sistema** están restringidas a:
    - Solo endpoints específicos: `/debug/config_dump`, `/debug/ndsz`, `/debug/edsz`
    - Solo proxies del mismo namespace (no pueden ver proxies de otros namespaces)
- Para otorgar a namespaces adicionales el mismo acceso completo que el namespace del sistema, establece la variable de entorno `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` en istiod con una lista de namespaces separados por comas.
  {{< tip >}}
  `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` está disponible en Istio 1.29.1+, 1.28.5+ y 1.27.8+ (próximos lanzamientos de parches).
  {{< /tip >}}

## Métodos de acceso

**Mediante localhost (recomendado):**

La redirección de puertos (`port-forward`) hacia istiod evita la autenticación, ya que las solicitudes provienen de localhost. Así es como funciona istioctl, y es el enfoque recomendado para la mayoría de las integraciones:

{{< text bash >}}
$ kubectl port-forward -n istio-system deploy/istiod 15014:15014
$ curl http://localhost:15014/debug/syncz
{{< /text >}}

**Acceso directo por red (para herramientas dentro del clúster):**

Para herramientas que se ejecutan dentro del clúster (por ejemplo, Kiali, monitoreo personalizado) que acceden a istiod directamente a través de la red de servicios de Kubernetes, el token de cuenta de servicio debe:

- Tener la audiencia `istio-ca` (predeterminada)
- Provenir de un namespace autorizado (ya sea `istio-system` o uno listado en `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES`)
- Incluirse como token portador (bearer token) en el encabezado Authorization

{{< text bash >}}
$ TOKEN=$(kubectl create token my-sa --audience istio-ca -n my-namespace)
$ curl -H "Authorization: Bearer $TOKEN" https://istiod.istio-system:15014/debug/syncz
{{< /text >}}

{{< warning >}}
Los tokens de cuenta de servicio estándar dentro del clúster tienen la audiencia `https://kubernetes.default.svc.cluster.local` y no funcionarán para el acceso directo sin solicitar explícitamente la audiencia `istio-ca`.
{{< /warning >}}

## Ejemplo: Configurar el acceso de un namespace

Para permitir que una herramienta de monitoreo que se ejecuta en el namespace `monitoring` acceda a los endpoints de depuración, agrega el namespace a la configuración de istiod:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
spec:
  template:
    spec:
      containers:
      - name: discovery
        env:
        - name: DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES
          value: "monitoring,kiali-operator"
{{< /text >}}

Después de aplicar este cambio, las cuentas de servicio de los namespaces `monitoring` y `kiali-operator` tendrán el mismo nivel de acceso que las cuentas de servicio de `istio-system`.
