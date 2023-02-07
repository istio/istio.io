---
---
当使用 `default` 标签和现有的未修订版本的 Istio 安装方式一起使用时，
建议删除旧的 `MutatingWebhookConfiguration`（通常称为 `istio-sidecar-injector`），
以避免新旧控制平面同时尝试注入。
