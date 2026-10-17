# Reproducing the authorization example

Live policy verification is pending. The article describes expected outcomes, not completed runtime checks.

Download the [public reproduction archive](public-reproduction-istio-v8.tar.gz), [setup and cleanup guide](public-package/REPRODUCE.md), and [package manifest](public-package/PUBLIC_MANIFEST.json). The archive contains the complete package, including the custom kind launcher, its source, patch and license. Extract it into a fresh directory using the guide; the website provides the guide and manifest separately for inspection.

SHA-256 pins:

```text
public-reproduction-istio-v8.tar.gz
5faec38993a4db2a6db46bf468c2e1f643ce381420dba30c72a3d721f2f19f4d

PUBLIC_MANIFEST.json
10e9f72118a2d4dd0c180d1b705a0fb4ccd9d822bb52711535147454887b9243
```

Use a fresh isolated cluster. Supply operator configuration and explicit launcher authorization outside the package; the shipped configuration and authorization files are templates. No private host, kubeconfig or caller credentials are required from the author.

The complete lifecycle includes preparation, two serial 21-obligation/63-request suites, independent export verification and supervised cleanup. Check denial attribution, complete sorted ledger states, policy convergence and permitted-call controls before treating any expected outcome as an observed result. The guide specifies the resource limits and cleanup requirements.
