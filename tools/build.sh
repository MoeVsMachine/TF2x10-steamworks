#!/usr/bin/env bash
# Build every plugin in addons/sourcemod/scripting.
#
#   ./tools/build.sh [output-dir]      # default: build
#
# Downloads the pinned SourceMod compiler and the pinned third-party includes,
# so a clean checkout builds without any local setup. CI runs the same script.
#
# Override any pin from the environment to test a different release:
#   SM_URL=... ./tools/build.sh
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out_dir=${1:-build}
scripting="$repo_root/addons/sourcemod/scripting"

SM_VERSION=${SM_VERSION:-1.12.0.7255}
# Pinned to the GitHub release, not sm.alliedmods.net/smdrop: that tree prunes old
# builds and its sourcemod-latest-linux pointer has been returning 404.

SM_URL=${SM_URL:-https://github.com/alliedmodders/sourcemod/releases/download/${SM_VERSION}/sourcemod-1.12.0-git7255-linux.tar.gz}

# Third-party includes, pinned by commit. The plugins #tryinclude the first four;
# tf2items_giveweapon and visweps are optional integrations that are left out
# unless the matching plugin is present, exactly as before.
TF2ITEMS_SHA=${TF2ITEMS_SHA:-e350812}
TF2ATTRIBUTES_SHA=${TF2ATTRIBUTES_SHA:-eb4006a}
STEAMWORKS_SHA=${STEAMWORKS_SHA:-f0c1b62}
UPDATER_SHA=${UPDATER_SHA:-3636ecd}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "SourceMod ${SM_VERSION}"
curl -fsSL "$SM_URL" -o "$work/sm.tar.gz"
mkdir -p "$work/sm"
tar -xzf "$work/sm.tar.gz" -C "$work/sm"
sm="$work/sm/addons/sourcemod/scripting"
# spcomp64 is the 64-bit compiler: it runs natively on x86_64 with no i386 sysroot.
test -x "$sm/spcomp64" || { echo "spcomp64 missing from the SourceMod tarball" >&2; exit 1; }

inc="$work/include"
mkdir -p "$inc"
echo "Includes"
curl -fsSL "https://raw.githubusercontent.com/asherkin/TF2Items/${TF2ITEMS_SHA}/pawn/tf2items.inc" -o "$inc/tf2items.inc"
curl -fsSL "https://raw.githubusercontent.com/FlaminSarge/tf2attributes/${TF2ATTRIBUTES_SHA}/scripting/include/tf2attributes.inc" -o "$inc/tf2attributes.inc"
curl -fsSL "https://raw.githubusercontent.com/KyleSanderson/SteamWorks/${STEAMWORKS_SHA}/Pawn/includes/SteamWorks.inc" -o "$inc/SteamWorks.inc"
curl -fsSL "https://raw.githubusercontent.com/sbpp/Updater-include-mirror/${UPDATER_SHA}/scripting/include/updater.inc" -o "$inc/updater.inc"

mkdir -p "$out_dir"
shopt -s nullglob
sources=("$scripting"/*.sp)
if [ ${#sources[@]} -eq 0 ]; then
	echo "no .sp files in $scripting" >&2
	exit 1
fi

for src in "${sources[@]}"; do
	name=$(basename "$src" .sp)
	# Deployed name, where it differs from the source file name: the x10 fork has
	# always shipped as plugins/tf2items_randomizer.smx.
	case "$name" in
		tf2items_randomizer_x10) out=tf2items_randomizer ;;
		*) out=$name ;;
	esac
	echo "Compiling $name -> $out.smx"
	"$sm/spcomp64" "$src" -i "$sm/include" -i "$inc" -o "$out_dir/$out.smx"
done

echo
ls -l "$out_dir"
