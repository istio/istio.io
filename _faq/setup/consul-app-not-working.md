---
title: Consul - My application isn't working, where can I troubleshoot this?
order: 40
type: markdown
---
{% include home.html %}

Please ensure all required containers are running: etcd, istio-apiserver, consul, registrator, pilot.  If one of them is not running, you may find the {containerID} using `docker ps -a` and then use `docker logs {containerID}` to read the logs.
