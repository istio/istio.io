---
title: Istio Webhook Management [Experimental]
description: How to manage webhooks in Istio through istioctl.
weight: 100
keywords: [security,webhook]
---

{{< boilerplate experimental-feature-warning >}}

Istio has two webhooks: Galley and the sidecar injector. By default,
these webhooks manage their own configurations. From a
security perspective, this default behavior is not recommended because a compromised webhook could then conduct
privilege escalation attacks.

This task shows how to use the new [{{< istioctl >}} x post-install webhook](/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) command to
securely manage the configurations of the webhooks.

## Getting started

* Install Istio with [DNS certificates configured](/docs/tasks/security/dns-cert) and
`global.operatorManageWebhooks` set to `true`.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          operatorManageWebhooks: true
          certificates:
            - secretName: dns.istio-galley-service-account
              dnsNames: [istio-galley.istio-system.svc, istio-galley.istio-system]
            - secretName: dns.istio-sidecar-injector-service-account
              dnsNames: [istio-sidecar-injector.istio-system.svc, istio-sidecar-injector.istio-system]
    EOF
    $ istioctl manifest apply -f ./istio.yaml
    {{< /text >}}

* Install [`jq`](https://stedolan.github.io/jq/) for JSON parsing.

## Check webhook certificates

To display the DNS names in the webhook certificates of Galley and the sidecar injector, you need to get the secret
from Kubernetes, parse it, decode it, and view the text output with the following commands:

{{< text bash >}}
$ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
$ kubectl get secret dns.istio-sidecar-injector-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
{{< /text >}}

The output from the above commands should include the DNS names of Galley and the sidecar injector, respectively:

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-sidecar-injector.istio-system.svc, DNS:istio-sidecar-injector.istio-system
{{< /text >}}

## Enable webhook configurations

1.  To generate the `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration` configuration files, run the following
command.

    {{< text bash >}}
    $ istioctl manifest generate > istio.yaml
    {{< /text >}}

1.  Open the `istio.yaml` configuration file, search for `kind: MutatingWebhookConfiguration` and save
the `MutatingWebhookConfiguration` of the sidecar injector to `sidecar-injector-webhook.yaml`. The following
is a `MutatingWebhookConfiguration` in an example `istio.yaml`.

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: MutatingWebhookConfiguration
    metadata:
      name: istio-sidecar-injector
      labels:
        app: sidecarInjectorWebhook
        release: istio
    webhooks:
      - name: sidecar-injector.istio.io
        clientConfig:
          service:
            name: istio-sidecar-injector
            namespace: istio-system
            path: "/inject"
          caBundle: ""
        rules:
          - operations: [ "CREATE" ]
            apiGroups: [""]
            apiVersions: ["v1"]
            resources: ["pods"]
        failurePolicy: Fail
        namespaceSelector:
          matchLabels:
            istio-injection: enabled
    {{< /text >}}

1.  Open the `istio.yaml` configuration file, search for `kind: ValidatingWebhookConfiguration` and save
the `ValidatingWebhookConfiguration` of Galley to `galley-webhook.yaml`. The following
is a `ValidatingWebhookConfiguration` in an example `istio.yaml` (only
a part of the configuration is shown to save space).

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: ValidatingWebhookConfiguration
    metadata:
      name: istio-galley
      labels:
        app: galley
        release: istio
        istio: galley
    webhooks:
      - name: pilot.validation.istio.io
        clientConfig:
          service:
            name: istio-galley
            namespace: istio-system
            path: "/admitpilot"
          caBundle: ""
        rules:
          - operations:
            - CREATE
            - UPDATE
            apiGroups:
            - config.istio.io
            ... SKIPPED
        failurePolicy: Fail
        sideEffects: None
    {{< /text >}}

1.  Verify that there are no existing webhook configurations for Galley and the sidecar injector.
The output of the following two commands should not contain any configurations for
Galley and the sidecar injector.

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration
    $ kubectl get validatingwebhookconfiguration
    {{< /text >}}

1.  Use `istioctl` to enable the webhook configurations:

    {{< text bash >}}
    $ istioctl experimental post-install webhook enable --webhook-secret dns.istio-galley-service-account \
        --namespace istio-system --validation-path galley-webhook.yaml \
        --injection-path sidecar-injector-webhook.yaml
    {{< /text >}}

1.  To check that the sidecar injector webhook is working, verify that the webhook injects a
sidecar container into an example pod with the following commands:

    {{< text bash >}}
    $ kubectl create namespace test-injection
    $ kubectl label namespaces test-injection istio-injection=enabled
    $ kubectl run --generator=run-pod/v1 --image=nginx nginx-app --port=80 -n test-injection
    $ kubectl get pod -n test-injection
    {{< /text >}}

    The output from the `get pod` command should show the following. The `2/2` value means that
    the webhook injected a sidecar into the example pod:

    {{< text plain >}}
    NAME        READY   STATUS    RESTARTS   AGE
    nginx-app   2/2     Running   0          10s
    {{< /text >}}

1.  Check that the validation webhook is working:

    {{< text bash >}}
    $ kubectl create namespace test-validation
    $ kubectl apply -n test-validation -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: invalid-gateway
    spec:
      selector:
        # DO NOT CHANGE THESE LABELS
        # The ingressgateway is defined in install/kubernetes/helm/istio/values.yaml
        # with these labels
        istio: ingressgateway
    EOF
    {{< /text >}}

    The output from the gateway creation command should show the following output. The error
    in the output indicates that the validation webhook checked the gateway's configuration YAML file:

    {{< text plain >}}
    Error from server: error when creating "invalid-gateway.yaml": admission webhook "pilot.validation.istio.io" denied the request: configuration is invalid: gateway must have at least one server
    {{< /text >}}

## Show webhook configurations

1.  If you named the sidecar injector's configuration `istio-sidecar-injector` and
named Galley's configuration `istio-galley-istio-system`, use the following command
to show the configurations of these two webhooks:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --validation-config=istio-galley-istio-system  --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  If you named the sidecar injector's configuration `istio-sidecar-injector`,
use the following command to show the configuration of the sidecar injector:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  If you named Galley's configuration `istio-galley-istio-system`, show Galley's configuration with the following command:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --injection=false --validation-config=istio-galley-istio-system
    {{< /text >}}

## Disable webhook configurations

1.  If you named the sidecar injector's configuration `istio-sidecar-injector` and
    named Galley's configuration `istio-galley-istio-system`, use the following command
    to disable the configurations of these two webhooks:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --validation-config=istio-galley-istio-system  --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  If you named the sidecar injector's configuration `istio-sidecar-injector`,
disable the webhook with the following command:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  If you named Galleys's configuration `istio-galley-istio-system`, disable the webhook with the following command:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --injection=false --validation-config=istio-galley-istio-system
    {{< /text >}}

## Cleanup

You can run the following command to delete the resources created in this tutorial.

{{< text bash >}}
$ kubectl delete ns test-injection test-validation
{{< /text >}}