#!/usr/bin/env python3
# This script copies the supported k8s versions from the latest entry in support status to master

import yaml
import sys

matrix_path = '../data/compatibility/supportStatus.yml'

# Needed because updating yaml while retaining comments requires extra libraries
yaml_header = """
# Please keep entries ordered descending by version.
# The order will be retained while rendering the
# data into the support_status_table shortcode
"""

# Subclass built-in str type to use double quotes
class quoted(str): pass
class flow_seq(list): pass

# Customize how YAML is displayed (d = dumper; v = value)
yaml.add_representer(quoted, lambda d, v: d.represent_scalar('tag:yaml.org,2002:str', v, style='"'))
yaml.add_representer(type(None), lambda d, v: d.represent_scalar('tag:yaml.org,2002:null', ''))

# Test list class
yaml.add_representer(flow_seq, lambda d, v: d.represent_sequence('tag:yaml.org,2002:seq', v, flow_style=True))
# yaml.add_representer(type(list), lambda d, v: d.represent_scalar('tag:yaml.org,2002:seq', ''))

with open(matrix_path) as stream:
    #data = yaml.safe_load(stream)
    data = yaml.load(stream, yaml.FullLoader)

# Quote the data for readability and forced string type
for (istio_idx, istio_info) in enumerate(data):
    for key in istio_info:
        if data[istio_idx][key]:
            if key in ["k8sVersions", "testedK8sVersions"]:
                for (k8s_idx, k8s_ver) in enumerate(data[istio_idx][key]):
                    data[istio_idx][key][k8s_idx] = quoted(data[istio_idx][key][k8s_idx])
                data[istio_idx][key] = flow_seq(data[istio_idx][key])
            else:
                data[istio_idx][key] = quoted(data[istio_idx][key])

data[0]['k8sVersions'] = data[1]['k8sVersions']

yaml.Dumper.ignore_aliases = lambda s, d: True
yaml.dump(data, sys.stdout, indent=2, default_flow_style=None, explicit_start=True, sort_keys=False, Dumper=yaml.Dumper)

# yaml.dump(data, sys.stdout, indent=2, default_flow_style=False, explicit_start=True)

#with open(matrix_path) as stream:
#    data = yaml.safe_load(stream)
#
#try:
#    data[0]['k8sVersions'] = data[1]['k8sVersions']
#    print('"{}" updated.'.format(matrix_path))
#    with open(matrix_path, "w") as f:
#      #yaml.dump(data, f, default_flow_style=False)
#      yaml.dump(data, sys.stdout, indent=4, default_flow_style=False, explicit_start=True)
#
#except:
#    sys.stderr.write('failed to retrieve data from "{}"\n'.format(matrix_path))
#    sys.exit(1)
