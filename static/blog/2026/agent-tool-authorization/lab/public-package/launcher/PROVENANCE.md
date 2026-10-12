# Custom kind launcher provenance

The binary is the exact existing Linux amd64 kind v0.33.0 custom build, SHA-256 `55ccf762eb3975ad00f7d51fbc37d0b813c93a93ac4f84eb6f61c548e46ecfa2`, 11,042,940 bytes. It is not the upstream official release binary.

Upstream: https://github.com/kubernetes-sigs/kind at commit `407a9675e6d9af1200b5f57f9ca52ec6cdacce74`. The selected source proof, original and patched `provision.go`, narrow logging patch, go.mod/go.sum and exact existing launcher contract are included. Apache License 2.0 is included in LICENSE. The single source change adds Docker json-file logging bounded to 4 MiB x 2 during node creation. Build used Go 1.27.1, GOOS=linux GOARCH=amd64 CGO_ENABLED=0, trimpath, readonly modules, empty build ID and the version link flags described by the unchanged contract. A fresh rebuild is not substituted for these reviewed binary bytes.

The contract's historical PENDING fields are preserved exactly; they do not provide human execution authority. An operator-owned exact explicit launcher authorization remains mandatory. This package includes no true grant and makes no live launcher execution claim.
