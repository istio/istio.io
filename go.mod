module istio.io/istio.io

go 1.13

replace github.com/golang/glog => github.com/istio/glog v0.0.0-20190424172949-d7cfb6fa2ccd

replace k8s.io/klog => github.com/istio/klog v0.0.0-20190424230111-fb7481ea8bcf

replace github.com/spf13/viper => github.com/istio/viper v1.3.3-0.20190515210538-2789fed3109c

replace github.com/docker/docker => github.com/docker/engine v1.4.2-0.20191011211953-adfac697dc5b

require (
	istio.io/gogo-genproto v0.0.0-20200511213158-02f1fd1746e5 // indirect
	istio.io/istio v0.0.0-20200622140019-5d0ba6bf14a4
	istio.io/pkg v0.0.0-20200511212725-7bfbbf968c23
)

replace github.com/Azure/go-autorest/autorest => github.com/Azure/go-autorest/autorest v0.9.0

replace github.com/Azure/go-autorest/autorest/adal => github.com/Azure/go-autorest/autorest/adal v0.5.0

replace github.com/Azure/go-autorest => github.com/Azure/go-autorest v13.2.0+incompatible
