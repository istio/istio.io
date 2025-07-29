---
title: Integración de CA Personalizada usando Kubernetes CSR
description: Muestra cómo usar una Autoridad de Certificación Personalizada (que se integra con la API CSR de Kubernetes) para aprovisionar certificados de workload de Istio.
weight: 100
keywords: [security,certificate]
aliases:
    - /docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

Esta feature requiere Kubernetes versión >= 1.18.

Esta tarea muestra cómo aprovisionar certificados de workload
usando una autoridad de certificación personalizada que se integra con la
[API CSR de Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/). Diferentes workloads pueden obtener sus certificados firmados por diferentes firmantes de certificados. Cada firmante de certificados es efectivamente una CA diferente. Se espera que los workloads cuyos certificados son emitidos por el mismo firmante de certificados puedan comunicarse mTLS entre sí, mientras que los workloads firmados por diferentes firmantes no puedan.
Esta feature aprovecha [Chiron](/blog/2019/dns-cert/), un componente ligero vinculado con Istiod que firma certificados usando la API CSR de Kubernetes.

Para este ejemplo, usamos [cert-manager de código abierto](https://cert-manager.io).
Cert-manager ha agregado [soporte experimental para `CertificateSigningRequests` de Kubernetes](https://cert-manager.io/docs/usage/kube-csr/) a partir de la versión 1.4.

## Desplegar el controlador de CA personalizada en el cluster de Kubernetes

1. Despliegue cert-manager de acuerdo con la [documentación de instalación](https://cert-manager.io/docs/installation/).

    {{< warning >}}
    Asegúrese de habilitar la feature gate: `--feature-gates=ExperimentalCertificateSigningRequestControllers=true`
    {{< /warning >}}

    {{< text bash >}}
    $ helm repo add jetstack https://charts.jetstack.io
    $ helm repo update
    $ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set featureGates="ExperimentalCertificateSigningRequestControllers=true" --set installCRDs=true
    {{< /text >}}

1. Cree tres emisores de cluster autofirmados `istio-system`, `foo` y `bar` para cert-manager.
   Nota: También se pueden usar emisores de namespace y otros tipos de emisores.

    {{< text bash >}}
    $ cat <<EOF > ./selfsigned-issuer.yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-bar-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: bar-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: bar
      secretName: bar-ca-selfsigned
      issuerRef:
        name: selfsigned-bar-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: bar
    spec:
      ca:
        secretName: bar-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-foo-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: foo-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: foo
      secretName: foo-ca-selfsigned
      issuerRef:
        name: selfsigned-foo-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: foo
    spec:
      ca:
        secretName: foo-ca-selfsigned
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-istio-issuer
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: istio-ca
      namespace: cert-manager
    spec:
      isCA: true
      commonName: istio-system
      secretName: istio-ca-selfsigned
      issuerRef:
        name: selfsigned-istio-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: istio-system
    spec:
      ca:
        secretName: istio-ca-selfsigned
    EOF
    $ kubectl apply -f ./selfsigned-issuer.yaml
    {{< /text >}}

## Verificar que los secretos se crean para cada emisor de cluster

{{< text bash >}}
$ kubectl get secret -n cert-manager -l controller.cert-manager.io/fao=true
NAME                  TYPE                DATA   AGE
bar-ca-selfsigned     kubernetes.io/tls   3      3m36s
foo-ca-selfsigned     kubernetes.io/tls   3      3m36s
istio-ca-selfsigned   kubernetes.io/tls   3      3m38s
{{< /text >}}

## Exportar certificados raíz para cada emisor de cluster

{{< text bash >}}
$ export ISTIOCA=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export FOOCA=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export BARCA=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
{{< /text >}}

## Desplegar Istio con información de firmante de certificado predeterminada

1. Despliegue Istio en el cluster usando `istioctl` con la siguiente configuración. El `ISTIO_META_CERT_SIGNER` es el firmante de certificado predeterminado para los workloads.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        pilot:
          env:
            EXTERNAL_CA: ISTIOD_RA_KUBERNETES_API
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_META_CERT_SIGNER: istio-system
        caCertificates:
        - pem: |
    $ISTIOCA
          certSigners:
          - clusterissuers.cert-manager.io/istio-system
        - pem: |
    $FOOCA
          certSigners:
          - clusterissuers.cert-manager.io/foo
        - pem: |
    $BARCA
          certSigners:
          - clusterissuers.cert-manager.io/bar
      components:
        pilot:
          k8s:
            env:
            - name: CERT_SIGNER_DOMAIN
              value: clusterissuers.cert-manager.io
            - name: PILOT_CERT_PROVIDER
              value: k8s.io/clusterissuers.cert-manager.io/istio-system
            overlays:
              - kind: ClusterRole
                name: istiod-clusterrole-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      - clusterissuers.cert-manager.io/foo
                      - clusterissuers.cert-manager.io/bar
                      - clusterissuers.cert-manager.io/istio-system
                      resources:
                      - signers
                      verbs:
                      - approve
    EOF
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. Cree los namespaces `bar` y `foo`.

    {{< text bash >}}
    $ kubectl create ns bar
    $ kubectl create ns foo
    {{< /text >}}

1. Despliegue el `proxyconfig-bar.yaml` en el namespace `bar` para definir el firmante de certificado para los workloads en el namespace `bar`.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-bar.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: barpc
      namespace: bar
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: bar
    EOF
    $ kubectl apply  -f ./proxyconfig-bar.yaml
    {{< /text >}}

1. Despliegue el `proxyconfig-foo.yaml` en el namespace `foo` para definir el firmante de certificado para los workloads en el namespace `foo`.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-foo.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: foopc
      namespace: foo
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: foo
    EOF
    $ kubectl apply  -f ./proxyconfig-foo.yaml
    {{< /text >}}

1. Despliegue las applications de ejemplo `httpbin` y `curl` en los namespaces `foo` y `bar`.

    {{< text bash >}}
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl label ns bar istio-injection=enabled
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
    $ kubectl apply -f samples/curl/curl.yaml -n foo
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n bar
    {{< /text >}}

## Verificar la conectividad de red entre `httpbin` y `curl` dentro del mismo namespace

Cuando se despliegan los workloads, envían solicitudes CSR con la información del firmante relacionada. Istiod reenvía la solicitud CSR a la CA personalizada para su firma. La CA personalizada utilizará el emisor de cluster correcto para firmar el certificado. Los workloads bajo el namespace `foo` usarán los emisores de cluster `foo`, mientras que los workloads bajo el namespace `bar` usarán los emisores de cluster `bar`. Para verificar que realmente han sido firmados por los emisores de cluster correctos, podemos verificar que los workloads bajo el mismo namespace pueden comunicarse, mientras que los workloads bajo un namespace diferente no pueden comunicarse.

1. Establezca la variable de entorno `CURL_POD_FOO` con el nombre del pod `curl`.

    {{< text bash >}}
    $ export CURL_POD_FOO=$(kubectl get pod -n foo -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Verifique la conectividad de red entre el service `curl` y `httpbin` en el namespace `foo`.

    {{< text bash >}}
    $ kubectl exec "$CURL_POD_FOO" -n foo -c curl -- curl http://httpbin.foo:8000/html
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
          <h1>Herman Melville - Moby-Dick</h1>

          <div>
            <p>
              Availing himself of the mild...
            </p>
          </div>
      </body>
     {{< /text >}}

1. Verifique la conectividad de red entre el service `curl` en el namespace `foo` y `httpbin` en el namespace `bar`.

    {{< text bash >}}
    $ kubectl exec "$CURL_POD_FOO" -n foo -c curl -- curl http://httpbin.bar:8000/html
    upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
    {{< /text >}}

## Limpieza

* Elimine los namespaces y desinstale Istio y cert-manager:

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ istioctl uninstall --purge -y
    $ helm delete -n cert-manager cert-manager
    $ kubectl delete ns istio-system cert-manager
    $ unset ISTIOCA FOOCA BARCA
    $ rm -rf istio.yaml proxyconfig-foo.yaml proxyconfig-bar.yaml selfsigned-issuer.yaml
    {{< /text >}}

## Razones para usar esta feature

* Integración de CA personalizada: al especificar un nombre de firmante en la solicitud CSR de Kubernetes, esta feature permite a Istio integrarse con autoridades de certificación personalizadas utilizando la interfaz de la API CSR de Kubernetes. Esto requiere que la CA personalizada implemente un controlador de Kubernetes para observar los recursos `CertificateSigningRequest` y actuar sobre ellos.

* Mejor multi-tenencia: al especificar un firmante de certificado diferente para diferentes workloads, los certificados para los workloads de diferentes tenants pueden ser firmados por diferentes CAs.
