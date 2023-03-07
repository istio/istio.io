#!/usr/bin/env python3
# This script copies the supported k8s versions from the latest entry in support status to master

import yaml
import sys

matrix_path = '../data/compatibility/supportStatus.yml'

# Needed since retaining YAML comments requires extra libraries
yaml_header = """
# Please keep entries ordered descending by version.
# The order will be retained while rendering the
# data into the support_status_table shortcode
""".lstrip() # remove leading newline

# Subclass built-in types
class flow_seq(list): pass # forces inline list
class quoted(str): pass # forces double quotes

# Customize how YAML is displayed (d = dumper; v = value)
yaml.add_representer(flow_seq, lambda d, v: d.represent_sequence('tag:yaml.org,2002:seq', v, flow_style=True))
yaml.add_representer(quoted, lambda d, v: d.represent_scalar('tag:yaml.org,2002:str', v, style='"'))
yaml.add_representer(type(None), lambda d, v: d.represent_scalar('tag:yaml.org,2002:null', '')) # empty null lines

# Disables unneeded anchors
yaml.Dumper.ignore_aliases = lambda s, d: True

try:
    with open(matrix_path) as stream:
        data = yaml.safe_load(stream)

except yaml.YAMLError as exc:
    sys.stderr.write('Failed to load data from "{}"\n'.format(matrix_path))
    if hasattr(exc, 'problem_mark'):
        if exc.context:
            print("{}\n{} {}".format(exc.problem_mark, exc.problem, exc.context).strip())
        else:
            print("{}\n{}".format(exc.problem_mark, exc.problem).strip())
    sys.exit(1)

# Iterate through each property and apply representers
for (istio_idx, istio_info) in enumerate(data):
    for key in istio_info:
        if data[istio_idx][key]:
            if key in ["k8sVersions", "testedK8sVersions"]:
                for (k8s_idx, k8s_ver) in enumerate(data[istio_idx][key]):
                    data[istio_idx][key][k8s_idx] = quoted(data[istio_idx][key][k8s_idx])
                data[istio_idx][key] = flow_seq(data[istio_idx][key])
            else:
                data[istio_idx][key] = quoted(data[istio_idx][key])

# Set first entry (master) to latest release's k8sVersions
data[0]['k8sVersions'] = data[1]['k8sVersions']

try:
    with open(matrix_path, "w") as f:
        f.write(yaml_header) # place header comments at top of file
        yaml.dump(data, f, indent=2, default_flow_style=False, sort_keys=False, Dumper=yaml.Dumper)
    print('"{}" updated.'.format(matrix_path))
except:
    sys.stderr.write('Failed to write to "{}"\n'.format(matrix_path))
    sys.exit(1)
