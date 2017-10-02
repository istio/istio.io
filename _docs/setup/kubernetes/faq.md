---
title: FAQ
overview: Frequently asked questions, current limitations and troubleshooting tips on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How do I check if my cluster has enabled the alpha features required for automatic sidecar injection?_

  Automatic sidecar injection requires the
  [initilizer alpha feature](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature).
  Run the following command to check if the initializer has been enabled
  (empty output indicates that initializers are not enabled):
 
  ```bash
  kubectl api-versions | grep admissionregistration
  ```

  In addition, the Kubernetes API server must be started with the Initializer plugin enabled.

* _Automatic sidecar injection is not working. How can I debug this?_

  Ensure that your cluster has met the
  [prerequisites](sidecar-injection.html#automatic-sidecar-injection) for
  the automatic sidecar injection.  If your microservice is deployed in
  kube-system, kube-public or istio-system namespaces, they are exempted
  from automatic sidecar injection.  Please use a different namespace
  instead.
  
* _Can I migrate an existing installation from Istio v0.1.x to v0.2.x?_
  
  Upgrading from Istio 0.1.x to 0.2.x is not supported. You must uninstall Istio v0.1, _including pods with Istio sidecars_ and start with a fresh install of Istio v0.2.
