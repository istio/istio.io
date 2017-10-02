---
title: FAQ
overview: Frequently asked questions, current limitations and troubleshooting tips on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How do I check if my cluster has enabled the alpha feature required for automatic sidecar injection?_

  Automatic sidecar injection requires the [initilizer alpha feature](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature).
  Run the following command to check if the initializer has been enabled (empty output indicates that initializers are not enabled):
 
  ```bash
  kubectl api-versions | grep admissionregistration
  ```

* _Automatic sidecar injection doesn't work for my microservice, how can I debug this?_
  
  Please ensure your cluster has met the [prerequisites](automatic-sidecar-inject.html#prerequisites) for the automatic sidecar injection.  If your microservice is deployed in kube-system, kube-public or istio-system namespaces, they are exempted from automatic sidecar injection.  Please use a different namespace instead.
  
* _Can I migrate an existing installation from Istio v0.1.x to v0.2.x?_
  
  Upgrading from Istio 0.1.x to 0.2.x is not supported. You must uninstall Istio v0.1, _including pods with Istio sidecars_ and start with a fresh install of Istio v0.2.
