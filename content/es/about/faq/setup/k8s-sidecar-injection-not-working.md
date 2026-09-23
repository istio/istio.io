---
title: Kubernetes - ¿Cómo puedo depurar problemas con la inyección automática de sidecar?
weight: 20
---

Asegúrese de que su cluster haya cumplido los
[requisitos previos](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) para
la inyección automática de sidecar. Si su microservicio está implementado en
los namespaces `kube-system`, `kube-public` o `istio-system`, están exentos
de la inyección automática de sidecar. Utilice un namespace diferente
en su lugar.
