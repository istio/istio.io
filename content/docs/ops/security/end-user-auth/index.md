---
title: End User Authentication
description: What to do if end-user authentication doesn't work.
weight: 80
aliases:
    - /help/ops/security/end-user-auth
---

With Istio, you can enable authenticating end user. Currently, the end user credential supported by the Istio authentication policy is JWT.
The following is a guide for troubleshooting the end user JWT authentication.

1. Check your Istio authentication policy, `principalBinding` should be set as `USE_ORIGIN` to authenticate the end user.

1. If `jwksUri` isn’t set, make sure the JWT issuer is of url format and `url + /.well-known/openid-configuration` can be opened in browser; for example, if the JWT issuer is `https://accounts.google.com`, make sure `https://accounts.google.com/.well-known/openid-configuration` is a valid url and can be opened in a browser.

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "example-3"
    spec:
      targets:
      - name: httpbin
      peers:
      - mtls:
      origins:
      - jwt:
          issuer: "628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
          jwksUri: "https://www.googleapis.com/service_accounts/v1/jwk/628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
      principalBinding: USE_ORIGIN
    {{< /text >}}

1. If the JWT token is placed in the Authorization header in http requests, make sure the JWT token is valid (not expired, etc). The fields in a JWT token can be decoded by using online JWT parsing tools, e.g., [jwt.io](https://jwt.io/).

1. Get the Istio proxy (i.e., Envoy) logs to verify the configuration which Pilot distributes is correct.

    For example, if the authentication policy is enforced on the `httpbin` service in the namespace `foo`, use the command below to get logs from the Istio proxy, make sure `local_jwks` is set and the http response code is in the Istio proxy logs.

    {{< text bash >}}
    $ kubectl logs httpbin-68fbcdcfc7-hrnzm -c istio-proxy -n foo
    [2018-07-04 19:13:30.762][15][info][config] ./src/envoy/http/jwt_auth/auth_store.h:72] Loaded JwtAuthConfig: rules {
      issuer: "628645741881-noabiu23f5a8m8ovd8ucv698lj78vv0l@developer.gserviceaccount.com"
      local_jwks {
        inline_string: "{\n \"keys\": [\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"03bc39a6b56602c0d2ad421c3993d5e4f88e6f54\",\n   \"n\": \"u9gnSMDYw4ggVKInAfxpXqItv9Ii7PlUFrAcwANQMW9fbZrFpITFD45t0gUy9CK4QewkLhqDDUJSvpH7wprS8Hi0M8wAJf_lgugdRr6Nc2qK-eywjjDK-afQjhGLcMJGS0YXi3K2lyP-oWiLingMbYRiJxTi86icWT8AU8bKoTyTPFOExAJkDFnquulU0_KlteZxbjnRIVvMKfpgZ3yK9Pzv7XjtdvO7xlr59K9Zotd4mgphIUADfw1fR0lNkjHQp9N0WP9cbOsyUwm5jjDklnyVh7yBHcEk1YHccntosxnwIn-cj538PSaL_qDZgDAsJKHPZlkiP_1mjsu3NkofIQ\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"60aef5b0877e9f0d67b787b5be797636735efdee\",\n   \"n\": \"0TmzDEN12GF9UaWJI40oKwJlu53ZQihHcaVi1thLGs1l3ubdPWv8MEsc9X2DjCRxEB6Ss1R2VOImrQ2RWFuBSNHorjE0_GyEGNzvOH-0uUQ5uES2HvEN7384XfUYj9MoTPibstDEl84pm4d3Ka3R_1wk03Jrl9MIq6fnV_4Z-F7O7ElGqk8xcsiVUowd447dwlrd55ChIyISF5PvbCLtOKz9FgTz2mEb8jmzuZQs5yICgKZCzlJ7xNOOmZcqCZf9Qzaz4OnVLXykBLzSuLMtxvvOxf53rvWB0F2__CjKlEWBCQkB39Zaa_4I8dCAVxgkeQhgoU26BdzLL28xjWzdbw\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"62a93512c9ee4c7f8067b5a216dade2763d32a47\",\n   \"n\": \"0YWnm_eplO9BFtXszMRQNL5UtZ8HJdTH2jK7vjs4XdLkPW7YBkkm_2xNgcaVpkW0VT2l4mU3KftR-6s3Oa5Rnz5BrWEUkCTVVolR7VYksfqIB2I_x5yZHdOiomMTcm3DheUUCgbJRv5OKRnNqszA4xHn3tA3Ry8VO3X7BgKZYAUh9fyZTFLlkeAh0-bLK5zvqCmKW5QgDIXSxUTJxPjZCgfx1vmAfGqaJb-nvmrORXQ6L284c73DUL7mnt6wj3H6tVqPKA27j56N0TB1Hfx4ja6Slr8S4EB3F1luYhATa1PKUSH8mYDW11HolzZmTQpRoLV8ZoHbHEaTfqX_aYahIw\",\n   \"e\": \"AQAB\"\n  },\n  {\n   \"kty\": \"RSA\",\n   \"alg\": \"RS256\",\n   \"use\": \"sig\",\n   \"kid\": \"b3319a147514df7ee5e4bcdee51350cc890cc89e\",\n   \"n\": \"qDi7Tx4DhNvPQsl1ofxxc2ePQFcs-L0mXYo6TGS64CY_2WmOtvYlcLNZjhuddZVV2X88m0MfwaSA16wE-RiKM9hqo5EY8BPXj57CMiYAyiHuQPp1yayjMgoE1P2jvp4eqF-BTillGJt5W5RuXti9uqfMtCQdagB8EC3MNRuU_KdeLgBy3lS3oo4LOYd-74kRBVZbk2wnmmb7IhP9OoLc1-7-9qU1uhpDxmE6JwBau0mDSwMnYDS4G_ML17dC-ZDtLd1i24STUw39KH0pcSdfFbL2NtEZdNeam1DDdk0iUtJSPZliUHJBI_pj8M-2Mn_oA8jBuI8YKwBqYkZCN1I95Q\",\n   \"e\": \"AQAB\"\n  }\n ]\n}\n"
      }
      forward: true
      forward_payload_header: "istio-sec-8a85f33ec44c5ccbaf951742ff0aaa34eb94d9bd"
    }
    allow_missing_or_failed: true
    [2018-07-04 19:13:30.763][15][info][upstream] external/envoy/source/server/lds_api.cc:62] lds: add/update listener '10.8.2.9_8000'
    [2018-07-04T19:13:39.755Z] "GET /ip HTTP/1.1" 401 - 0 29 0 - "-" "curl/7.35.0" "e8374005-1957-99e4-96b6-9d6ec5bef396" "httpbin.foo:8000" "-"
    [2018-07-04T19:13:40.463Z] "GET /ip HTTP/1.1" 401 - 0 29 0 - "-" "curl/7.35.0" "9badd659-fa0e-9ca9-b4c0-9ac225571929" "httpbin.foo:8000" "-"
    {{< /text >}}
