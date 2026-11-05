#!/bin/bash
# Build the scheduler, merger and executor images of this fork from HEAD.
#
#   tools/build-solunio-images.sh            # build
#   PUSH=1 tools/build-solunio-images.sh     # build and push
#
# Tag: <upstream version>-<9 char commit sha>, e.g. 14.3.0-06f81188c.
# See SOLUNIO.md.

set -euo pipefail

REGISTRY=${REGISTRY:-"localhost"}
COMPONENTS=${COMPONENTS:-scheduler merger executor}
# Override to e.g. "podman --root /tmp/podman/root --runroot /tmp/podman/run".
PODMAN=${PODMAN:-podman}

cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "Uncommitted changes: the image is built from HEAD." >&2
    exit 1
fi

VERSION=$(git describe --tags --abbrev=0 --match '[0-9]*')
SHA=$(git rev-parse --short=9 HEAD)
TAG=$VERSION-$SHA

# A clean export keeps .venv, .git etc. out of the build context.
CONTEXT=$(mktemp -d)
trap 'rm -rf "$CONTEXT"' EXIT
git archive HEAD | tar -x -C "$CONTEXT"

for component in $COMPONENTS; do
    $PODMAN build --platform linux/amd64 --format oci \
        --target "zuul-$component" \
        --build-arg "PBR_VERSION=$VERSION+solunio.$SHA" \
        -t "$REGISTRY/zuul-$component:$TAG" "$CONTEXT"
done

for component in $COMPONENTS; do
    if [ -n "${PUSH:-}" ]; then
        $PODMAN push "$REGISTRY/zuul-$component:$TAG"
    else
        echo "Built $REGISTRY/zuul-$component:$TAG"
    fi
done
