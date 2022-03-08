---
title: Spire SDS Integration
linktitle: How integrate with Spire CA.
description: Describes how to configure Istio to integrate with Spire CA via Secret Discovery Service.
weight: 40
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: no
---

[Spire](/docs/ops/integrations/spire/)

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) is a production-ready implementation of the SPIFFE APIs that performs node
and workload attestation in order to securely issue SVIDs to workloads, and verify
the SVIDs of other workloads, based on a predefined set of conditions. In an Istio deployment, SPIRE can be
configured as a source of SVIDs for Istio workloads through integrating with [Envoy's SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret).

## Install Spire

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Spire up and running:

{{< text bash >}}
$ kubectl apply -f @samples/security/envoy-sds/spire/spire-quickstart.yaml
{{< /text >}}

This will deploy SPIRE into your cluster, along with two additional components: the [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi) — used to share the Spire Agent's Unix Domain Socket with the other
pods throughout the node — and the [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar), a facilitator that performs automatic workload registration
within Kubernetes. See [Install Istio](#install-istio) to configure Istio and integrate with the SPIFFE CSI Driver.

{{< warning >}}
Note that many configuration used here may not be fully apropriate for production. 
Please see [Scaling SPIRE](https://spiffe.io/docs/latest/planning/scaling_spire/) for more information on configuring SPIRE for a production environment.
{{< /warning >}}

### Option 2: Customizable Spire install

Reference the [SPIRE Installation guide](https://spiffe.io/docs/latest/try/getting-started-k8s/) 
to get started deploying SPIRE into your Kubernetes environment. See [Integration Prerequisites](#integration-prerequisites)
for more information on configuring SPIRE to integrate with Istio deployments.

### CA Integration Prerequisites

There are a couple of necessary configuration requirements to successfully integrate Istio with Spire CA:

1. Access [Spire Agent reference](https://spiffe.io/docs/latest/deploying/spire_agent/#agent-configuration-file) and
   configure the Spire Agent socket path to match Envoy SDS path.

   {{< text >}}
   socket_path = "/run/secrets/workload-spiffe-uds/socket"
   {{< /text >}}

2. Share the Spire Agent socket with the pods within the node by leveraging the
   [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi).

3. See [Install Istio](#install-istio) to configure Istio to integrate with the SPIFFE CSI Driver.

## Install Istio

[Download the latest Istio release](https://istio.io/latest/docs/setup/getting-started/#download).
After deploying successfully Spire into your environment, install Istio with custom patches for istio-ingressgateways/egressgateways as well as the istio-proxy
to access the Spire Agent socket shared by the [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi). Use
[Automatic sidecar injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
to inject automatically the spire template below into new workloads pods.

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
                   - path: spec.template.spec.volumes[8]
                     value:
                       name: workload-socket
                       csi:
                         driver: "csi.spiffe.io"
                   - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                     value:
                       name: workload-socket
                       mountPath: "/run/spire/sockets"
                       readOnly: true
   EOF
   {{< /text >}}

This will share the spiffe-csi-driver with the Ingressgateway and the sidecars that are going
to be automatically injected on workload pods, granting them access to the Spire Agent's UNIX Domain Socket.


## Registering Workloads

Registering workloads with SPIFFE IDs in the SPIRE Server.

### Option 1: Automatically

By deploying [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar)
along with Spire Server to register new entries automatically for each new pod that is created.

### Option 2: Manually

Spire Server is able to verify a group of values to improve workload attestation security
robustness.

1. To generate an entry for an ingress-gateway with a set of selectors for example, get the
   pod name and pod-uid:

{{< text bash >}}
$ INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
$ INGRESS_POD_UID=$(kubectl get pods -n istio-system $INGRESS_POD -o jsonpath='{.metadata.uid}')
{{< /text >}}

2. Get the spire-server pod:

{{< text bash >}}
$ SPIRE_SERVER_POD=$(kubectl get pod -l app=spire-server -n spire -o jsonpath="{.items[0].metadata.name}")
{{< /text >}}

3. Attest the Spire Agent running on the node
   {{< text bash >}}
   $ kubectl exec -n spire $SPIRE_SERVER_POD -- \
   /opt/spire/bin/spire-server entry create \
   -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
   -selector k8s_psat:cluster:demo-cluster \
   -selector k8s_psat:agent_ns:spire \
   -selector k8s_psat:agent_sa:spire-agent \
   -node -socketPath /run/spire/sockets/server.sock
   {{< /text >}}
   
   {{< text >}}
   Entry ID         : d38c88d0-7d7a-4957-933c-361a0a3b039c
   SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
   Parent ID        : spiffe://example.org/spire/server
   Revision         : 0
   TTL              : default
   Selector         : k8s_psat:agent_ns:spire
   Selector         : k8s_psat:agent_sa:spire-agent
   Selector         : k8s_psat:cluster:demo-cluster
   {{</ text >}}

4. and then register an entry for the pod:
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
   {{< /text >}}

   {{< text >}}
   Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
   SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
   Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
   Revision         : 0
   TTL              : default
   Selector         : k8s:ns:istio-system
   Selector         : k8s:pod-uid:63c2bbf5-a8b1-4b1f-ad64-f62ad2a69807
   Selector         : k8s:sa:istio-ingressgateway-service-account
   DNS name         : istio-ingressgateway.istio-system.svc
   DNS name         : istio-ingressgateway-c48554dd6-cff5z
   {{</ text >}}

{{< warning >}}
SpiffeIDs for workloads must contain the Istio SPIFFE ID pattern spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>
{{< /warning >}}

Consult [Registering workloads](https://spiffe.io/docs/latest/deploying/registering/) on how
to create new entries for workloads and attest a set of multiples selectors for securing services.

## Verifying Entries

Confirm that identities were created for the workloads.
{{< text bash >}}
$ kubectl exec -i -t $SPIRE_SERVER_POD -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -socketPath /run/spire/sockets/server.sock"
{{< /text >}}

   {{< text >}}
   Found 1 entry
   Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
   SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
   Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
   Revision         : 0
   TTL              : default
   Selector         : k8s:ns:istio-system
   Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d
   Selector         : k8s:sa:istio-ingressgateway-service-account
   DNS name         : istio-ingressgateway-c48554dd6-cff5z
   {{< /text >}}

## Spire Federation

Istio uses different Envoy validation contexts for workload identities and bundles.
To enable Spire Federation:

1. Consult [Spire Agent SDS configuration](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration) and set the following 
SDS configuration values for your Spire Agent configuration file.

| Configuration              | Description                                                                                      | Validation Context |
| -------------------------- | ------------------------------------------------------------------------------------------------ |--------------------|
| `default_svid_name`        | The TLS Certificate resource name to use for the default X509-SVID with Envoy SDS                | default            |
| `default_bundle_name`      | The Validation Context resource name to use for the default X.509 bundle with Envoy SDS          | null               |
| `default_all_bundles_name` | The Validation Context resource name to use for all bundles (including federated) with Envoy SDS | ROOTCA             |

This will allow Envoy to get federated bundles from Spire.

2. Adds the federates with podAnnotation from spiffe.io, with the trust domain you want to federate, for your workload deployment:

   {{< text  >}}
   podAnnotations:
     spiffe.io/federatesWith: "domain.test"
   {{< /text >}}

## Cleanup Spire

* Remove created Kubernetes resources:

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
