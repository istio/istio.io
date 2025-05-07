---
---
{{< tip >}}
Istio 默认启用了 `auto_sni` 和 `auto_san_validation`。
这意味着，只要您的 `DestinationRule` 中没有显式设置 `sni`，
新上游连接的传输套接字 SNI 将根据下游 HTTP 主机/授权标头进行设置。
如果在 `sni` 未设置时 `DestinationRule` 中没有设置 `subjectAltNames`，
则 `auto_san_validation` 将启动，并且新上游连接的上游出示的证书将根据下游 HTTP 主机/授权标头自动验证。
{{< /tip >}}
