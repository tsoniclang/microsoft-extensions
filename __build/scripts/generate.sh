#!/bin/bash
# Generate TypeScript declarations for Microsoft.Extensions.* from the ASP.NET Core shared framework.
#
# Prerequisites:
#   - .NET 10 SDK installed
#   - dotnet-bindgen repository cloned at ../dotnet-bindgen (sibling directory)
#   - @tsonic/dotnet cloned at ../dotnet (sibling directory)
#
# Usage:
#   ./__build/scripts/generate.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTNET_BINDGEN_DIR="$PROJECT_DIR/../dotnet-bindgen"
DOTNET_MAJOR="${DOTNET_MAJOR:-10}"
DOTNET_LIB="$PROJECT_DIR/../dotnet/versions/$DOTNET_MAJOR"

resolve_shared_framework_path() {
    local framework="$1"
    local version="${DOTNET_VERSION:-}"
    if [ -n "$version" ]; then
        local explicit
        explicit="$(dotnet --list-runtimes | awk -v framework="$framework" -v version="$version" '$1 == framework && $2 == version { root=$3; gsub(/^\[/, "", root); gsub(/\]$/, "", root); print root "/" $2; exit }')"
        if [ -n "$explicit" ]; then
            echo "$explicit"
            return
        fi
        echo "${DOTNET_HOME:-$HOME/.dotnet}/shared/$framework/$version"
        return
    fi

    local resolved
    resolved="$(dotnet --list-runtimes | awk -v framework="$framework" -v major="$DOTNET_MAJOR" '$1 == framework && index($2, major ".") == 1 { root=$3; gsub(/^\[/, "", root); gsub(/\]$/, "", root); print $2 "|" root }' | sort -t '|' -k1,1V | tail -1)"
    if [ -z "$resolved" ]; then
        echo "ERROR: No installed $framework runtime found for .NET major $DOTNET_MAJOR" >&2
        exit 1
    fi

    echo "${resolved#*|}/${resolved%%|*}"
}

NETCORE_RUNTIME_PATH="$(resolve_shared_framework_path Microsoft.NETCore.App)"
ASPNET_RUNTIME_PATH="$(resolve_shared_framework_path Microsoft.AspNetCore.App)"

echo "================================================================"
echo "Generating Microsoft.Extensions.* TypeScript Declarations"
echo "================================================================"
echo ""
echo "Configuration:"
echo "  .NET Runtime:      $NETCORE_RUNTIME_PATH"
echo "  ASP.NET Runtime:   $ASPNET_RUNTIME_PATH"
echo "  BCL Library:       $DOTNET_LIB (external reference)"
echo "  dotnet-bindgen:         $DOTNET_BINDGEN_DIR"
echo "  Output:            $PROJECT_DIR"
echo "  Naming:            CLR (no transforms)"
echo ""

# Verify prerequisites
if [ ! -d "$NETCORE_RUNTIME_PATH" ]; then
    echo "ERROR: .NET runtime not found at $NETCORE_RUNTIME_PATH"
    echo "Set DOTNET_HOME or DOTNET_VERSION environment variables"
    exit 1
fi

if [ ! -d "$ASPNET_RUNTIME_PATH" ]; then
    echo "ERROR: ASP.NET runtime not found at $ASPNET_RUNTIME_PATH"
    echo "Set DOTNET_HOME or DOTNET_VERSION environment variables"
    exit 1
fi

if [ ! -d "$DOTNET_BINDGEN_DIR" ]; then
    echo "ERROR: dotnet-bindgen not found at $DOTNET_BINDGEN_DIR"
    echo "Clone it: git clone https://github.com/tsoniclang/dotnet-bindgen ../dotnet-bindgen"
    exit 1
fi

if [ ! -d "$DOTNET_LIB" ]; then
    echo "ERROR: @tsonic/dotnet not found at $DOTNET_LIB"
    echo "Clone it: git clone https://github.com/tsoniclang/dotnet ../dotnet"
    exit 1
fi

# Clean output directory (keep config files)
echo "[1/3] Cleaning output directory..."
cd "$PROJECT_DIR"

# Remove all namespace directories (but keep config files, __build, node_modules, .git)
find . -maxdepth 1 -type d \
    ! -name '.' \
    ! -name '.git' \
    ! -name '.tests' \
    ! -name 'node_modules' \
    ! -name '__build' \
    -exec rm -rf {} \; 2>/dev/null || true

# Remove generated files at root
rm -f *.d.ts *.js families.json 2>/dev/null || true
rm -rf __internal Internal internal 2>/dev/null || true

echo "  Done"

# Build dotnet-bindgen
echo "[2/3] Building dotnet-bindgen..."
cd "$DOTNET_BINDGEN_DIR"
dotnet build src/DotnetBindgen/DotnetBindgen.csproj -c Release --verbosity quiet
echo "  Done"

# Collect all Microsoft.Extensions.* assemblies from the ASP.NET shared framework
echo "[3/3] Generating TypeScript declarations..."
EXT_DLLS=( "$ASPNET_RUNTIME_PATH"/Microsoft.Extensions*.dll )
if [ ! -f "${EXT_DLLS[0]}" ]; then
    echo "ERROR: No Microsoft.Extensions*.dll assemblies found at $ASPNET_RUNTIME_PATH"
    exit 1
fi

# Keep this package focused on the core Microsoft.Extensions.* surface area
# (Hosting/DI/Logging/Configuration/Options/etc). Identity is part of the
# ASP.NET Core stack and is intentionally excluded.
FILTERED_DLLS=()
for dll in "${EXT_DLLS[@]}"; do
    case "$(basename "$dll")" in
        Microsoft.Extensions.Identity.*.dll) ;;
        Microsoft.Extensions.Features.dll) ;;
        *) FILTERED_DLLS+=( "$dll" ) ;;
    esac
done

GEN_ARGS=()
for dll in "${FILTERED_DLLS[@]}"; do
    GEN_ARGS+=( -a "$dll" )
done

dotnet run --project src/DotnetBindgen/DotnetBindgen.csproj --no-build -c Release -- \
    generate "${GEN_ARGS[@]}" -d "$NETCORE_RUNTIME_PATH" -o "$PROJECT_DIR" \
    --lib "$DOTNET_LIB"

echo ""
echo "================================================================"
echo "Generation Complete"
echo "================================================================"
