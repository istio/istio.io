---
title: OpenShift
description: Instructions to setup an OpenShift cluster for Istio.
weight: 55
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/openshift/
    - /docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
owner: istio/wg-environments-maintainers
test: no
---

Follow these instructions to prepare an OpenShift cluster for Istio.

By default, OpenShift doesn't allow containers running with user ID 0.
You must enable containers running with UID 0 for Istio's service accounts
by running the command below. Make sure to replace `istio-system` if you are
deploying Istio in another namespace:

{{< text bash >}}
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
{{< /text >}}

Install Istio using the OpenShift profile:

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

After installation is complete, expose an OpenShift route for the ingress gateway.

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=http2
{{< /text >}}

## Privileged security context constraints for application sidecars

The Istio sidecar injected into each application pod runs with user ID 1337, which is not allowed by default in OpenShift. To allow this user ID to be used, execute the following commands. Replace `<target-namespace>` with the appropriate namespace.

{{< text bash >}}
$ oc adm policy add-scc-to-group privileged system:serviceaccounts:<target-namespace>
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts:<target-namespace>
{{< /text >}}

When removing your application, remove the permissions as follows.

{{< text bash >}}
$ oc adm policy remove-scc-from-group privileged system:serviceaccounts:<target-namespace>
$ oc adm policy remove-scc-from-group anyuid system:serviceaccounts:<target-namespace>
{{< /text >}}

## Additional requirements for the application namespace

CNI on OpenShift is managed by `Multus`, and it requires a `NetworkAttachmentDefinition` to be present in the application namespace in order to invoke the `istio-cni` plugin. Execute the following commands. Replace `<target-namespace>` with the appropriate namespace.

{{< text bash >}}
$ cat <<EOF | oc -n <target-namespace> create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF
{{< /text >}}

When removing your application, remove the `NetworkAttachmentDefinition` as follows.

{{< text bash >}}
$ oc -n <target-namespace> delete network-attachment-definition istio-cni
{{< /text >}}
