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
	github.com/golang/sync v0.0.0-20180314180146-1d60e4601c6f
	github.com/pmezard/go-difflib v1.0.0
	istio.io/client-go v1.13.0-beta.1.0.20220210233217-e58430254644 // indirect
	istio.io/istio v0.0.0-20220213095637-2a5e10406d79
	istio.io/pkg v0.0.0-20220210214831-ae0a970bca81
	k8s.io/apimachinery v0.23.3
	k8s.io/client-go v0.23.3
)
