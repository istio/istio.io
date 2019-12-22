---
title: Consul - 我的应用没有工作，怎么进行问题排查？
weight: 40
---

请确保所有需要的容器正常运行：`etcd`、`istio-apiserver`、`consul`、`registrator`、`pilot`。如果以上某个容器未正常运行，你可以通过 `docker ps -a` 命令找到容器 ID {containerID} 然后使用 `docker logs {containerID}` 命令查看日志。
