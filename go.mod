module istio.io/istio.io

go 1.13

replace github.com/golang/glog => github.com/istio/glog v0.0.0-20190424172949-d7cfb6fa2ccd

replace k8s.io/klog => github.com/istio/klog v0.0.0-20190424230111-fb7481ea8bcf

replace github.com/spf13/viper => github.com/istio/viper v1.3.3-0.20190515210538-2789fed3109c

replace github.com/docker/docker => github.com/docker/engine v1.4.2-0.20191011211953-adfac697dc5b

require (
	github.com/Azure/go-autorest/autorest/adal v0.8.3 // indirect
	github.com/docker/spdystream v0.0.0-20181023171402-6480d4af844c // indirect
	github.com/elazarl/goproxy v0.0.0-20190630181448-f1e96bc0f4c5 // indirect
	github.com/elazarl/goproxy/ext v0.0.0-20190630181448-f1e96bc0f4c5 // indirect
	github.com/emicklei/go-restful v2.9.6+incompatible // indirect
	github.com/frankban/quicktest v1.4.1 // indirect
	github.com/go-logr/zapr v0.1.1 // indirect
	github.com/go-openapi/spec v0.19.5 // indirect
	github.com/go-openapi/swag v0.19.6 // indirect
	github.com/gregjones/httpcache v0.0.0-20190611155906-901d90724c79 // indirect
	github.com/mitchellh/reflectwalk v1.0.1 // indirect
	github.com/openshift/api v3.9.1-0.20191008181517-e4fd21196097+incompatible // indirect
	github.com/pelletier/go-toml v1.3.0 // indirect
	github.com/pierrec/lz4 v2.2.7+incompatible // indirect
	github.com/pquerna/cachecontrol v0.0.0-20180306154005-525d0eb5f91d // indirect
	github.com/prometheus/prom2json v1.2.2 // indirect
	github.com/spf13/jwalterweatherman v1.1.0 // indirect
	istio.io/gogo-genproto v0.0.0-20200807182027-a780f93e8ee1 // indirect
	istio.io/istio v0.0.0-20200910082619-5a0543852749
	istio.io/pkg v0.0.0-20200807223740-7c8bbc23c476
)

replace github.com/Azure/go-autorest/autorest => github.com/Azure/go-autorest/autorest v0.9.0

replace github.com/Azure/go-autorest/autorest/adal => github.com/Azure/go-autorest/autorest/adal v0.5.0

replace github.com/Azure/go-autorest => github.com/Azure/go-autorest v13.2.0+incompatible
