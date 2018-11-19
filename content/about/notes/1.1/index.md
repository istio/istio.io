---
title: Istio 1.1
weight: 88
icon: notes
---

TODO announcement

{{< relnote_links >}}

## Policies and Telemetry

- **Kiali**. The Service Graph addon has been [deprecated](https://github.com/istio/istio/issues/9066) in favor of [Kiali](https://www.kiali.io). See the [Kiali Task](/docs/tasks/telemetry/kiali/) for more details about Kiali.

## Security

- Deprecated `RbacConfig` replacing it with `ClusterRbacConfig` to implement the correct cluster scope.
  Refer to our guide on [Migrating the `RbacConfig` to `ClusterRbacConfig`](/docs/setup/kubernetes/upgrading-istio#migrating-the-rbacconfig-to-clusterrbacconfig)
  for migration instructions.
  
## Istioctl

- Deprecated `istioctl create`, `istioctl replace`, `istioctl get`, and `istioctl delete`. `kubectl` should be used instead (see https://kubernetes.io/docs/tasks/tools/install-kubectl). These commands will be removed in the next release (1.2).
- `istioctl gen-deploy`. [`helm template`](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template) should be used instead. This command will be removed in the next release (1.2).
  
- Added [`istioctl validate`](/docs/reference/commands/istioctl/#istioctl-validate) for offline validation of Istio Kubernetes resources. This is intended to replace the existing usage of the deprecated `istioctl create` command.

- Added [`istioctl experimental verify-install`](/docs/reference/commands/istioctl/#istioctl-experimental-verify-install). This experimental command verifies the installation status of Istio given a specified install YAML file. 

## Configuration

- Galley can now optionally serve as the Kubernetes touch point between Kubernetes and Pilot and Mixer. This feature is [alpha](https://preliminary.istio.io/about/feature-stages/#feature-phase-definitions). In subsequent Istio releases Galley will become the Istio's configuration management mechanism.

