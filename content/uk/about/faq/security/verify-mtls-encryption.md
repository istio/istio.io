---
title: Як я можу перевірити, що трафік використовує взаємне шифрування TLS?
weight: 25
---

Якщо ви встановили Istio з `values.global.proxy.privileged=true`, ви можете використовувати `tcpdump`, щоб визначити статус шифрування. Також, з Kubernetes 1.23 і пізніших версій, як альтернатива встановленню Istio як привілейованого сервісу, ви можете використовувати `kubectl debug` для запуску `tcpdump` в [тимчасовому контейнері](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container). Дивіться [міграцію на взаємний TLS в Istio](/docs/tasks/security/authentication/mtls-migration) для інструкцій.
