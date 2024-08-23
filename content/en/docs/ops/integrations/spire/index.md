---
title: SPIRE
description: How to configure Istio to integrate with SPIRE to get cryptographic identities through Envoy's SDS API.
weight: 31
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: yes
---

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) is a production-ready implementation of the SPIFFE specification that performs node and workload attestation in order to securely
issue cryptographic identities to workloads running in heterogeneous environments. SPIRE can be configured as a source of cryptographic identities for Istio workloads through an integration with
[Envoy's SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret). Istio can detect the existence of a UNIX Domain Socket that implements the Envoy SDS API on a defined
socket path, allowing Envoy to communicate and fetch identities directly from it.

This integration with SPIRE provides flexible attestation options not available with the default Istio identity management while harnessing Istio's powerful service management.
For example, SPIRE's plugin architecture enables diverse workload attestation options beyond the Kubernetes namespace and service account attestation offered by Istio.
SPIRE's node attestation extends attestation to the physical or virtual hardware on which workloads run.

For a quick demo of how this SPIRE integration with Istio works, see [Integrating SPIRE as a CA through Envoy's SDS API]({{< github_tree >}}/samples/security/spire).

## Install SPIRE

We recommend you follow SPIRE's installation instructions and best practices for installing SPIRE, and for deploying SPIRE in production environments.

For the examples in this guide, the [SPIRE Helm charts](https://artifacthub.io/packages/helm/spiffe/spire) will be used with upstream defaults, to focus on just the configuration necessary to integrate SPIRE and Istio.

{{< text syntax=bash snip_id=install_spire_crds >}}
$ helm upgrade --install -n spire-server spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace
{{< /text >}}

{{< text syntax=bash snip_id=install_spire_istio_overrides >}}
$ helm upgrade --install -n spire-server spire spire --repo https://spiffe.github.io/helm-charts-hardened/ --wait --set global.spire.trustDomain="example.org"
{{< /text >}}

{{< tip >}}
See the [SPIRE Helm chart](https://artifacthub.io/packages/helm/spiffe/spire) documentation for other values you can configure for your installation.

It is important that SPIRE and Istio are configured with the exact same trust domain, to prevent authentication and authorization errors, and that the [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi) is enabled and installed.
{{< /tip >}}

By default, the above will also install:

- The [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi), which is used to mount an Envoy-compatible SDS socket into proxies. Using the SPIFFE CSI driver to mount SDS sockets is strongly recommended by both Istio and SPIRE, as `hostMounts` are a larger security risk and introduce operational hurdles. This guide assumes the use of the SPIFFE CSI driver.

- The [SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager), which eases the creation of SPIFFE registrations for workloads.

## Register workloads

By design, SPIRE only grants identities to workloads that have been registered with the SPIRE server; this includes user workloads, as well as Istio components. Istio sidecars and gateways, once configured for SPIRE integration, cannot get identities, and therefore cannot reach READY status, unless there is a preexisting, matching SPIRE registration created for them ahead of time.

See the [SPIRE docs on registering workloads](https://spiffe.io/docs/latest/deploying/registering/) for more information on using multiple selectors to strengthen attestation criteria, and the selectors available.

This section describes the options available for registering Istio workloads in a SPIRE Server and provides some example workload registrations.

{{< warning >}}
Istio currently requires a specific SPIFFE ID format for workloads. All registrations must follow the Istio SPIFFE ID pattern: `spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

### Option 1: Auto-registration using the SPIRE Controller Manager

New entries will be automatically registered for each new pod that matches the selector defined in a [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) custom resource.

Both Istio sidecars and Istio gateways need to be registered with SPIRE, so that they can request identities.

#### Istio Gateway `ClusterSPIFFEID`

The following will create a `ClusterSPIFFEID`, which will auto-register any Istio Ingress gateway pod with SPIRE if it is scheduled into the `istio-system` namespace, and has a service account named `istio-ingressgateway-service-account`. These selectors are used as a simple example; consult the [SPIRE Controller Manager documentation](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) for more details.

{{< text syntax=bash snip_id=spire_csid_istio_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-ingressgateway-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  workloadSelectorTemplates:
    - "k8s:ns:istio-system"
    - "k8s:sa:istio-ingressgateway-service-account"
EOF
{{< /text >}}

#### Istio Sidecar `ClusterSPIFFEID`

The following will create a `ClusterSPIFFEID` which will auto-register any pod with the `spiffe.io/spire-managed-identity: true` label that is deployed into the `default` namespace with SPIRE. These selectors are used as a simple example; consult the [SPIRE Controller Manager documentation](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) for more details.

{{< text syntax=bash snip_id=spire_csid_istio_sidecar >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-sidecar-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels:
      spiffe.io/spire-managed-identity: "true"
  workloadSelectorTemplates:
    - "k8s:ns:default"
EOF
{{< /text >}}

### Option 2: Manual Registration

If you wish to manually create your SPIRE registrations, rather than use the SPIRE Controller Manager mentioned in [the recommended option](#option-1-auto-registration-using-the-spire-controller-manager), refer to the [SPIRE documentation on manual registration](https://spiffe.io/docs/latest/deploying/registering/).

Below are the equivalent manual registrations based off the automatic registrations in [Option 1](#option-1-auto-registration-using-the-spire-controller-manager). The following steps assume you have [already followed the SPIRE documentation to manually register your SPIRE agent and node attestation](https://spiffe.io/docs/latest/deploying/registering/#1-defining-the-spiffe-id-of-the-agent) and that your SPIRE agent was registered with the SPIFFE identity `spiffe://example.org/ns/spire/sa/spire-agent`.

1. Get the `spire-server` pod:

    {{< text syntax=bash snip_id=set_spire_server_pod_name_var >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l statefulset.kubernetes.io/pod-name=spire-server-0 -n spire-server -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Register an entry for the Istio Ingress gateway pod:

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:sa:istio-ingressgateway-service-account \
        -selector k8s:ns:istio-system \
        -socketPath /run/spire/sockets/server.sock

    Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
    SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
    Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Revision         : 0
    TTL              : default
    Selector         : k8s:ns:istio-system
    Selector         : k8s:sa:istio-ingressgateway-service-account
    {{< /text >}}

1. Register an entry for workloads injected with an Istio sidecar:

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/sleep \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-label:spiffe.io/spire-managed-identity:true \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

## Install Istio

1. [Download the Istio release](/docs/setup/additional-setup/download-istio-release/).

1. Create the Istio configuration with custom patches for the Ingress Gateway and `istio-proxy`. The Ingress Gateway component includes the `spiffe.io/spire-managed-identity: "true"` label.

    {{< text syntax=bash snip_id=define_istio_operator_for_auto_registration >}}
    $ cat <<EOF > ./istio.yaml
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
        # This is used to customize the sidecar template.
        # It adds both the label to indicate that SPIRE should manage the
        # identity of this pod, as well as the CSI driver mounts.
        sidecarInjectorWebhook:
          templates:
            spire: |
              labels:
                spiffe.io/spire-managed-identity: "true"
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
                      readOnly: true
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            label:
              istio: ingressgateway
            k8s:
              overlays:
                # This is used to customize the ingress gateway template.
                # It adds the CSI driver mounts, as well as an init container
                # to stall gateway startup until the CSI driver mounts the socket.
                - apiVersion: apps/v1
                  kind: Deployment
                  name: istio-ingressgateway
                  patches:
                    - path: spec.template.spec.volumes.[name:workload-socket]
                      value:
                        name: workload-socket
                        csi:
                          driver: "csi.spiffe.io"
                          readOnly: true
                    - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                      value:
                        name: workload-socket
                        mountPath: "/run/secrets/workload-spiffe-uds"
                        readOnly: true
                    - path: spec.template.spec.initContainers
                      value:
                        - name: wait-for-spire-socket
                          image: busybox:1.36
                          volumeMounts:
                            - name: workload-socket
                              mountPath: /run/secrets/workload-spiffe-uds
                              readOnly: true
                          env:
                            - name: CHECK_FILE
                              value: /run/secrets/workload-spiffe-uds/socket
                          command:
                            - sh
                            - "-c"
                            - |-
                              echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                              while [[ ! -e ${CHECK_FILE} ]] ; do
                                echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                                sleep 15
                              done
                              ls -l ${CHECK_FILE}
    EOF
    {{< /text >}}

1. Apply the configuration:

    {{< text syntax=bash snip_id=apply_istio_operator_configuration >}}
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. Check Ingress Gateway pod state:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

    The Ingress Gateway pod is `Ready` since the corresponding registration entry is automatically created for it on the SPIRE Server. Envoy is able to fetch cryptographic identities from SPIRE.

    This configuration also adds an `initContainer` to the gateway that will wait for SPIRE to create the UNIX Domain Socket before starting the `istio-proxy`. If the SPIRE agent is not ready, or has not been properly configured with the same socket path, the Ingress Gateway `initContainer` will wait forever.

1. Deploy an example workload:

    {{< text syntax=bash snip_id=apply_sleep >}}
    $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    In addition to needing `spiffe.io/spire-managed-identity` label, the workload will need the SPIFFE CSI Driver volume to access the SPIRE Agent socket. To accomplish this,
    you can leverage the `spire` pod annotation template from the [Install Istio](#install-istio) section or add the CSI volume to
    the deployment spec of your workload. Both of these alternatives are highlighted on the example snippet below:

    {{< text syntax=yaml snip_id=none >}}
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
                  readOnly: true
    {{< /text >}}

The Istio configuration shares the `spiffe-csi-driver` with the Ingress Gateway and the sidecars that are going to be injected on workload pods, granting them access to the SPIRE Agent's UNIX Domain Socket.

See [Verifying that identities were created for workloads](#verifying-that-identities-were-created-for-workloads)
to check issued identities.

## Verifying that identities were created for workloads

Use the following command to confirm that identities were created for the workloads:

{{< text syntax=bash snip_id=none >}}
$ kubectl exec -t "$SPIRE_SERVER_POD" -n spire-server -c spire-server -- ./bin/spire-server entry show
Found 2 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
{{< /text >}}

Check the Ingress-gateway pod state:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
{{< /text >}}

After registering an entry for the Ingress-gateway pod, Envoy receives the identity issued by SPIRE and uses it for all TLS and mTLS communications.

### Check that the workload identity was issued by SPIRE

1. Get pod information:

    {{< text syntax=bash snip_id=set_sleep_pod_var >}}
    $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Retrieve sleep's SVID identity document using the istioctl proxy-config secret command:

    {{< text syntax=bash snip_id=get_sleep_svid >}}
    $ istioctl proxy-config secret "$SLEEP_POD" -o json | jq -r \
    '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
    {{< /text >}}

1. Inspect the certificate and verify that SPIRE was the issuer:

    {{< text syntax=bash snip_id=get_svid_subject >}}
    $ openssl x509 -in chain.pem -text | grep SPIRE
        Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
    {{< /text >}}

## SPIFFE federation

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

- If using the SPIRE Controller Manager, create federated entries for workloads by setting the `federatesWith` field of the [ClusterSPIFFEID CR](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) to the trust domains you want the pod to federate with:

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: spire.spiffe.io/v1alpha1
    kind: ClusterSPIFFEID
    metadata:
      name: federation
    spec:
      spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
      podSelector:
        matchLabels:
          spiffe.io/spire-managed-identity: "true"
      federatesWith: ["example.io", "example.ai"]
    {{< /text >}}

- For manual registration see [Create Registration Entries for Federation](https://spiffe.io/docs/latest/architecture/federation/readme/#create-registration-entries-for-federation).

## Cleanup SPIRE

Remove SPIRE by uninstalling its Helm charts:

{{< text syntax=bash snip_id=uninstall_spire >}}
$ helm delete -n spire-server spire
{{< /text >}}

{{< text syntax=bash snip_id=uninstall_spire_crds >}}
$ helm delete -n spire-server spire-crds
{{< /text >}}
