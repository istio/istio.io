# Whole Istio V8 reproduction

This package is source-only. It has not run a live cluster. The shipped launcher approval and operator config are false templates. Supply your own explicit decision and host data outside the package. Do not edit shipped bytes.

## Requirements

Linux amd64; `/usr/bin/python3` exactly Python 3.10.12; local Docker with cgroup v2, memory/swap/CPU limits and `/var/lib/docker`; Linux `prctl` child subreapers, pidfds, `/proc` and cgroup observations; writable `/var/tmp`; two free loopback API ports. Python standard library only. Use two terminals on this same host for independent export verification. No SSH, cloud account, private hostname or historical machine baseline is required by this recipe.

Runtime preparation downloads the exact upstream kind v0.33.0 binary for provenance, kubectl v1.36.4 and Istio 1.31.1. It executes the supplied exact custom kind binary `55ccf762eb3975ad00f7d51fbc37d0b813c93a93ac4f84eb6f61c548e46ecfa2`. The official release binary is distinct. Launcher source, patch and Apache-2.0 license are in `launcher/`. Tool and image pins remain in `v8/source/prepare.py`; the app uses the exact pinned Python base image. Downloads need outbound access on the operator's host.

Keep unchanged: cumulative disk cap 8 GiB, 25 GiB host free, disk use below 94%, free inodes above 100,000, preflight available RAM 10 GiB, monitored available RAM 2 GiB, existing node/cgroup caps and 4 MiB x 2 node logs. Phase limits remain prepare 1,200 seconds, setup 1,200, serial runtime 4,560, deletion 60. One absolute 7,080-second deadline starts before input checks. V8 matrix limit stays 900 seconds; existing diagnostic deadlines stay 60 seconds; each independently verified export return stays 180 seconds. Supervised commands reserve up to 15 seconds and checker children reserve 5 seconds for cancellation/drain within that same absolute deadline. These reserves reduce the remaining wait; they never extend any cap. No retry or budget reset.

## Before allocation

Remove any old owned lab residue in a separately reviewed operation. Record its exact IDs/names in `prior_owned_absence`; the neutral tool only checks absence. On a genuinely new host use empty arrays and explicitly attest `separately_verified:true`. It never cleans old residue.

Measure your own original pre-allocation budget **before downloading/extracting lab content**. Save this external JSON. If continuing an existing budget chain, carry its original baseline, original devices and latest measured peaks unchanged. Never replace it with the current measurement.

```json
{
  "schema": "istio-budget-v1",
  "hostname": "ACTUAL_OWN_HOSTNAME",
  "cap_bytes": 8589934592,
  "provenance": "Describe actual pre-allocation observation or original carried budget chain",
  "captured_at_gst": "ACTUAL_TIMESTAMP GST",
  "root": {"device": 0, "baseline_used_bytes": 0, "latest_peak_used_bytes": 0},
  "docker": {"device": 0, "baseline_used_bytes": 0, "latest_peak_used_bytes": 0}
}
```

For `/` and `/var/lib/docker`, get `device = os.stat(path).st_dev` and `used = (os.statvfs(path).f_blocks - os.statvfs(path).f_bfree) * os.statvfs(path).f_frsize`. Use actual positive integers, never the zero placeholders. On a new chain latest peak equals its measured baseline. On a carried chain latest peak must include all intervening allocations, retained images and evidence. Missing provenance is fatal. The runner never creates a replacement baseline.

On a new host, this explicit read-only command prints an original-budget JSON from actual measurements. Redirect it to your external fresh budget file before downloading the package. Do not run it to replace an existing chain:

```sh
/usr/bin/python3 -B -c 'import datetime,json,os,socket; zone=datetime.timezone(datetime.timedelta(hours=4)); value=dict(schema="istio-budget-v1",hostname=socket.gethostname(),cap_bytes=8589934592,provenance="Explicit operator pre-allocation statvfs measurement",captured_at_gst=datetime.datetime.now(zone).strftime("%Y-%m-%d %H:%M:%S GST"));
for key,path in [("root","/"),("docker","/var/lib/docker")]:
 s=os.statvfs(path); used=(s.f_blocks-s.f_bfree)*s.f_frsize; value[key]=dict(device=os.stat(path).st_dev,baseline_used_bytes=used,latest_peak_used_bytes=used)
print(json.dumps(value,indent=2))' > /absolute/fresh-original-budget.json
```

Obtain archive and PUBLIC_MANIFEST SHA-256 pins through the external release handoff. Check the archive against its external pin **before extraction**. The tar contains only relative regular files at its top level. Extract into a new private directory with Python 3.10.12 with the bounded command below. The runner checks the actual archive hash, exact archive inventory, every extracted asset, exact current PUBLIC_MANIFEST, repinned public source manifest and custom launcher before staging. Keep the original pinned archive available outside the extraction.

Exact bounded fresh extraction command, with your externally received archive SHA as the third argument:

```sh
/usr/bin/python3 -B -c 'import hashlib,json,pathlib,sys,tarfile

def path(value):
 result=pathlib.Path(value)
 assert result.is_absolute()
 assert not any(item.is_symlink() for item in (result,*result.parents))
 return result

def unique(pairs):
 result={}
 for key,value in pairs:
  assert key not in result
  result[key]=value
 return result

def members(source):
 result=source.getmembers()
 names=[item.name for item in result]
 assert 0<len(result)<=100 and len(set(names))==len(names)
 for item in result: member(item)
 return result

def member(item):
 relative=pathlib.PurePosixPath(item.name)
 assert item.isfile() and not item.issparse() and 0<=item.size<=16777216
 assert not relative.is_absolute() and ".." not in relative.parts
 assert relative.as_posix()==item.name

def checked(source,items,manifest_pin):
 payload={item.name:source.extractfile(item).read() for item in items}
 assert hashlib.sha256(payload["PUBLIC_MANIFEST.json"]).hexdigest()==manifest_pin
 manifest=json.loads(payload["PUBLIC_MANIFEST.json"],object_pairs_hook=unique)
 assert set(payload)==set(manifest["files"])|{"PUBLIC_MANIFEST.json"}
 for name,pin in manifest["files"].items():
  assert hashlib.sha256(payload[name]).hexdigest()==pin
 return payload

def extract(payload,destination):
 destination.mkdir(mode=448)
 for name,content in payload.items():
  target=destination/name
  target.parent.mkdir(parents=True,exist_ok=True)
  with target.open("xb") as output: output.write(content)

archive=path(sys.argv[1]); destination=path(sys.argv[2]); expected=sys.argv[3]; manifest_pin=sys.argv[4]
assert not destination.exists() and archive.stat().st_size<33554432
assert hashlib.sha256(archive.read_bytes()).hexdigest()==expected
with tarfile.open(archive) as source:
 payload=checked(source,members(source),manifest_pin)
extract(payload,destination)' \
  /absolute/public-reproduction-istio-v8.tar.gz /absolute/fresh-package EXTERNAL_ARCHIVE_SHA256 EXTERNAL_PUBLIC_MANIFEST_SHA256
```

Copy templates to absolute external paths. Fill every placeholder, choose two unique run IDs/clusters/networks/nodes/contexts and free ports. Use a fresh staging root `/var/tmp/technical-blogs-20261009-istio-YOUR-FRESH-SUFFIX`. This prefix is required by the unchanged V8 `safe_root`; the suffix and hostname are yours. Package, staging and exchange must be separate non-overlapping paths without symlink ancestors. Exchange must not exist and its parent must exist.

In operator config set `execution_approved:true` and `preserve_current_foreign:true` only after your explicit approval. Pin the original budget file, archive and public manifest. Then hash the finished operator config. In the external launcher authorization supply that exact config hash, your actor and actual approval provenance, with `approved:true`. The shipped template provides the exact binary and contract pins. No real human grant is included.

The runner captures a fresh current inventory of every foreign container, including stopped containers, plus foreign networks, image IDs, volumes and the host setting. It preserves every captured member throughout; it distinguishes those from the two declared fresh owned runs. A changed or missing foreign member fails the run. It never removes or modifies foreign resources.

## Terminal 1: complete lifecycle

From the fresh extracted package:

```sh
/usr/bin/python3 -B public_lifecycle.py run \
  --operator-config /absolute/operator.json \
  --launcher-authorization /absolute/launcher-authorization.json \
  --exchange-dir /absolute/fresh-exchange
```

Do not launch prepare/setup/runtime/deletion separately. The one outer monitor starts before staging/preparation and remains alive through prepare, setup, both serial 63-request suites, all three receipt returns, exact owned cleanup and staging deletion. Linux child subreapers retain owned orphan descendants. Observed real/effective/saved/filesystem UIDs, PID start times and pidfds bind ownership; UID drift rejects. Process groups never establish ownership. Every supervised child waits at a pipe execution gate until registration completes. Registration failure closes that gate, retains the spawned root and cancels/drains it and the owned forest before diagnostics. An unreaped direct child handle permits root cancellation; descendants use retained pidfds. Primary and cancellation errors both remain. Every host/probe allocation checks the original deadline before spawning. Resource and current foreign observations continue every five seconds and at closure.

## Terminal 2: independently verify all three exports

Wait for each `VERIFY_REQUEST` line in Terminal 1. The atomic request JSON names the actual archive and receipt target. For the example run IDs above, run these commands as soon as each request appears, within the unchanged 180-second runtime wait. Use fresh verification directories outside staging and the package; their allocation remains charged to the original host budget.

```sh
/usr/bin/python3 -B verify_and_return.py \
  --archive /absolute/fresh-exchange/evidence-operator-a-before-teardown.tar.gz \
  --run-id operator-a-before-teardown \
  --fresh-destination /absolute/fresh-verify-a \
  --receipt-target /absolute/fresh-exchange/receipt-operator-a-before-teardown.json

/usr/bin/python3 -B verify_and_return.py \
  --archive /absolute/fresh-exchange/evidence-operator-b-before-teardown.tar.gz \
  --run-id operator-b-before-teardown \
  --fresh-destination /absolute/fresh-verify-b \
  --receipt-target /absolute/fresh-exchange/receipt-operator-b-before-teardown.json

/usr/bin/python3 -B verify_and_return.py \
  --archive /absolute/fresh-exchange/evidence-cleanup-verified.tar.gz \
  --run-id cleanup-verified \
  --fresh-destination /absolute/fresh-verify-cleanup \
  --receipt-target /absolute/fresh-exchange/receipt-cleanup-verified.json
```

The verifier independently hashes the actual archive, records the strict public derivative `verify_export.py` child, rejects unsafe/undeclared members and hash drift, and requires the child actual natural exit 0 and complete bounded output drain before exclusive atomic receipt publication. Returned envelopes bind the exact five-field receipt, actual archive manifest/count, checker bytes, package manifest and checker output hashes. The outer bridge checks the returned ID/SHA/manifest and relays it to the exact unchanged runtime wait path. Never manufacture receipts. A failed verification returns no receipt. The verifier is a distinct operator process; this local receipt contract is not cryptographic attestation of a remote identity.

## Public evidence boundary

`v8/source/public-evidence-schema.json` declares the exact public artifact models. Export produces `istio-public-evidence-v1` envelopes with path, original-byte SHA and projected data. The independently executed checker rejects additional fields at every declared object. Raw Docker Config/HostConfig/Env, raw certificate material, grants and private argv are excluded. Node caps/log rotation, image/source/report bindings, original assertion observations, full ledger/audit rows, policy/RBAC rules, selected route/TLS/SDS facts, pod identities and certificate SAN/validity metadata remain. Source files are pinned, with prepared manifests restricted to the exact reviewed render shape. Original hashes describe original bytes; archive manifest hashes describe projected bytes.

Proxy-status and comparison streams become closed structured rows and results with original stream SHA-256 hashes. The supported status header is `NAME CLUSTER CDS LDS EDS RDS ECDS ISTIOD VERSION`; rows use the declared lab proxy identities, Kubernetes cluster, named Istiod controller, Istio 1.31.1 and declared xDS states. Approved SYNCED ages normalize through the unchanged V8 age parser. All three comparison domains remain. The producer and independent checker reject unknown raw streams, private argv/environment text and undeclared structured fields even when archive hashes are recomputed. Gate sync columns use the same closed row schema. Literal reviewed assertion failures remain; unsupported failure messages retain their original SHA instead of arbitrary text. Command proof retains approved operation, observed exit/time and original argv SHA; it never exports raw argv. No recursive commands/logs, Docker dumps, certificates, environment or human authorization are exported. Any unsupported artifact shape fails instead of substituting another format.

## Completion and retained evidence

`lifecycle.completion.json` in exchange indicates observed whole-lifecycle phase closure. It requires actual natural exit 0 and drained output for all four phase children, both exact 63-request result sets, all three independent verifier receipts, cleanup verification, absent staging root and a final successful monitor observation. Also record Terminal 1's actual exit and complete output drain using your external process recorder. The independent verifier parent records its checker child exit/drain. The supervisor cannot attest to its own future natural exit; its receipt explicitly requires that external completion. Missing completion or `lifecycle.failure.json` means failure. A source-only/local fake-world control receipt grants no runtime success.

Exchange retains the three bounded allowlisted exports, returned receipts, requests, phase output/hash/exit receipts, original-budget binding, current foreign binding, full-chain resource observations and final lifecycle receipt. Verification directories retain strictly checked exports. Staging is deleted only after the final verified cleanup export. Exchange and independent verification directories remain operator-owned evidence and charged to the same cumulative budget. On failure, owned resources may remain allocated for a separately reviewed cleanup; there is no automatic old-residue deletion, pruning, resize or alternate host path.

`v8/REPRODUCE.md` identifies this public derivative and points to the complete entrypoint. This top-level guide is the complete public lifecycle entrypoint. The original private V8 remains unchanged. Cases, app/client, policy, TLS and routing source bytes are retained. Public runtime/evidence adapters carry the original deadline through command drains and final observations. Public exporter/checker/source manifest are explicitly repinned; transformed evidence is not byte-identical private evidence. New adapters require independent source review before any live run.
