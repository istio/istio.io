---
title: Istio Webhook Management [Experimental]
description: Shows how to manage webhooks in Istio through istioctl.
weight: 100
keywords: [security,webhook]
---

{{< boilerplate experimental-feature-warning >}}

Istio has two webhooks: Galley and Sidecar Injector. By default,
Galley and Sidecar Injector manage their own webhook configurations, which from the
security perspective is not recommended because a compromised webhook may conduct
privilege escalation attacks.

This task shows how to use `istioctl`, instead of Galley and Sidecar Injector, to
manage the webhook configurations of Galley and Sidecar Injector.

## Before you begin

* Create a Kubernetes cluster with Istio installed. In the installation,
[`global.operatorManageWebhooks`]({{< github_file >}}/install/kubernetes/helm/istio/values.yaml) should
be set to `true`, and [DNS certificates should be configured](/docs/tasks/security/dns-cert).
Istio installation guides can be found [here](/docs/setup/install).

* Install [`jq`](https://stedolan.github.io/jq/) for JSON parsing.

## Check webhook certificates

To display the DNS names in the webhook certificates of Galley and Sidecar Injector, run the following commands:

{{< text bash >}}
$ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
$ kubectl get secret dns.istio-sidecar-injector-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
{{< /text >}}

The output from the above commands should include the DNS names of Galley and Sidecar Injector, respectively:

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-sidecar-injector.istio-system.svc, DNS:istio-sidecar-injector.istio-system
{{< /text >}}

## Enable webhook configurations

1.  Generate `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration` by running the following
command. The YAML file [`values-istio-dns-cert.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml)
contains an example DNS certificate configuration (details in [the certificate guide](/docs/tasks/security/dns-cert)).
The following command uses the default Istio configuration plus the DNS certificate configuration in `values-istio-dns-cert.yaml`.
The document of the helm template command can be found in the [link](https://helm.sh/docs/helm/#helm-template).

    {{< text bash >}}
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --values install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml \
        install/kubernetes/helm/istio > istio-webhook-config.yaml
    {{< /text >}}

<!-- TODO (lei-tang): improve the UX for obtain MutatingWebhookConfiguration -->
1.  Open the `istio-webhook-config.yaml` configuration file, search `'kind: MutatingWebhookConfiguration'` and save
the `MutatingWebhookConfiguration` of Sidecar Injector to `sidecar-injector-webhook.yaml`. The following
is a `MutatingWebhookConfiguration` in an example `istio-webhook-config.yaml`.

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: MutatingWebhookConfiguration
    metadata:
      name: istio-sidecar-injector
      labels:
        app: sidecarInjectorWebhook
        chart: sidecarInjectorWebhook
        heritage: Tiller
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

<!-- TODO (lei-tang): improve the UX for obtain ValidatingWebhookConfiguration -->
1.  Open the `istio-webhook-config.yaml` configuration file, search `'kind: ValidatingWebhookConfiguration'` and save
the `ValidatingWebhookConfiguration` of Galley to `galley-webhook.yaml`. The following
is a `ValidatingWebhookConfiguration` in an example `istio-webhook-config.yaml` (only
a part of the configuration is shown to save space).

    {{< text yaml >}}
    apiVersion: admissionregistration.k8s.io/v1beta1
    kind: ValidatingWebhookConfiguration
    metadata:
      name: istio-galley
      labels:
        app: galley
        chart: galley
        heritage: Tiller
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

1.  Enable webhook configurations through `istioctl`:

    {{< text bash >}}
    $ istioctl experimental post-install webhook enable --validation --webhook-secret dns.istio-galley-service-account \
        --namespace istio-system --validation-path galley-webhook.yaml \
        --injection-path sidecar-injector-webhook.yaml
    {{< /text >}}

1.  Check the Sidecar Injector webhook is working by verifying that Sidecar Injector injects a
sidecar container into an example pod:

    {{< text bash >}}
    $ kubectl create namespace test-injection; kubectl label namespaces test-injection istio-injection=enabled
    $ kubectl run --generator=run-pod/v1 --image=nginx nginx-app --port=80 -n test-injection
    $ kubectl get pod -n test-injection
    {{< /text >}}

    The output from the `get pod` command should show the following output (`2/2` means that
    the Sidecar Injector webhook injected a sidecar into the example pod):

    {{< text plain >}}
    NAME    READY   STATUS    RESTARTS   AGE
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

    The output from the gateway creation command should show the following output (the error
    in the output indicates that the validation webhook checked the gateway YAML file):

    {{< text plain >}}
    Error from server: error when creating "invalid-gateway.yaml": admission webhook "pilot.validation.istio.io" denied the request: configuration is invalid: gateway must have at least one server
    {{< /text >}}

## Show webhook configurations

1.  Show the configurations of Galley and Sidecar Injector with their default webhook configuration names:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status
    {{< /text >}}

1.  Show the configuration of Sidecar Injector with the webhook configuration name being `istio-sidecar-injector`:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  Show the configuration of Galley with the webhook configuration name being `istio-galley`:

    {{< text bash >}}
    $ istioctl experimental post-install webhook status --injection=false --validation-config=istio-galley
    {{< /text >}}

## Disable webhook configurations

1.  Disable the configurations of Galley and Sidecar Injector with their default webhook configuration names:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable
    {{< /text >}}

1.  Disable the configuration of Sidecar Injector with the webhook configuration name being `istio-sidecar-injector`:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --validation=false --injection-config=istio-sidecar-injector
    {{< /text >}}

1.  Disable the configuration of Galley with the webhook configuration name being `istio-galley`:

    {{< text bash >}}
    $ istioctl experimental post-install webhook disable --injection=false --validation-config=istio-galley
    {{< /text >}}

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial. You may also run the following command to delete
the resources created.

{{< text bash >}}
$ kubectl delete ns test-injection test-validation
{{< /text >}}