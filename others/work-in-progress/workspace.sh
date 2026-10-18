#!/usr/bin/env bash
# source: https://github.com/leanderziehm/devops/tree/main/others/work-in-progress/workspace.sh
# maybe make it recreate a container each time or idk

work() {
    local prefix="$1"
    local path="${2:-$PWD}"
    local folder
    local container="work${prefix:+-$prefix}"

    if [[ "$prefix" == "ps" ]]; then
        podman ps -a --filter "name=^work" \
            --format "table {{.Names}}\t{{.Status}}"
        return
    fi

    path="$(realpath "$path")" || return 1
    folder="$(basename "$path")"

    if podman container exists "$container"; then
        echo "Using existing container: $container"

        if [[ "$(podman inspect -f '{{.State.Running}}' "$container")" == "true" ]]; then
            podman exec -it "$container" bash
        else
            podman start -ai "$container"
        fi
    else
        echo "Creating container: $container"

        podman run -it \
            --name "$container" \
            --userns keep-id \
            -v "$path:/$folder:Z" \
            -w "/$folder" \
            --network host \
            ghcr.io/leanderziehm/dev-environment-fedora:latest
    fi
}