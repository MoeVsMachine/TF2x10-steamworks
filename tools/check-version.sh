#!/usr/bin/env bash
# Check that the version numbers agree, and optionally that a release tag matches.
#
#   ./tools/check-version.sh            # source <-> update.txt
#   ./tools/check-version.sh 1.7.8      # ...and the tag being released
#
# The release version is the tf2x10 plugin version: update.txt drives the Updater
# plugin, which compares its "Latest" against the version the running plugin
# reports, so the two drifting apart means update prompts that never resolve.
# The randomizer has its own version and is reported separately.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tag=${1:-}

read_version() {
	# #define PLUGIN_VERSION "x.y.z"
	sed -n 's/^#define[[:space:]]\+PLUGIN_VERSION[[:space:]]\+"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

tf2x10=$(read_version "$root/addons/sourcemod/scripting/tf2x10.sp")
randomizer=$(read_version "$root/addons/sourcemod/scripting/tf2items_randomizer_x10.sp")
latest=$(sed -n 's/^[[:space:]]*"Latest"[[:space:]]*"\([^"]*\)".*/\1/p' "$root/addons/sourcemod/update.txt" | head -n 1)

printf 'tf2x10.sp        %s\n' "${tf2x10:-<missing>}"
printf 'update.txt       %s\n' "${latest:-<missing>}"
printf 'randomizer       %s\n' "${randomizer:-<missing>}"

fail=0
if [ -z "$tf2x10" ] || [ -z "$latest" ]; then
	echo "error: could not read a version from tf2x10.sp and/or update.txt" >&2
	fail=1
elif [ "$tf2x10" != "$latest" ]; then
	echo "error: tf2x10.sp says $tf2x10 but update.txt says $latest" >&2
	fail=1
fi

if [ -n "$tag" ] && [ "$tag" != "$tf2x10" ]; then
	echo "error: tag $tag does not match the plugin version $tf2x10" >&2
	fail=1
fi

if [ "$fail" -eq 0 ]; then
	echo "ok"
fi
exit "$fail"
