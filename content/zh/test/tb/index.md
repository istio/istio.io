---
title: 文本块
description: 基础文本块。
skip_sitemap: true
---

带 html 标记的普通文本块

{{< text plain >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP
...
{{< /text >}}

带普通输出的 Bash 文本块

{{< text bash >}}
$ this is a text block
$ echo Foo \
Bar
Foo Bar
{{< /text >}}

带重定向的 Bash 文本块

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
{{< /text >}}

带 html 标记的 Bash 文本块

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP
...
{{< /text >}}

带 yaml 输出和下载名称的 Bash 文本块

{{< text syntax="bash" outputis="yaml" downloadas="foo.yaml" >}}
$ kubectl -n istio-system get configmap istio-galley-configuration -o jsonpath='{.data}'
map[validatingwebhookconfiguration.yaml:apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: istio-galley
  namespace: istio-system
  labels:
    app: istio-galley
    chart: galley-1.0.0
    release: istio
    heritage: Tiller
webhooks:
  - name: pilot.validation.istio.io
    clientConfig:
      service:
        name: istio-galley
        namespace: istio-system
        path: "/admitpilot"
      caBundle: ""
    rules:
      - operations:
      (... snip ...)
{{< /text >}}

带 json 输出和下载名称的 Bash 文本块

{{< text syntax="bash" outputis="json" downloadas="foo.txt" >}}
$ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"newlog.logentry.istio-system\" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
{"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
{{< /text >}}

基于文件的文本块

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

带代码片段和下载名称且基于文件的文本块

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP2" downloadas="foo.txt" >}}

带下载名称且基于文件的 bash 文本块

{{< text_import file="test/command_example.txt" syntax="bash" downloadas="foo.sh" >}}

基于 URL 的文本块

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

带代码片段且基于 URL 的文本块

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

带重定向且基于 URL 的文本块

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/command_example.txt" syntax="bash" outputis="yaml" >}}

带 @@ 内容且基于 URL 文本块

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/release-1.1/test/command_example_atat.txt" syntax="bash" >}}

很宽的文本块

{{< text plain >}}
真得很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽很宽
{{< /text >}}

很高的文本块

{{< text plain >}}
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
真得很高
{{< /text >}}
