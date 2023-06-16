---
---
{{< tip >}}
如有必要，凭据可以包含一个[证书吊销列表 (CRL)](https://datatracker.ietf.org/doc/html/rfc5280)，
使用 `ca.crl` 作为键名。如果是这样，请在上述示例中添加另一个参数来提供
CRL：`--from-file=ca.crl=/some/path/to/your-crl.pem`。
{{< /tip >}}
