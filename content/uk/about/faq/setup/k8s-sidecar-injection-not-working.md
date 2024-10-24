---
title: Kubernetes — як можна відстежити проблеми з автоматичними інʼєкціями sidecar?
weight: 20
---

Переконайтеся, що ваш кластер відповідає [вимогам](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) для автоматичної інʼєкції sidecar. Якщо ваш мікросервіс розгорнутий у просторах імен `kube-system`, `kube-public` або `istio-system`, вони виключені з автоматичної інʼєкції sidecar. Будь ласка, використовуйте інший простір імен.
