---
title: Eureka - My application isn't working, where can I troubleshoot this?
weight: 60
---
{% include home.html %}

Please ensure all required containers are running: etcd, istio-apiserver, consul, registrator, istio-pilot.  If one of them is not running, you may find the {containerID} using `docker ps -a` and then use `docker logs {containerID}` to read the logs.
