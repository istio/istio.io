---
title: Istio CA Integration with SPIRE 
linktitle: How integrate Istio with SPIRE through Envoy SDS API.
description: Describes how to configure Istio to integrate with SPIRE to get cryptographic identities through the Envoy SDS API.
weight: 40
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: no
---

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) is a production-ready implementation of the SPIFFE specification that performs node and workload attestation in order to securely issue cryptographic identities to workloads running in heterogeneous environments.  
In an Istio deployment, SPIRE can be configured as a source of cryptographic identities for Istio workloads through the integration with [Envoy's SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret).
Istio can detect the existence of a UNIX domain socket that implements the Envoy SDS API on a well known path, allowing Envoy to communicate and 
receive identities directly from it.

## Install SPIRE

### Option 1: Quick start

Istio provides a basic sample installation to quickly get SPIRE up and running:

{{< text bash >}}
$ kubectl apply -f @samples/security/envoy-sds/spire/spire-quickstart.yaml
{{< /text >}}

This will deploy SPIRE into your cluster, along with two additional components: the [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi) — used to share the SPIRE Agent's Unix domain socket with the other
pods throughout the node — and the [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar), a facilitator that performs automatic workload registration
within Kubernetes. See [Install Istio](#install-istio) to configure Istio and integrate with the SPIFFE CSI Driver.

{{< warning >}}
Note that some configurations used here may not be fully appropriate for a production environment. 

Please see [Scaling SPIRE](https://spiffe.io/docs/latest/planning/scaling_spire/) for more information on configuring SPIRE for a production environment.
{{< /warning >}}

### Option 2: Customizable Spire install

See the [SPIRE's Quickstart for Kubernetes guide](https://spiffe.io/docs/latest/try/getting-started-k8s/) 
to get started deploying SPIRE into your Kubernetes environment. See [Integration Prerequisites](#integration-prerequisites)
for more information on configuring SPIRE to integrate with Istio deployments.

### CA Integration Prerequisites

These configuration requirements are necessary to successfully integrate Istio with SPIRE:

1. Access [SPIRE Agent reference](https://spiffe.io/docs/latest/deploying/spire_agent/#agent-configuration-file) and
   configure the SPIRE Agent socket path to match Envoy SDS path.

   {{< text >}}
   socket_path = "/run/secrets/workload-spiffe-uds/socket"
   {{< /text >}}

2. Share the SPIRE Agent socket with the pods within the node by leveraging the
   [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi).

3. See [Install Istio](#install-istio) to configure Istio to integrate with the SPIFFE CSI Driver.

## Install Istio

[Download the latest Istio release](https://istio.io/latest/docs/setup/getting-started/#download).
After successfully deploying SPIRE into your environment, install Istio with custom patches for istio-ingressgateways/egressgateways as well as the istio-proxy

to access the SPIRE Agent socket shared by the [SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi). Use
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

This will share the spiffe-csi-driver with the Ingressgateway and the sidecars that are going
to be automatically injected on workload pods, granting them access to the SPIRE Agent's UNIX Domain Socket.

* Check Ingressgateway pod state:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   0/1     Running   0          17s
istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
{{< /text >}}

Data plane containers will only reach ready state after creating new entries for them on SPIRE Server, that way Envoy will be able
to fetch cryptographic identities from SPIRE.
See [Registering Workloads](#registering-workloads) to register entries for services in your mesh.

## Registering Workloads

Registering workloads with SPIFFE IDs in the SPIRE Server.

### Option 1: Automatically

By deploying [SPIRE Kubernetes Workload Registrar](https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar)
along with SPIRE Server to register new entries automatically for each new pod that is created.

See [Verifying that identities were created for workloads](#verifying-that-identities-were-created-for-workloads) 
to check issued identities.

### Option 2: Manual registration

SPIRE Server is able to verify a group of values to improve workload attestation security
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

3. Attest the SPIRE Agent running on the node
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

4. and then register an entry for istio-ingressgateway pod:
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
SPIFFE IDs for workloads must follow the Istio SPIFFE ID pattern: spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>
{{< /warning >}}

See the [SPIRE help on Registering workloads](https://spiffe.io/docs/latest/deploying/registering/) to learn how to create new entries for workloads and get them attested using multiple selectors to strengthen attestation criteria.

## Verifying that identities were created for workloads

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

* Check Ingressgateway pod state:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
{{< /text >}}

After registering an entry for Ingressgateway pod, Envoy receives the identity issued by SPIRE and uses it for all TLS and mTLS 
communications.

## SPIFFE Federation

SPIRE Servers are able to authenticate SPIFFE identities originated from different trust domains, this is known as SPIFFE federation.
SPIRE Agent can be configured to push federated bundles to Envoy through the Envoy SDS API, allowing Envoy to use [validation context](https://spiffe.io/docs/latest/microservices/envoy/#validation-context)
to verify peer certificates and trust a workload from another trust domain.   
To enable Istio to federate SPIFFE identities through SPIRE integration:

1. Consult [SPIRE Agent SDS configuration](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration) and set the following 
SDS configuration values for your SPIRE Agent configuration file.

| Configuration              | Description                                                                                      | Resource Name |
|----------------------------|--------------------------------------------------------------------------------------------------|---------------|
| `default_svid_name`        | The TLS Certificate resource name to use for the default X509-SVID with Envoy SDS                | default       |
| `default_bundle_name`      | The Validation Context resource name to use for the default X.509 bundle with Envoy SDS          | null          |
| `default_all_bundles_name` | The Validation Context resource name to use for all bundles (including federated) with Envoy SDS | ROOTCA        |

This will allow Envoy to get federated bundles directly from SPIRE.

2. In your workload deployment, add the pod annotation `spiffe.io/federatesWith`, specifying the trust domain you want the pod federated with:

   {{< text  >}}
   podAnnotations:
     spiffe.io/federatesWith: "<trust.domain>"
   {{< /text >}}

## Cleanup SPIRE

* If you installed SPIRE using the quick start SPIRE deployment provided by Istio, use
the following commands to remove those Kubernetes resources:

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
