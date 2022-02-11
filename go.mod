module istio.io/istio.io

go 1.16

replace github.com/spf13/viper => github.com/istio/viper v1.3.3-0.20190515210538-2789fed3109c

// Old version had no license
replace github.com/chzyer/logex => github.com/chzyer/logex v1.1.11-0.20170329064859-445be9e134b2

// Avoid pulling in incompatible libraries
replace github.com/docker/distribution => github.com/docker/distribution v0.0.0-20191216044856-a8371794149d

replace github.com/docker/docker => github.com/moby/moby v17.12.0-ce-rc1.0.20200618181300-9dc6525e6118+incompatible

// Client-go does not handle different versions of mergo due to some breaking changes - use the matching version
replace github.com/imdario/mergo => github.com/imdario/mergo v0.3.5

require (
	cloud.google.com/go/compute v1.2.0 // indirect
	github.com/aws/aws-sdk-go v1.42.45 // indirect
	github.com/cncf/xds/go v0.0.0-20220121163655-4a2b9fdd466b // indirect
	github.com/golang/sync v0.0.0-20180314180146-1d60e4601c6f
	github.com/lestrrat-go/jwx v1.2.18 // indirect
	github.com/onsi/gomega v1.18.1 // indirect
	github.com/pmezard/go-difflib v1.0.0
	github.com/prometheus/client_golang v1.12.1 // indirect
	go.opentelemetry.io/proto/otlp v0.12.0 // indirect
	golang.org/x/net v0.0.0-20220127200216-cd36cc0744dd // indirect
	golang.org/x/sys v0.0.0-20220128215802-99c3d69c2c27 // indirect
	google.golang.org/genproto v0.0.0-20220202230416-2a053f022f0d // indirect
	google.golang.org/grpc v1.44.0 // indirect
	helm.sh/helm/v3 v3.8.0 // indirect
	istio.io/gogo-genproto v0.0.0-20220203154911-542602f9bf4f // indirect
	istio.io/istio v0.0.0-20220211191359-5441a97d3671
	istio.io/pkg v0.0.0-20220210214831-ae0a970bca81
	k8s.io/apimachinery v0.23.3
	k8s.io/client-go v0.23.3
	k8s.io/kube-openapi v0.0.0-20220124234850-424119656bbf // indirect
	k8s.io/kubectl v0.23.3 // indirect
	k8s.io/utils v0.0.0-20220127004650-9b3446523e65 // indirect
)
