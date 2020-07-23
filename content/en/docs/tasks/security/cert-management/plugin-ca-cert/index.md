---
title: Plugging in existing CA Certificates
description: Shows how system administrators can configure Istio's CA with an existing root certificate, signing certificate and key.
weight: 80
keywords: [security,certificates]
aliases:
    - /docs/tasks/security/plugin-ca-cert/
owner: istio/wg-security-maintainers
test: yes
---

This task shows how administrators can configure the Istio certificate authority with an existing root certificate, signing certificate and key.

By default, Istio's CA generates a self-signed root certificate and key, and uses them to sign the workload certificates.
Istio's CA can also sign workload certificates using an administrator-specified certificate and key, and with an
administrator-specified root certificate. This task demonstrates how to plug such certificates and key into Istio's CA.

## Plugging in existing certificates and key

Suppose we want to have Istio's CA use an existing signing (CA) certificate `ca-cert.pem` and key `ca-key.pem`.
Furthermore, the certificate `ca-cert.pem` is signed by the root certificate `root-cert.pem`.
We would like to use `root-cert.pem` as the root certificate for Istio workloads.

In the following example,
Istio CA's signing (CA) certificate (`ca-cert.pem`) is different from the root certificate (`root-cert.pem`),
so the workload cannot validate the workload certificates directly from the root certificate.
The workload needs a `cert-chain.pem` file to specify the chain of trust,
which should include the certificates of all the intermediate CAs between the workloads and the root CA.
In our example, it contains Istio CA's signing certificate, so `cert-chain.pem` is the same as `ca-cert.pem`.
Note that if your `ca-cert.pem` is the same as `root-cert.pem`, the `cert-chain.pem` file should be empty.

These files are ready to use in the `samples/certs/` directory.

{{< tip >}}
The default Istio CA installation configures the location of certificates and keys based on the
predefined secret and file names used in the command below (i.e., secret named `cacerts`, root certificate
in a file named `root-cert.pem`, Istio CA's key in `ca-key.pem`, etc.).
You must use these specific secret and file names, or reconfigure Istio's CA when you deploy Istio.
{{< /tip >}}

The following steps plug in the certificates and key into a Kubernetes secret,
which will be read by Istio's CA:

1.  Create a secret `cacerts` including all the input files `ca-cert.pem`, `ca-key.pem`, `root-cert.pem` and `cert-chain.pem`:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem \
        --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem \
        --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1.  Deploy Istio using the `demo` profile.

    Istio's CA will read certificates and key from the secret-mount files.

    {{< text bash >}}
    $ istioctl install --set profile=demo
    {{< /text >}}

## Deploying example services

1. Deploy the `httpbin` and `sleep` sample services.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1. Deploy a policy for workloads in the `foo` namespace to only accept mutual TLS traffic.

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "PeerAuthentication"
    metadata:
      name: "default"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

## Verifying the certificates

In this section, we verify that workload certificates are signed by the certificates that we plugged into the CA.
This requires you have `openssl` installed on your machine.

1.  Sleep 20 seconds for the mTLS policy to take effect before retrieving the certificate chain
of `httpbin`. As the CA certificate used in this example is self-signed,
the `verify error:num=19:self signed certificate in certificate chain` error returned by the
openssl command is expected.

    {{< text bash >}}
    $ sleep 20; kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

1.  Parse the certificates on the certificate chain.

    {{< text bash >}}
    $ sed -n '/-----BEGIN CERTIFICATE-----/{:start /-----END CERTIFICATE-----/!{N;b start};/.*/p}' httpbin-proxy-cert.txt > certs.pem
    $ awk 'BEGIN {counter=0;} /BEGIN CERT/{counter++} { print > "proxy-cert-" counter ".pem"}' < certs.pem
    {{< /text >}}

1.  Verify the root certificate is the same as the one specified by the administrator:

    {{< text bash >}}
    $ openssl x509 -in samples/certs/root-cert.pem -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    Files /tmp/root-cert.crt.txt and /tmp/pod-root-cert.crt.txt are identical
    {{< /text >}}

1.  Verify the CA certificate is the same as the one specified by the administrator:

    {{< text bash >}}
    $ openssl x509 -in samples/certs/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    Files /tmp/ca-cert.crt.txt and /tmp/pod-cert-chain-ca.crt.txt are identical
    {{< /text >}}

1.  Verify the certificate chain from the root certificate to the workload certificate:

    {{< text bash >}}
    $ openssl verify -CAfile <(cat samples/certs/ca-cert.pem samples/certs/root-cert.pem) ./proxy-cert-1.pem
    ./proxy-cert-1.pem: OK
    {{< /text >}}

## Cleanup

*   To remove the secret `cacerts`, and the `foo` and `istio-system` namespaces:

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    $ kubectl delete ns foo istio-system
    {{< /text >}}

*   To remove the Istio components: follow the [uninstall instructions](/docs/setup/getting-started/#uninstall) to remove.
