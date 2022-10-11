---
title: SPIRE
description: How to configure Istio to integrate with SPIRE to get cryptographic identities through Envoy's SDS API.
weight: 31
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: no
---

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) is a production-ready implementation of the SPIFFE specification that performs node and workload attestation in order to securely
issue cryptographic identities to workloads running in heterogeneous environments. SPIRE can be configured as a source of cryptographic identities for Istio workloads through an integration with
[Envoy's SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret). Istio can detect the existence of a UNIX Domain Socket that implements the Envoy SDS API on a defined
socket path, allowing Envoy to communicate and fetch identities directly from it.

This integration with SPIRE provides flexible attestation options not available with the default Istio identity management while harnessing Istio's powerful service management.
For example, SPIRE's plugin architecture enables diverse workload attestation options beyond the Kubernetes namespace and service account attestation offered by Istio.
SPIRE's node attestation extends attestation to the physical or virtual hardware on which workloads run.

For a quick demo of how this SPIRE integration with Istio works, see [Integrating SPIRE as a CA through Envoy's SDS API]({{< github_tree >}}/samples/security/spire).

{{< warning >}}
Note that this integration requires version 1.14 for both `istioctl` and the data plane.
{{< /warning >}}

The integration is compatible with Istio upgrades.

## Install SPIRE

### Option 1: Quick start

Istio provides a basic sample installation to quickly get SPIRE up and running:

{{< text bash >}}
$ kubectl apply -f @samples/security/spire/spire-quickstart.yaml@
{{< /text >}}

This will deploy SPIRE into your cluster, along with two additional components: the [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi) — used to share the SPIRE Agent's UNIX Domain Socket with the other
pods throughout the node — and the [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar), a facilitator that performs automatic workload registration
within Kubernetes. See [Install Istio](#install-istio) to configure Istio and integrate with the SPIFFE CSI Driver.

### Option 2: Configure a custom SPIRE installation

See the [SPIRE's Quick start for Kubernetes guide](https://spiffe.io/docs/latest/try/getting-started-k8s/)
to get started deploying SPIRE into your Kubernetes environment. See [SPIRE CA Integration Prerequisites](#spire-ca-integration-prerequisites)
for more information on configuring SPIRE to integrate with Istio deployments.

#### SPIRE CA Integration Prerequisites

To integrate your SPIRE deployment with Istio, configure SPIRE:

1. Access the [SPIRE Agent reference](https://spiffe.io/docs/latest/deploying/spire_agent/#agent-configuration-file) and
    configure the SPIRE Agent socket path to match the Envoy SDS defined socket path.

    {{< text plain >}}
    socket_path = "/run/secrets/workload-spiffe-uds/socket"
    {{< /text >}}

1. Share the SPIRE Agent socket with the pods within the node by deploying the
    [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi).

See [Install Istio](#install-istio) to configure Istio to integrate with the SPIFFE CSI Driver.

{{< warning >}}
Note that you must deploy SPIRE before installing Istio into your environment so that Istio can detect it as a CA.
{{< /warning >}}

## Install Istio

1. [Download Istio release 1.14+](/docs/setup/getting-started/#download).

1. After [deploying SPIRE](#install-spire) into your environment, and verifying that all deployments are in `Ready` state,
    install Istio with custom patches for the Ingress-gateway as well as for istio-proxy.

    {{< text bash >}}
    $ istioctl install --skip-confirmation -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      profile: default
      meshConfig:
        trustDomain: example.org
      values:
        global:
        # This is used to customize the sidecar template
        sidecarInjectorWebhook:
          templates:
            spire: |
              spec:
                containers:
                - name: istio-proxy
                  volumeMounts:
                  - name: workload-socket
                    mountPath: /run/secrets/workload-spiffe-uds
                    readOnly: true
                volumes:
                  - name: workload-socket
                    csi:
                      driver: "csi.spiffe.io"
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            label:
              istio: ingressgateway
            k8s:
              overlays:
                - apiVersion: apps/v1
                  kind: Deployment
                  name: istio-ingressgateway
                  patches:
                    - path: spec.template.spec.volumes.[name:workload-socket]
                      value:
                        name: workload-socket
                        csi:
                          driver: "csi.spiffe.io"
                    - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                      value:
                        name: workload-socket
                        mountPath: "/run/secrets/workload-spiffe-uds"
                        readOnly: true
    EOF
    {{< /text >}}

    This will share the `spiffe-csi-driver` with the Ingress Gateway and the sidecars that are going to be injected on workload pods,
    granting them access to the SPIRE Agent's UNIX Domain Socket.

1. Use [sidecar injection](/docs/setup/additional-setup/sidecar-injection) to inject the `istio-proxy`
    container into the pods within your mesh. See [custom templates](/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental)
    for information on how to apply the custom defined `spire` template into `istio-proxy`. This allows for the CSI driver to mount the UDS on the sidecars.

    Check Ingress-gateway pod state:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   0/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

Data plane containers will only reach `Ready` if a corresponding registration entry is created for them on the SPIRE Server. Then,
Envoy will be able to fetch cryptographic identities from SPIRE.
See [Register workloads](#register-workloads) to register entries for services in your mesh.

## Register workloads

This section describes the options available for registering workloads in a SPIRE Server.

### Option 1: Automatic registration using the SPIRE workload registrar

By deploying [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar)
along with a SPIRE Server, new entries are automatically registered for each new pod that is created.

See [Verifying that identities were created for workloads](#verifying-that-identities-were-created-for-workloads)
to check issued identities.

Note that `SPIRE workload registrar` is used in the [quick start](#option-1:-quick-start) section.

### Option 2: Manual Registration

To improve workload attestation security robustness, SPIRE is able to verify against a group of selector values based on different parameters. Skip these steps if you installed `SPIRE` by following the [quick start](#option-1:-quick-start) since it uses automatic registration.

1. Generate an entry for an Ingress Gateway with a set of selectors such as the
    pod name and pod UID:

    {{< text bash >}}
    $ INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
    $ INGRESS_POD_UID=$(kubectl get pods -n istio-system $INGRESS_POD -o jsonpath='{.metadata.uid}')
    {{< /text >}}

1. Get the spire-server pod:

    {{< text bash >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l app=spire-server -n spire -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Register an entry for the SPIRE Agent running on the node:

    {{< text bash >}}
    $ kubectl exec -n spire $SPIRE_SERVER_POD -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s_psat:cluster:demo-cluster \
        -selector k8s_psat:agent_ns:spire \
        -selector k8s_psat:agent_sa:spire-agent \
        -node -socketPath /run/spire/sockets/server.sock

    Entry ID         : d38c88d0-7d7a-4957-933c-361a0a3b039c
    SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Parent ID        : spiffe://example.org/spire/server
    Revision         : 0
    TTL              : default
    Selector         : k8s_psat:agent_ns:spire
    Selector         : k8s_psat:agent_sa:spire-agent
    Selector         : k8s_psat:cluster:demo-cluster
    {{< /text >}}

1. Register an entry for the Ingress-gateway pod:

    {{< text bash >}}
    $ kubectl exec -n spire $SPIRE_SERVER_POD -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:sa:istio-ingressgateway-service-account \
        -selector k8s:ns:istio-system \
        -selector k8s:pod-uid:$INGRESS_POD_UID \
        -dns $INGRESS_POD \
        -dns istio-ingressgateway.istio-system.svc \
        -socketPath /run/spire/sockets/server.sock

    Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
    SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
    Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Revision         : 0
    TTL              : default
    Selector         : k8s:ns:istio-system
    Selector         : k8s:pod-uid:63c2bbf5-a8b1-4b1f-ad64-f62ad2a69807
    Selector         : k8s:sa:istio-ingressgateway-service-account
    DNS name         : istio-ingressgateway.istio-system.svc
    DNS name         : istio-ingressgateway-5b45864fd4-lgrxs
    {{< /text >}}

1. Deploy an example workload:

    {{< text bash >}}
    $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    Note that the workload will need the SPIFFE CSI Driver volume to access the SPIRE Agent socket. To accomplish this,
    you can leverage the `spire` pod annotation template from the [Install Istio](#install-istio) section or add the CSI volume to
    the deployment spec of your workload. Both of these alternatives are highlighted on the example snippet below:

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: sleep
    spec:
    replicas: 1
    selector:
        matchLabels:
        app: sleep
    template:
        metadata:
        labels:
            app: sleep
        # Injects custom sidecar template
        annotations:
            inject.istio.io/templates: "sidecar,spire"
        spec:
        terminationGracePeriodSeconds: 0
        serviceAccountName: sleep
        containers:
        - name: sleep
            image: curlimages/curl
            command: ["/bin/sleep", "3650d"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: tmp
            mountPath: /tmp
            securityContext:
            runAsUser: 1000
        volumes:
        - name: tmp
            emptyDir: {}
        # CSI volume
        - name: workload-socket
            csi:
            driver: "csi.spiffe.io"
    {{< /text >}}

1. Get pod information:

    {{< text bash >}}
    $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
    $ SLEEP_POD_UID=$(kubectl get pods $SLEEP_POD -o jsonpath='{.metadata.uid}')
    {{< /text >}}

1. Register the workload:

    {{< text bash >}}
    $ kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/sleep \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-uid:$SLEEP_POD_UID \
        -dns $SLEEP_POD \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

{{< warning >}}
SPIFFE IDs for workloads must follow the Istio SPIFFE ID pattern: `spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

See the [SPIRE help on Registering workloads](https://spiffe.io/docs/latest/deploying/registering/) to learn how to create new entries for workloads and get them attested using multiple selectors to strengthen attestation criteria.

## Verifying that identities were created for workloads

Use the following command to confirm that identities were created for the workloads:

{{< text bash >}}
$ kubectl exec -i -t $SPIRE_SERVER_POD -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -socketPath /run/spire/sockets/server.sock"
Found 3 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:istio-system
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d
Selector         : k8s:sa:istio-ingressgateway-service-account
DNS name         : istio-ingressgateway-5b45864fd4-lgrxs

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
DNS name         : sleep-5f4d47c948-njvpk

Entry ID         : f0544fd7-1945-4bd1-88dc-0a5513fdae1c
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_psat:agent_ns:spire
Selector         : k8s_psat:agent_sa:spire-agent
Selector         : k8s_psat:cluster:demo-cluster
{{< /text >}}

Check the Ingress-gateway pod state:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
{{< /text >}}

After registering an entry for the Ingress-gateway pod, Envoy receives the identity issued by SPIRE and uses it for all TLS and mTLS communications.

### Check that the workload identity was issued by SPIRE

1. Retrieve sleep's SVID identity document using the istioctl proxy-config secret command:

    {{< text bash >}}
    $ istioctl proxy-config secret $SLEEP_POD -o json | jq -r \
    '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
    {{< /text >}}

1. Inspect the certificate and verify that SPIRE was the issuer:

    {{< text bash >}}
    $ openssl x509 -in chain.pem -text | grep SPIRE
        Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
    {{< /text >}}

## SPIFFE Federation

SPIRE Servers are able to authenticate SPIFFE identities originating from different trust domains. This is known as SPIFFE federation.

SPIRE Agent can be configured to push federated bundles to Envoy through the Envoy SDS API, allowing Envoy to use [validation context](https://spiffe.io/docs/latest/microservices/envoy/#validation-context)
to verify peer certificates and trust a workload from another trust domain.
To enable Istio to federate SPIFFE identities through SPIRE integration, consult [SPIRE Agent SDS configuration](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration) and set the following
SDS configuration values for your SPIRE Agent configuration file.

| Configuration              | Description                                                                                      | Resource Name |
|----------------------------|--------------------------------------------------------------------------------------------------|---------------|
| `default_svid_name`        | The TLS Certificate resource name to use for the default `X509-SVID` with Envoy SDS              | default       |
| `default_bundle_name`      | The Validation Context resource name to use for the default X.509 bundle with Envoy SDS          | null          |
| `default_all_bundles_name` | The Validation Context resource name to use for all bundles (including federated) with Envoy SDS | ROOTCA        |

This will allow Envoy to get federated bundles directly from SPIRE.

### Create federated registration entries

* If using the SPIRE Kubernetes Workload Registrar, create federated entries for workloads by adding the pod annotation `spiffe.io/federatesWith` to the service deployment spec,
    specifying the trust domain you want the pod to federate with:

    {{< text yaml >}}
    podAnnotations:
      spiffe.io/federatesWith: "<trust.domain>"
    {{< /text >}}

* For manual registration see [Create Registration Entries for Federation](https://spiffe.io/docs/latest/architecture/federation/readme/#create-registration-entries-for-federation).

## Cleanup SPIRE

If you installed SPIRE using the quick start SPIRE deployment provided by Istio,
use the following commands to remove those Kubernetes resources:

{{< text bash >}}
$ kubectl delete CustomResourceDefinition spiffeids.spiffeid.spiffe.io
$ kubectl delete -n spire serviceaccount spire-agent
$ kubectl delete -n spire configmap spire-agent
$ kubectl delete -n spire deployment spire-agent
$ kubectl delete csidriver csi.spiffe.io
$ kubectl delete -n spire configmap spire-server
$ kubectl delete -n spire service spire-server
$ kubectl delete -n spire serviceaccount spire-server
$ kubectl delete -n spire statefulset spire-server
$ kubectl delete clusterrole spire-server-trust-role spire-agent-cluster-role
$ kubectl delete clusterrolebinding spire-server-trust-role-binding spire-agent-cluster-role-binding
$ kubectl delete namespace spire
{{< /text >}}
