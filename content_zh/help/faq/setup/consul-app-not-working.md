---
title: Consul - 我的应用程序无法正常工作，我该如何调试并解决问题？
weight: 40
---

请确保所有需要的容器都运行正常：etcd、istio-apiserver、consul、registrator、pilot。如果以上某个容器未正常运行，你可以使用 `docker ps -a` 命令找到 {containerID}，然后使用命令 `docker logs {containerID}` 来查阅日志。
