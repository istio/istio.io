---
title: Problemas de seguridad
description: Técnicas para resolver problemas comunes de autenticación, autorización y seguridad en general en Istio.
force_inline_toc: true
weight: 20
keywords: [security,citadel]
aliases:
    - /help/ops/security/repairing-citadel
    - /help/ops/troubleshooting/repairing-citadel
    - /docs/ops/troubleshooting/repairing-citadel
owner: istio/wg-security-maintainers
test: n/a
---

## Falla la autenticación de usuarios finales {#end-user-authentication-fails}

Con Istio, puedes habilitar la autenticación de usuarios finales mediante [políticas de autenticación de solicitudes](/es/docs/tasks/security/authentication/authn-policy/#end-user-authentication). Sigue estos pasos para solucionar problemas con la especificación de la política.

1. Si `jwksUri` no está configurado, asegúrate de que el emisor del JWT tenga formato de URL y de que `url + /.well-known/openid-configuration` se pueda abrir en el navegador; por ejemplo, si el emisor del JWT es `https://accounts.google.com`, asegúrate de que `https://accounts.google.com/.well-known/openid-configuration` sea una URL válida y se pueda abrir en un navegador.

    {{< text yaml >}}
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: "example-3"
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    {{< /text >}}

1. Si el token JWT va en la cabecera Authorization de las solicitudes HTTP, asegúrate de que sea válido (que no haya expirado, etc.). Puedes decodificar los campos de un token JWT con herramientas en línea para analizar JWT, p. ej., [jwt.io](https://jwt.io/).

1. Verifica la configuración del proxy Envoy del workload de destino con el comando `istioctl proxy-config`.

    Con la política de ejemplo anterior aplicada, usa el siguiente comando para revisar la configuración de `listener` en el puerto de entrada `80`. Deberías ver el filtro `envoy.filters.http.jwt_authn` con ajustes que coinciden con el emisor y el JWKS especificados en la política.

    {{< text bash >}}
    $ POD=$(kubectl get pod -l app=httpbin -n foo -o jsonpath={.items..metadata.name})
    $ istioctl proxy-config listener ${POD} -n foo --port 80 --type HTTP -o json
    <redacted>
                                {
                                    "name": "envoy.filters.http.jwt_authn",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.config.filter.http.jwt_authn.v2alpha.JwtAuthentication",
                                        "providers": {
                                            "origins-0": {
                                                "issuer": "testing@secure.istio.io",
                                                "localJwks": {
                                                    "inlineString": "*redacted*"
                                                },
                                                "payloadInMetadata": "testing@secure.istio.io"
                                            }
                                        },
                                        "rules": [
                                            {
                                                "match": {
                                                    "prefix": "/"
                                                },
                                                "requires": {
                                                    "requiresAny": {
                                                        "requirements": [
                                                            {
                                                                "providerName": "origins-0"
                                                            },
                                                            {
                                                                "allowMissing": {}
                                                            }
                                                        ]
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                },
    <redacted>
    {{< /text >}}

## La autorización es demasiado restrictiva o permisiva {#authorization-is-too-restrictive-or-permissive}

### Asegúrate de que no haya errores tipográficos en el archivo YAML de la política {#make-sure-there-are-no-typos-in-the-policy-yaml-file}

Un error común es especificar varios elementos sin querer en el YAML. Toma como ejemplo la siguiente política:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: example
  namespace: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths:
        - /foo
  - from:
    - source:
        namespaces:
        - foo
{{< /text >}}

Podrías esperar que la política permita solicitudes si la ruta es `/foo` **y** el namespace de origen es `foo`.
Sin embargo, la política en realidad permite solicitudes si la ruta es `/foo` **o** el namespace de origen es `foo`, lo cual es
más permisivo.

En la sintaxis YAML, el `-` delante de `from:` significa que es un nuevo elemento de la lista. Esto crea 2 reglas en la
política en lugar de 1. En una política de autorización, varias reglas tienen la semántica de `OR`.

Para solucionar el problema, simplemente elimina el `-` sobrante para que la política tenga solo 1 regla que permita solicitudes si la
ruta es `/foo` **y** el namespace de origen es `foo`, lo cual es más restrictivo.

### Asegúrate de NO usar campos exclusivos de HTTP en puertos TCP {#make-sure-you-are-not-using-http-only-fields-on-tcp-ports}

La política de autorización será más restrictiva porque los campos exclusivos de HTTP (p. ej., `host`, `path`, `headers`, JWT, etc.)
no existen en las conexiones TCP sin procesar.

En el caso de una política `ALLOW`, estos campos nunca coinciden. En el caso de las acciones `DENY` y `CUSTOM`, se considera que estos campos
siempre coinciden. El efecto final es una política más restrictiva que podría causar denegaciones inesperadas.

Revisa la definición del servicio de Kubernetes para verificar que el puerto esté [nombrado correctamente con el protocolo adecuado](/es/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).
Si usas campos exclusivos de HTTP en el puerto, asegúrate de que el nombre del puerto tenga el prefijo `http-`.

### Asegúrate de que la política se aplique al destino correcto {#make-sure-the-policy-is-applied-to-the-correct-target}

Revisa el selector de workloads y el namespace para confirmar que se aplica a los destinos correctos. Puedes determinar la
política de autorización vigente ejecutando `istioctl x authz check POD-NAME.POD-NAMESPACE`.

### Presta atención a la acción especificada en la política {#pay-attention-to-the-action-specified-in-the-policy}

- Si no se especifica, la política usa la acción `ALLOW` de forma predeterminada.

- Cuando un workload tiene varias acciones (`CUSTOM`, `ALLOW` y `DENY`) aplicadas al mismo tiempo, todas las acciones deben
  cumplirse para permitir una solicitud. En otras palabras, una solicitud se deniega si cualquiera de las acciones la deniega, y solo se permite si
  todas las acciones la permiten.

- La acción `AUDIT` no aplica control de acceso y no denegará la solicitud en ningún caso.

Lee [habilitación implícita de la autorización](/es/docs/concepts/security/#implicit-enablement) para obtener más detalles sobre el orden de evaluación.

## Asegúrate de que Istiod acepte las políticas {#ensure-istiod-accepts-the-policies}

Istiod convierte y distribuye tus políticas de autorización a los proxies. Los siguientes pasos te ayudan
a asegurarte de que Istiod funcione como se espera:

1. Ejecuta el siguiente comando para habilitar el registro de depuración en istiod:

    {{< text bash >}}
    $ istioctl admin log --level authorization:debug
    {{< /text >}}

1. Obtén los registros de Istiod con el siguiente comando:

    {{< tip >}}
    Probablemente necesites eliminar primero y luego volver a aplicar tus políticas de autorización para que
    se genere la salida de depuración de estas políticas.
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system
    {{< /text >}}

1. Revisa la salida y verifica que no haya errores. Por ejemplo, podrías ver algo similar a lo siguiente:

    {{< text plain >}}
    2021-04-23T20:53:29.507314Z info ads Push debounce stable[31] 1: 100.981865ms since last change, 100.981653ms since last push, full=true
    2021-04-23T20:53:29.507641Z info ads XDS: Pushing:2021-04-23T20:53:29Z/23 Services:15 ConnectedEndpoints:2  Version:2021-04-23T20:53:29Z/23
    2021-04-23T20:53:29.507911Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508077Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508128Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
    2021-04-23T20:53:29.508158Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509097Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509167Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509501Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509652Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on TCP filter chain successfully
        * built 1 TCP filters for DENY action
        * added 1 TCP filters to filter chain 2
        * added 1 TCP filters to filter chain 3
        * added 1 TCP filters to filter chain 4
    2021-04-23T20:53:29.510903Z info ads LDS: PUSH for node:curl-557747455f-6dxbl.foo resources:18 size:85.0kB
    2021-04-23T20:53:29.511487Z info ads LDS: PUSH for node:httpbin-74fb669cc6-lpscm.foo resources:18 size:86.4kB
    {{< /text >}}

    Esto muestra que Istiod generó:

    - Una configuración de filtro HTTP con la política `ns[foo]-policy[deny-path-headers]-rule[0]` para el workload `httpbin-74fb669cc6-lpscm.foo`.

    - Una configuración de filtro TCP con la política `ns[foo]-policy[deny-path-headers]-rule[0]` para el workload `httpbin-74fb669cc6-lpscm.foo`.

## Asegúrate de que Istiod distribuya las políticas a los proxies correctamente {#ensure-istiod-distributes-policies-to-proxies-correctly}

Istiod distribuye las políticas de autorización a los proxies. Los siguientes pasos te ayudan a asegurarte de que istiod funcione como se espera:

{{< tip >}}
El comando siguiente asume que desplegaste `httpbin`; debes reemplazar `"-l app=httpbin"` por tu pod real si
no usas `httpbin`.
{{< /tip >}}

1. Ejecuta el siguiente comando para obtener el volcado de la configuración del proxy del workload `httpbin`:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. Revisa el registro y verifica que:

    - El registro incluye un filtro `envoy.filters.http.rbac` para aplicar la política de autorización en cada solicitud entrante.
    - Istio actualiza el filtro en consecuencia después de que actualizas tu política de autorización.

1. La siguiente salida significa que el proxy de `httpbin` ha habilitado el filtro `envoy.filters.http.rbac` con reglas que impiden
   que cualquiera acceda a la ruta `/headers`.

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "typed_config": {
      "@type": "type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC",
      "rules": {
       "action": "DENY",
       "policies": {
        "ns[foo]-policy[deny-path-headers]-rule[0]": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "url_path": {
                  "path": {
                   "exact": "/headers"
                  }
                 }
                }
               ]
              }
             }
            ]
           }
          }
         ],
         "principals": [
          {
           "and_ids": {
            "ids": [
             {
              "any": true
             }
            ]
           }
          }
         ]
        }
       }
      },
      "shadow_rules_stat_prefix": "istio_dry_run_allow_"
     }
    },
    {{< /text >}}

## Asegúrate de que los proxies apliquen las políticas correctamente {#ensure-proxies-enforce-policies-correctly}

En última instancia, son los proxies los que aplican las políticas de autorización. Los siguientes pasos te ayudan a asegurarte de que el proxy funcione como se espera:

{{< tip >}}
El comando siguiente asume que desplegaste `httpbin`; debes reemplazar `"-l app=httpbin"` por tu pod real si
no usas `httpbin`.
{{< /tip >}}

1. Activa el registro de depuración de autorización en el proxy con el siguiente comando:

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin --level "rbac:debug"
    {{< /text >}}

1. Verifica que veas la siguiente salida:

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. Envía algunas solicitudes al workload `httpbin` para generar registros.

1. Imprime los registros del proxy con el siguiente comando:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. Revisa la salida y verifica que:

    - El registro de salida muestra `enforced allowed` o `enforced denied`, según si la solicitud
      se permitió o se denegó, respectivamente.

    - Tu política de autorización espera los datos extraídos de la solicitud.

1. El siguiente es un ejemplo de salida para una solicitud a la ruta `/httpbin`:

    {{< text plain >}}
    ...
    2021-04-23T20:43:18.552857Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:46180, directRemoteIP: 10.44.3.13:46180, remoteIP: 10.44.3.13:46180,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/curl, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', '672c9166-738c-4865-b541-128259cc65e5'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '8a124905edf4291a21df326729b264e9'
    'x-b3-spanid', '21df326729b264e9'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/curl'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
      }
    }

    2021-04-23T20:43:18.552910Z debug envoy rbac enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    ...
    {{< /text >}}

    El registro `enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` significa que la solicitud fue rechazada por
    la política `ns[foo]-policy[deny-path-headers]-rule[0]`.

1. El siguiente es un ejemplo de salida para una política de autorización en [modo dry-run](/es/docs/tasks/security/authorization/authz-dry-run):

    {{< text plain >}}
    ...
    2021-04-23T20:59:11.838468Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:49826, directRemoteIP: 10.44.3.13:49826, remoteIP: 10.44.3.13:49826,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/curl, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e7b2fdb0-d2ea-4782-987c-7845939e6313'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '696607fc4382b50017c1f7017054c751'
    'x-b3-spanid', '17c1f7017054c751'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/curl'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
      }
    }

    2021-04-23T20:59:11.838529Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    2021-04-23T20:59:11.838538Z debug envoy rbac no engine, allowed by default
    ...
    {{< /text >}}

    El registro `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` significa que la solicitud sería rechazada
    por la política **dry-run** `ns[foo]-policy[deny-path-headers]-rule[0]`.

    El registro `no engine, allowed by default` significa que la solicitud en realidad se permite porque la política dry-run es la
    única política en el workload.

## Errores de claves y certificados {#keys-and-certificates-errors}

Si sospechas que algunas de las claves o de los certificados que usa Istio no son correctos, puedes inspeccionar su contenido desde cualquier pod:

{{< text bash >}}
$ istioctl proxy-config secret curl-8f795f47d-4s4t7
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           138092480869518152837211547060273851586     2020-11-11T16:39:48Z     2020-11-10T16:39:48Z
ROOTCA            CA             ACTIVE     true           288553090258624301170355571152070165215     2030-11-08T16:34:52Z     2020-11-10T16:34:52Z
{{< /text >}}

Si pasas la opción `-o json`, puedes enviar el contenido completo del certificado a `openssl` para analizarlo:

{{< text bash >}}
$ istioctl proxy-config secret curl-8f795f47d-4s4t7 -o json | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            99:59:6b:a2:5a:f4:20:f4:03:d7:f0:bc:59:f5:d8:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jun  4 20:38:20 2018 GMT
            Not After : Sep  2 20:38:20 2018 GMT
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
...
{{< /text >}}

Asegúrate de que el certificado mostrado contenga información válida. En particular, el campo `Subject Alternative Name` debe ser `URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`.

## Errores de TLS mutuo {#mutual-tls-errors}

Si sospechas que hay problemas con TLS mutuo, primero asegúrate de que istiod esté en buen estado y,
en segundo lugar, de que [las claves y los certificados se estén entregando](#keys-and-certificates-errors) correctamente a los sidecars.

Si todo parece funcionar hasta aquí, el siguiente paso es verificar que se aplique la [política de autenticación](/es/docs/tasks/security/authentication/authn-policy/) correcta
y que estén configuradas las destination rules correctas.

Si sospechas que el sidecar del lado del cliente puede estar enviando tráfico con TLS mutuo o en texto plano de forma incorrecta, revisa el
[dashboard Workload de Grafana](/es/docs/ops/integrations/grafana/). Las solicitudes salientes indican si se usa mTLS
 o no. Si después de revisarlo crees que los sidecars del cliente no se comportan como deberían, reporta un issue en GitHub.
