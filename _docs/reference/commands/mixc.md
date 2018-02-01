---
title: mixc
overview: Utility to trigger direct calls to Mixer's API.
layout: docs
---
This command lets you interact with a running instance of
Mixer. Note that you need a pretty good understanding of Mixer's
API in order to use this command.

|Option|Shorthand|Description
|------|---------|-----------
|--trace_jaeger_url <string>||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default "")
|--trace_log_spans ||Whether or not to log trace spans. 
|--trace_zipkin_url <string>||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default "")


## mixc check

The Check method is used to perform precondition checks and quota allocations. Mixer
expects a set of attributes as input, which it uses, along with
its configuration, to determine which adapters to invoke and with
which parameters in order to perform the checks and allocations.
```
mixc check [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--attributes <string>|-a|List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...  (default "")
|--bool_attributes <string>|-b|List of name/value bool attributes specified as name1=value1,name2=value2,...  (default "")
|--bytes_attributes <string>||List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...  (default "")
|--double_attributes <string>|-d|List of name/value float64 attributes specified as name1=value1,name2=value2,...  (default "")
|--duration_attributes <string>||List of name/value duration attributes specified as name1=value1,name2=value2,...  (default "")
|--int64_attributes <string>|-i|List of name/value int64 attributes specified as name1=value1,name2=value2,...  (default "")
|--mixer <string>|-m|Address and port of a running Mixer instance  (default "localhost:9091")
|--quotas <string>|-q|List of quotas to allocate specified as name1=amount1,name2=amount2,...  (default "")
|--repeat <int>|-r|Sends the specified number of requests in quick succession  (default 1)
|--string_attributes <string>|-s|List of name/value string attributes specified as name1=value1,name2=value2,...  (default "")
|--stringmap_attributes <string>||List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...  (default "")
|--timestamp_attributes <string>|-t|List of name/value timestamp attributes specified as name1=value1,name2=value2,...  (default "")
|--trace_jaeger_url <string>||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default "")
|--trace_log_spans ||Whether or not to log trace spans. 
|--trace_zipkin_url <string>||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default "")


## mixc help

Help provides help for any command in the application.
Simply type mixc help [path to command] for full details.
```
mixc help [command] [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--trace_jaeger_url <string>||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default "")
|--trace_log_spans ||Whether or not to log trace spans. 
|--trace_zipkin_url <string>||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default "")


## mixc report

The Report method is used to produce telemetry. Mixer
expects a set of attributes as input, which it uses, along with
its configuration, to determine which adapters to invoke and with
which parameters in order to output the telemetry.
```
mixc report [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--attributes <string>|-a|List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...  (default "")
|--bool_attributes <string>|-b|List of name/value bool attributes specified as name1=value1,name2=value2,...  (default "")
|--bytes_attributes <string>||List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...  (default "")
|--double_attributes <string>|-d|List of name/value float64 attributes specified as name1=value1,name2=value2,...  (default "")
|--duration_attributes <string>||List of name/value duration attributes specified as name1=value1,name2=value2,...  (default "")
|--int64_attributes <string>|-i|List of name/value int64 attributes specified as name1=value1,name2=value2,...  (default "")
|--mixer <string>|-m|Address and port of a running Mixer instance  (default "localhost:9091")
|--repeat <int>|-r|Sends the specified number of requests in quick succession  (default 1)
|--string_attributes <string>|-s|List of name/value string attributes specified as name1=value1,name2=value2,...  (default "")
|--stringmap_attributes <string>||List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...  (default "")
|--timestamp_attributes <string>|-t|List of name/value timestamp attributes specified as name1=value1,name2=value2,...  (default "")
|--trace_jaeger_url <string>||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default "")
|--trace_log_spans ||Whether or not to log trace spans. 
|--trace_zipkin_url <string>||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default "")


## mixc version

Prints out build version information
```
mixc version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--short |-s|Displays a short form of the version information 
|--trace_jaeger_url <string>||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default "")
|--trace_log_spans ||Whether or not to log trace spans. 
|--trace_zipkin_url <string>||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default "")

