---
title: mixs
overview: Mixer is Istio's abstraction on top of infrastructure backends.
layout: docs
order: 201
type: markdown
---

<a name="mixs"></a>
## mixs

Mixer is Istio's abstraction on top of infrastructure backends.

### Synopsis


Mixer is Istio's point of integration with infrastructure backends and is the
nexus for policy evaluation and telemetry reporting.

<a name="mixs_inventory_adapter"></a>
## mixs inventory adapter

List available adapter builders

### Synopsis


List available adapter builders

```
mixs inventory adapter
```

<a name="mixs_inventory_aspect"></a>
## mixs inventory aspect

List available aspects

### Synopsis


List available aspects

```
mixs inventory aspect
```

<a name="mixs_inventory"></a>
## mixs inventory

Inventory of available adapters and aspects in Mixer

### Synopsis


Inventory of available adapters and aspects in Mixer

<a name="mixs_server"></a>
## mixs server

Starts Mixer as a server

### Synopsis


Starts Mixer as a server

```
mixs server
```

### Options

```
      --adapterWorkerPoolSize int   Max # of goroutines in the adapter worker pool (default 1024)
      --apiWorkerPoolSize int       Max # of goroutines in the API worker pool (default 1024)
      --clientCertFiles string      A set of comma-separated client X509 cert files
      --compressedPayload           Whether to compress gRPC messages
      --configAPIPort uint16        HTTP port to use for Mixer's Configuration API (default 9094)
      --configFetchInterval uint    Configuration fetch interval in seconds (default 5)
      --configStoreURL string       URL of the config store. May be fs:// for file system, or redis:// for redis url
      --globalConfigFile string     Global Config
      --maxConcurrentStreams uint   Maximum supported number of concurrent gRPC streams (default 32)
      --maxMessageSize uint         Maximum size of individual gRPC messages (default 1048576)
  -p, --port uint16                 TCP port to use for Mixer's gRPC API (default 9091)
      --serverCertFile string       The TLS cert file
      --serverKeyFile string        The TLS key file
      --serviceConfigFile string    Combined Service Config
      --singleThreaded              Whether to run Mixer in single-threaded mode (useful for debugging)
      --trace                       Whether to trace rpc executions
```

<a name="mixs_version"></a>
## mixs version

Prints out build version information

### Synopsis


Prints out build version information

```
mixs version
```

