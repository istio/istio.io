---
title: Istio 1.1
publishdate: 2019-03-01
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

## `istioctl`

- Deprecated `istioctl create`, `istioctl replace`, `istioctl get`, and `istioctl delete`. Use `kubectl` instead (see <https://kubernetes.io/docs/tasks/tools/install-kubectl>). The next release (1.2) removes the deprecated commands.
- Deprecated `istioctl gen-deploy`. Use a [`helm template`](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template) instead. The next release (1.2) removes this command.

- Added [`istioctl validate`](/docs/reference/commands/istioctl/#istioctl-validate) for offline validation of Istio Kubernetes resources. The intent is to replace the existing use of the deprecated `istioctl create` command.

- Added [`istioctl experimental verify-install`](/docs/reference/commands/istioctl/#istioctl-experimental-verify-install). This experimental command verifies the installation status of Istio given a specified install YAML file.

## Configuration

- You can now use Galley to serve as the Kubernetes touch point between Kubernetes and the other Istio components: Pilot and Mixer. This feature is in [alpha](https://preliminary.istio.io/about/feature-stages/#feature-phase-definitions). Subsequent Istio releases will make Galley Istio's default configuration management mechanism.
