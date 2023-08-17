---
title: Custom CA Integration using Kubernetes CSR
description: Shows how to use a Custom Certificate Authority (that integrates with the Kubernetes CSR API) to provision Istio workload certificates.
weight: 100
keywords: [security,certificate]
aliases:
    - /docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

This feature requires Kubernetes version >= 1.18.

This task shows how to provision workload certificates
using a custom certificate authority that integrates with the
[Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/). Different workloads can get their certificates signed from different cert-signers. Each cert-signer is effectively a different CA. It is expected that workloads whose certificates are issued from the same cert-signer can talk mTLS to each other while workloads signed by different signers cannot.
This feature leverages [Chiron](/blog/2019/dns-cert/), a lightweight component linked with Istiod that signs certificates using the Kubernetes CSR API.

For this example, we use [open-source cert-manager](https://cert-manager.io).
Cert-manager has added [experimental Support for Kubernetes `CertificateSigningRequests`](https://cert-manager.io/docs/usage/kube-csr/) starting with version 1.4.

## Deploy custom CA controller in the Kubernetes cluster

1. Deploy cert-manager according to the [installation doc](https://cert-manager.io/docs/installation/).

    {{< warning >}}
    Make sure to enable feature gate: `--feature-gates=ExperimentalCertificateSigningRequestControllers=true`
    {{< /warning >}}

    {{< text bash >}}
    $ helm repo add jetstack https://charts.jetstack.io
    $ helm repo update
    $ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set featureGates="ExperimentalCertificateSigningRequestControllers=true" --set installCRDs=true
    {{< /text >}}

1. Create three self signed cluster issuers `istio-system`, `foo` and `bar` for cert-manager.
   Note: Namespace issuers and other types of issuers can also be used.

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

## Verify secrets are created for each cluster issuer

{{< text bash >}}
$ kubectl get secret -n cert-manager -l controller.cert-manager.io/fao=true
NAME                  TYPE                DATA   AGE
bar-ca-selfsigned     kubernetes.io/tls   3      3m36s
foo-ca-selfsigned     kubernetes.io/tls   3      3m36s
istio-ca-selfsigned   kubernetes.io/tls   3      3m38s
{{< /text >}}

## Export root certificates for each cluster issuer

{{< text bash >}}
$ export ISTIOCA=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export FOOCA=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
$ export BARCA=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
{{< /text >}}

## Deploy Istio with default cert-signer info

1. Deploy Istio on the cluster using `istioctl` with the following configuration. The `ISTIO_META_CERT_SIGNER` is the default cert-signer for workloads.

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

1. Create the `bar` and `foo` namespaces.

    {{< text bash >}}
    $ kubectl create ns bar
    $ kubectl create ns foo
    {{< /text >}}

1. Deploy the `proxyconfig-bar.yaml` in the `bar` namespace to define cert-signer for workloads in the `bar` namespace.

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

1. Deploy the `proxyconfig-foo.yaml` in the `foo` namespace to define cert-signer for workloads in the `foo` namespace.

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

1. Deploy the `httpbin` and `sleep` sample applications in the `foo` and `bar` namespaces.

    {{< text bash >}}
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl label ns bar istio-injection=enabled
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
    $ kubectl apply -f samples/sleep/sleep.yaml -n foo
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n bar
    {{< /text >}}

## Verify the network connectivity between `httpbin` and `sleep` within the same namespace

When the workloads are deployed, they send CSR requests with related signer info. Istiod forwards the CSR request to the custom CA for signing. The custom CA will use the correct cluster issuer to sign the cert back. Workloads under `foo` namespace will use `foo` cluster issuers while workloads under `bar` namespace will use the `bar` cluster issuers. To verify that they have indeed been signed by correct cluster issuers, we can verify workloads under the same namespace can communicate while workloads under the different namespace cannot communicate.

1. Set the `SLEEP_POD_FOO` environment variable to the name of `sleep` pod.

    {{< text bash >}}
    $ export SLEEP_POD_FOO=$(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Check network connectivity between service `sleep` and `httpbin` in the `foo` namespace.

    {{< text bash >}}
    $ kubectl exec "$SLEEP_POD_FOO" -n foo -c sleep -- curl http://httpbin.foo:8000/html
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

1. Check network connectivity between service `sleep` in the `foo` namespace and `httpbin` in the `bar` namespace.

    {{< text bash >}}
    $ kubectl exec "$SLEEP_POD_FOO" -n foo -c sleep -- curl http://httpbin.bar:8000/html
    upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
    {{< /text >}}

## Cleanup

* Remove the namespaces and uninstall Istio and cert-manager:

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ istioctl uninstall --purge -y
    $ helm delete -n cert-manager cert-manager
    $ kubectl delete ns istio-system cert-manager
    $ unset ISTIOCA FOOCA BARCA
    $ rm -rf istio.yaml proxyconfig-foo.yaml proxyconfig-bar.yaml selfsigned-issuer.yaml
    {{< /text >}}

## Reasons to use this feature

* Custom CA Integration - By specifying a Signer name in the Kubernetes CSR Request, this feature allows Istio to integrate with custom Certificate Authorities using the Kubernetes CSR API interface. This does require the custom CA to implement a Kubernetes controller to watch the `CertificateSigningRequest` Resources and act on them.

* Better multi-tenancy - By specifying a different cert-signer for different workloads, certificates for different tenant's workloads can be signed by different CAs.
