---
title: Consul - My application isn't working, where can I troubleshoot this?
weight: 40
---

Please ensure all required containers are running: etcd, istio-apiserver, consul, registrator, pilot.  If one of them is not running, you may find the {containerID} using `docker ps -a` and then use `docker logs {containerID}` to read the logs.
