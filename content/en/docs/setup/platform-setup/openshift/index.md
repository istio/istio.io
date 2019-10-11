---
title: OpenShift
description: Instructions to setup an OpenShift cluster for Istio.
weight: 24
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/openshift/
    - /docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
---

{{< warning >}}
OpenShift 4.1 and above use `nftables`, which is incompatible with the Istio `proxy-init` container. Please use [CNI](/docs/setup/additional-setup/cni/) instead.
{{< /warning >}}

Follow these instructions to prepare an OpenShift cluster for Istio.

By default, OpenShift doesn't allow containers running with user ID 0.
You must enable containers running with UID 0 for Istio's service accounts:

{{< text bash >}}
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system
{{< /text >}}

The list above accounts for the default Istio service accounts. If you enabled
other Istio services, like _Grafana_ for example, you need to enable its
service account with a similar command.

A service account that runs application pods needs privileged security context
constraints as part of sidecar injection:

{{< text bash >}}
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
{{< /text >}}

Install Istio using the [CNI](/docs/setup/additional-setup/cni/) instructions.

After installation is complete, expose an OpenShift route for the ingress gateway.

{{< text bash >}}
$ oc expose svc/istio-ingressgateway --port=80
{{< /text >}}

## Automatic sidecar injection

Webhook and certificate signing requests support must be enabled for [automatic injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) to work. Modify the master configuration file on the master node for the cluster as follows.

{{< tip >}}
By default, the master configuration file can be found in `/etc/origin/master/master-config.yaml`.
{{< /tip >}}

In the same directory as the master configuration file, create a file named `master-config.patch` with the following contents:

{{< text yaml >}}
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
{{< /text >}}

In the same directory, execute:

{{< text bash >}}
$ cp -p master-config.yaml master-config.yaml.prepatch
$ oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
$ master-restart api
$ master-restart controllers
{{< /text >}}

## Privileged security context constraints for sidecars

The Istio sidecar injected into each pod runs with user ID 1337, which is not allowed by default in OpenShift. To allow this user ID to be used, execute the following commands. Replace `-n bookinfo` with the appropriate namespace.

{{< text bash >}}
$ oc adm policy add-scc-to-group privileged system:serviceaccounts -n bookinfo
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts -n bookinfo
{{< /text >}}

When removing your application, remove the permissions as follows.

{{< text bash >}}
$ oc adm policy remove-scc-from-group privileged system:serviceaccounts -n bookinfo
$ oc adm policy remove-scc-from-group anyuid system:serviceaccounts -n bookinfo
{{< /text >}}
