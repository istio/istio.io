---
title: FAQ
overview: Frequently asked questions, current limitations and troubleshooting tips on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How to check if my cluster has the alpha feature required by automatic sidecar injection?_

  Automatic sidecar injection requires the [initilizer alpha feature] (https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature).  You can execute ```kubectl api-versions | grep admissionregistration``` to check if your cluster has the initializer alpha feature enabled.

* _Is there a migration between v0.1 to v0.2?_
  
  Sorry, there is no migration between v0.1 to v0.2.  You must uninstall Istio v0.1 and install Istio v0.2.
  
* _If I delete Istio v0.1 and install Istio v0.2 on my cluster, will my microservices continue to work with the new Istio? _
 
  Sorry, you will have to uninstll your microservices and reinstall them to ensure they are managed properly by Istio v0.2.
