---
---
Перед оновленням Istio у вашому кластері ми рекомендуємо створити резервну копію ваших власних конфігурацій і відновити їх з резервної копії за необхідності:

{{< text bash >}}
$ kubectl get istio-io --all-namespaces -oyaml > "$HOME"/istio_resource_backup.yaml
{{< /text >}}

Ви можете відновити вашу власну конфігурацію так:

{{< text bash >}}
$ kubectl apply -f "$HOME"/istio_resource_backup.yaml
{{< /text >}}