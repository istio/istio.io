import sys
import re
import os

linenum = 0
current_snip = None
multiline_cmd = False
output_started = False
snippets = []

HEADER="""####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE
####################################################################################################

"""

startsnip = re.compile(r"^(\s*){{< text (\w+) .*>}}$")
snippetid = re.compile(r"snip_id=(\w+)")
githubfile = re.compile("^([^@]*)@([\w\.\-_/]+)@([^@]*)$")

if len(sys.argv) < 2:
    print("usage: python snip.py mdfile [ snipdir ]")
    sys.exit(1)

markdown = sys.argv[1]

if len(sys.argv) > 2:
    snipdir = sys.argv[2]
else:
    snipdir = os.path.dirname(markdown)
   
snipfile = markdown.split('/')[-2] + "_snip.txt"

with open (markdown, 'rt') as mdfile:
    for line in mdfile:
        linenum += 1
        match = startsnip.match(line)
        if match:
            indent = match.group(1)
            kind = match.group(2)
            match = snippetid.search(line)
            if match:
                id = match.group(1)
            else:
                id = "snip_line_%d" % linenum
            if kind == "bash":
                script = "%s() {\n" % id
            else:
                script = "! read -r -d '' %s <<ENDSNIP\n" % id
            current_snip = { "start": linenum, "id": id, "kind": kind, "indent": indent, "script": ["", script] }
            snippets.append(current_snip)
        elif current_snip != None:
            if current_snip["indent"]:
                _,line = line.split(current_snip["indent"], 1)
            if "{{< /text >}}" in line:
                if current_snip["kind"] == "bash" and not output_started:
                    script = "}\n\n"
                else:
                    script = "ENDSNIP\n\n"
                current_snip["script"].append(script)
                current_snip = None
                multiline_cmd = False
                output_started = False
            else:
                if current_snip["kind"] == "bash":
                    if line.startswith("$ "):
                        line = line[2:]
                        match = githubfile.match(line)
                        if match:
                           line = match.group(1) + match.group(2) + match.group(3)
                        if "<<EOF" in line:
                            multiline_cmd = True
                    elif not multiline_cmd:
                        # command output
                        if not output_started:
                            current_snip["script"].append("}\n\n! read -r -d '' %s_out <<ENDSNIP\n" % id)
                            output_started = True
                current_snip["script"].append(line)

with open(os.path.join(snipdir, snipfile), 'w') as f:
    f.write(HEADER)
    for snippet in snippets:
        lines = snippet["script"]
        for line in lines:
            f.write(line)
