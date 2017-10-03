---
title: FAQ
overview: Frequently asked questions, current limitations and troubleshooting tips.

order: 100

layout: docs
type: markdown
---

{% include home.html %}

* _My application isn't working, where can I troubleshoot this?_

  Please ensure all required containers are running: etcd, istio-apiserver, consul, registrator, istio-pilot.  If one of them is not running, you may find the {containerID} using `docker ps -a` and then use `docker logs {containerID}` to read the logs.   
  
* _How do I unset the context changed by `istioctl` at the end?_

  Your ```kubectl``` is switched to use the istio context at the end of the `istio context-create` command.  You can use ```kubectl config get-contexts``` to obtain the list of contexts and ```kubectl config use-context {desired-context}``` to switch to use your desired context.
