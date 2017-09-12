---
title: istio_ca
overview: Istio Certificate Authority (CA)
layout: docs
order: 301
type: markdown
---

<a name="istio_ca_cmd"></a>
## istio_ca

Istio Certificate Authority (CA)

### Synopsis


Istio Certificate Authority (CA)

```
istio_ca [flags]
```

### Options

```
      --alsologtostderr                  log to standard error as well as files
      --ca-cert-ttl duration             The TTL of self-signed CA root certificate (default 8760h0m0s)
      --cert-chain string                Speicifies path to the certificate chain file
      --cert-ttl duration                The TTL of issued certificates (default 1h0m0s)
      --grpc-hostname string             Specifies the hostname for GRPC server. (default "localhost")
      --grpc-port int                    Specifies the port number for GRPC server. If unspecified, Istio CA will not server GRPC request.
      --kube-config string               Specifies path to kubeconfig file. This must be specified when not running inside a Kubernetes pod.
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
      --namespace string                 Select a namespace for the CA to listen to. If unspecified, Istio CA tries to use the ${NAMESPACE} environment variable. If neither is set, Istio CA listens to all namespaces.
      --root-cert string                 Specifies path to the root certificate file
      --self-signed-ca                   Indicates whether to use auto-generated self-signed CA certificate. When set to true, the '--signing-cert' and '--signing-key' options are ignored.
      --self-signed-ca-org string        The issuer organization used in self-signed CA certificate (default to k8s.cluster.local) (default "k8s.cluster.local")
      --signing-cert string              Specifies path to the CA signing certificate file
      --signing-key string               Specifies path to the CA signing key file
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istio_ca_version"></a>
## istio_ca version

Display version information

### Synopsis


Display version information

```
istio_ca version
```

### Options inherited from parent commands

```
      --alsologtostderr                  log to standard error as well as files
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

