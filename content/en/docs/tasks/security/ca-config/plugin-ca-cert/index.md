---
title: Plugging in External CA Key and Certificate
description: Shows how operators can configure Citadel with existing root certificate, signing certificate and key.
weight: 10
keywords: [security,certificates]
aliases:
    - /docs/tasks/security/plugin-ca-cert/
---

This task shows how operators can configure Citadel with existing root certificate, signing certificate and key.

By default, Citadel generates self-signed root certificate and key, and uses them to sign the workload certificates.
Citadel can also use the operator-specified certificate and key to sign workload certificates, with
operator-specified root certificate. This task demonstrates an example to plug certificates and key into Citadel.

## Plugging in the existing certificate and key

Suppose we want to have Citadel use the existing signing (CA) certificate `ca-cert.pem` and key `ca-key.pem`.
Furthermore, the certificate `ca-cert.pem` is signed by the root certificate `root-cert.pem`.
We would like to use `root-cert.pem` as the root certificate for Istio workloads.

In the following example,
Citadel's signing (CA) certificate (`ca-cert.pem`) is different from root certificate (`root-cert.pem`),
so the workload cannot validate the workload certificates directly from the root certificate.
The workload needs a `cert-chain.pem` file to specify the chain of trust,
which should include the certificates of all the intermediate CAs between the workloads and the root CA.
In our example, it contains Citadel's signing certificate, so `cert-chain.pem` is the same as `ca-cert.pem`.
Note that if your `ca-cert.pem` is the same as `root-cert.pem`, the `cert-chain.pem` file should be empty.

These files are ready to use in the `samples/certs/` directory.

  {{< tip >}}
  The default Citadel installation sets [command line options](/docs/reference/commands/istio_ca/index.html) to configure the location of certificates and keys based on the predefined secret and file names used in the command below (i.e., secret named `cacert`, root certificate in a file named `root-cert.pem`, Citadel key in `ca-key.pem`, etc.)
  You must use these specific secret and file names, or reconfigure Citadel when you deploy it.
  {{< /tip >}}

The following steps plug in the certificates and key into a Kubernetes secret,
which will be read by Citadel:

1.  Create a secret `cacerts` including all the input files `ca-cert.pem`, `ca-key.pem`, `root-cert.pem` and `cert-chain.pem`:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem \
        --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem \
        --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1.  Deploy Citadel with `global.mtls.enabled` set to `true` and the `demo` profile.
    Citadel will read certificates and key from the secret-mount files.

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo --set values.global.mtls.enabled=true
    {{< /text >}}

## Verifying the certificates

In this section, we verify that the workload certificates signed by the root certificates plugged in.
This requires you have `openssl` installed on your machine.

1. Deploy the `httpbin` and `sleep` example applications.

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1.  Retrieve the certificate chain of `httpbin`.

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

    Open `httpbin-proxy-cert.txt` created in the above command and save the three certificates in it
    to `proxy-cert-0.pem`, `proxy-cert-1.pem`, and `proxy-cert-2.pem`, respectively.
    A certificate starts with `-----BEGIN CERTIFICATE-----` and ends with `-----END CERTIFICATE-----`.

1.  Verify the root certificate is the same as the one specified by operator:

    {{< text bash >}}
    $ openssl x509 -in @samples/certs/root-cert.pem@ -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    {{< /text >}}

    Expect the output to be empty.

1.  Verify the CA certificate is the same as the one specified by operator:

    {{< text bash >}}
    $ openssl x509 -in @samples/certs/ca-cert.pem@ -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-1.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    {{< /text >}}

    Expect the output to be empty.

1.  Verify the certificate chain from the root certificate to the workload certificate:

    {{< text bash >}}
    $ head -n 21 ./proxy-cert-0.pem > /tmp/pod-cert-chain-workload.pem
    $ openssl verify -CAfile <(cat @samples/certs/ca-cert.pem@ @samples/certs/root-cert.pem@) /tmp/pod-cert-chain-workload.pem
    /tmp/pod-cert-chain-workload.pem: OK
    {{< /text >}}

## Cleanup

*   To remove the secret `cacerts` and redeploy Citadel with self-signed root certificate:

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    $ istioctl manifest apply
    {{< /text >}}

*   To remove the Istio components: follow the [uninstall instructions](/docs/setup/getting-started/#uninstall) to remove.
