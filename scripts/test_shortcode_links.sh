#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exercise the real shortcode templates and site configuration with a small site.
# Requires Hugo on PATH. Run from any directory.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SITE=$(mktemp -d)
trap 'rm -rf "$SITE"' EXIT

mkdir -p "$SITE/layouts/_default"
cp "$ROOT/hugo.toml" "$SITE/hugo.toml"
cp -R "$ROOT/layouts/shortcodes" "$ROOT/layouts/partials" "$SITE/layouts/"
cat > "$SITE/test.toml" <<'EOF'
enableGitInfo = false
[outputs]
home = ["HTML"]
EOF
printf '{{ .Content }}' > "$SITE/layouts/_default/single.html"
printf '{{ .Content }}' > "$SITE/layouts/_default/list.html"

SHORTCODES=(warning tip idea quote tabset centered_block involve_block multi_block feature_block)
LANGUAGES=(en zh es uk)

for lang in "${LANGUAGES[@]}"; do
    mkdir -p "$SITE/content/$lang/docs/target"
    printf '%s\n' '---' 'title: Home' '---' > "$SITE/content/$lang/_index.md"
    printf '%s\n' '---' 'title: Target' '---' '## Target' > "$SITE/content/$lang/docs/target/index.md"
    for shortcode in "${SHORTCODES[@]}"; do
        page="$SITE/content/$lang/docs/$shortcode"
        mkdir -p "$page"
        printf 'page resource\n' > "$page/asset.txt"
        {
            printf '%s\n' '---' "title: $shortcode" '---'
            printf '{{< %s >}}\n' "$shortcode"
            if [[ "$shortcode" == tabset ]]; then
                printf '{{< tab name="Example" >}}\n'
            fi
            cat <<'EOF'
[Same page](#target) [Other page](../target/#target)
[Resource](asset.txt) [External](https://example.org/guide/#target)

{{< text syntax="plain" expandlinks="false" >}}
parent:
  child: <value>
{{< /text >}}
EOF
            if [[ "$shortcode" == tabset ]]; then
                printf '{{< /tab >}}\n'
            fi
            printf '{{< /%s >}}\n\n## Target\n' "$shortcode"
        } > "$page/index.md"
    done
done

FAILED=0
check() {
    local expected=$1
    local file=$2
    if ! grep -Fq -- "$expected" "$file"; then
        echo "FAIL: ${file#"$SITE/"}: missing $expected"
        if [[ "$FAILED" -eq 0 ]]; then
            cat "$file"
        fi
        FAILED=1
    fi
}

# Cover production/deploy-preview URLs with /latest, as well as a site at /.
for prefix in "" /latest; do
    base="https://example.org$prefix"
    hugo --source "$SITE" --config hugo.toml,test.toml --baseURL "$base/" --quiet
    for lang in "${LANGUAGES[@]}"; do
        language_path="/$lang"
        if [[ "$lang" == en ]]; then
            language_path=""
        fi
        for shortcode in "${SHORTCODES[@]}"; do
            html="$SITE/public$language_path/docs/$shortcode/index.html"
            check "href=\"$base$language_path/docs/$shortcode/#target\"" "$html"
            check 'href="../target/#target"' "$html"
            check "href=\"$base$language_path/docs/$shortcode/asset.txt\"" "$html"
            check 'href="https://example.org/guide/#target"' "$html"
            check '  child: &lt;value&gt;' "$html"
        done
    done
done

if [[ "$FAILED" -ne 0 ]]; then
    exit 1
fi
echo "PASS: shortcode links and nested code in four languages at / and /latest/."
