---
title: Conectar Certificados de CA
description: Muestra cómo los administradores del sistema pueden configurar la CA de Istio con un certificado raíz, un certificado de firma y una clave.
weight: 80
keywords: [security,certificates]
aliases:
    - /docs/tasks/security/plugin-ca-cert/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo los administradores pueden configurar la autoridad de certificación (CA) de Istio con un certificado raíz,
un certificado de firma y una clave.

Por defecto, la CA de Istio genera un certificado raíz y una clave autofirmados y los utiliza para firmar los certificados de los workloads.
Para proteger la clave de la CA raíz, debe utilizar una CA raíz que se ejecute en una máquina segura sin conexión,
y utilizar la CA raíz para emitir certificados intermedios a las CA de Istio que se ejecutan en cada cluster.
Una CA de Istio puede firmar certificados de workloads utilizando el certificado y la clave especificados por el administrador, y distribuir un
certificado raíz especificado por el administrador a los workloads como la raíz de confianza.

El siguiente gráfico demuestra la jerarquía de CA recomendada en un mesh que contiene dos clusters.

{{< image width="50%"
    link="ca-hierarchy.svg"
    caption="Jerarquía de CA"
    >}}

Esta tarea demuestra cómo generar y conectar los certificados y la clave para la CA de Istio. Estos pasos se pueden repetir
para aprovisionar certificados y claves para las CA de Istio que se ejecutan en cada cluster.

## Conectar certificados y clave en el cluster

{{< warning >}}
Las siguientes instrucciones son solo para fines de demostración.
Para una configuración de cluster de producción, se recomienda encarecidamente utilizar una CA lista para producción, como
[Hashicorp Vault](https://www.hashicorp.com/products/vault).
Es una buena práctica gestionar la CA raíz en una máquina sin conexión con una fuerte
protección de seguridad.
{{< /warning >}}

{{< warning >}}
El soporte para firmas SHA-1 está [deshabilitado por defecto en Go 1.18](https://github.com/golang/go/issues/41682). Si está generando el certificado en macOS, asegúrese de que está utilizando OpenSSL como se describe en el [problema de GitHub 38049](https://github.com/istio/istio/issues/38049).
{{< /warning >}}

1.  En el directorio de nivel superior del paquete de instalación de Istio, cree un directorio para guardar los certificados y las claves:

    {{< text bash >}}
    $ mkdir -p certs
    $ pushd certs
    {{< /text >}}

1.  Genere el certificado raíz y la clave:

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk root-ca
    {{< /text >}}

    Esto generará los siguientes ficheros:

    * `root-cert.pem`: el certificado raíz generado
    * `root-key.pem`: la clave raíz generada
    * `root-ca.conf`: la configuración para `openssl` para generar el certificado raíz
    * `root-cert.csr`: el CSR generado para el certificado raíz

1.  Para cada cluster, genere un certificado intermedio y una clave para la CA de Istio.
    El siguiente es un ejemplo para `cluster1`:

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk cluster1-cacerts
    {{< /text >}}

    Esto generará los siguientes ficheros en un directorio llamado `cluster1`:

    * `ca-cert.pem`: los certificados intermedios generados
    * `ca-key.pem`: la clave intermedia generada
    * `cert-chain.pem`: la cadena de certificados generada que utiliza istiod
    * `root-cert.pem`: el certificado raíz

    Puede reemplazar `cluster1` con una cadena de su elección. Por ejemplo, con el argumento `cluster2-cacerts`,
    puede crear certificados y claves en un directorio llamado `cluster2`.

    Si está haciendo esto en una máquina sin conexión, copie el directorio generado a una máquina con acceso a los
    clusters.

1.  En cada cluster, cree un secreto `cacerts` que incluya todos los ficheros de entrada `ca-cert.pem`, `ca-key.pem`,
    `root-cert.pem` y `cert-chain.pem`. Por ejemplo, para `cluster1`:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
          --from-file=cluster1/ca-cert.pem \
          --from-file=cluster1/ca-key.pem \
          --from-file=cluster1/root-cert.pem \
          --from-file=cluster1/cert-chain.pem
    {{< /text >}}

1.  Vuelva al directorio de nivel superior de la instalación de Istio:

    {{< text bash >}}
    $ popd
    {{< /text >}}

## Desplegar Istio

1.  Despliegue Istio utilizando el perfil `demo`.

    La CA de Istio leerá los certificados y la clave de los ficheros montados en secreto.

    {{< text bash >}}
    $ istioctl install --set profile=demo
    {{< /text >}}

## Desplegar services de ejemplo

1. Despliegue los services de ejemplo `httpbin` y `curl`.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n foo
    {{< /text >}}

1. Despliegue una política para los workloads en el namespace `foo` para que solo acepten tráfico mTLS.

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: PeerAuthentication
    metadata:
      name: "default"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

## Verificación de los certificados

En esta sección, verificamos que los certificados de los workloads están firmados por los certificados que conectamos a la CA.
Esto requiere que tenga `openssl` instalado en su máquina.

1.  Espere 20 segundos para que la política mTLS surta efecto antes de recuperar la cadena de certificados
de `httpbin`. Como el certificado de CA utilizado en este ejemplo es autofirmado,
el error `verify error:num=19:self signed certificate in certificate chain` devuelto por el
comando openssl es esperado.

    {{< text bash >}}
    $ sleep 20; kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

1.  Analice los certificados en la cadena de certificados.

    {{< text bash >}}
    $ sed -n '/-----BEGIN CERTIFICATE-----/{:start /-----END CERTIFICATE-----/!{N;b start};/.*/p}' httpbin-proxy-cert.txt > certs.pem
    $ awk 'BEGIN {counter=0;} /BEGIN CERT/{counter++} { print > "proxy-cert-" counter ".pem"}' < certs.pem
    {{< /text >}}

1.  Verifique que el certificado raíz es el mismo que el especificado por el administrador:

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/root-cert.pem -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    Files /tmp/root-cert.crt.txt and /tmp/pod-root-cert.crt.txt are identical
    {{< /text >}}

1.  Verifique que el certificado de CA es el mismo que el especificado por el administrador:

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    Files /tmp/ca-cert.crt.txt and /tmp/pod-cert-chain-ca.crt.txt are identical
    {{< /text >}}

1.  Verifique la cadena de certificados desde el certificado raíz hasta el certificado del workload:

    {{< text bash >}}
    $ openssl verify -CAfile <(cat certs/cluster1/ca-cert.pem certs/cluster1/root-cert.pem) ./proxy-cert-1.pem
    ./proxy-cert-1.pem: OK
    {{< /text >}}

## Limpieza

*   Elimine los certificados, claves y ficheros intermedios de su disco local:

    {{< text bash >}}
    $ rm -rf certs
    {{< /text >}}

*   Elimine el secreto `cacerts`:

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    {{< /text >}}

*   Elimine la política de autenticación del namespace `foo`:

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    {{< /text >}}

*   Elimine las applications de ejemplo `curl` y `httpbin`:

    {{< text bash >}}
    $ kubectl delete -f samples/curl/curl.yaml -n foo
    $ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
    {{< /text >}}

*   Desinstale Istio del cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

*   Elimine el namespace `foo` y `istio-system` del cluster:

    {{< text bash >}}
    $ kubectl delete ns foo istio-system
    {{< /text >}}
