registry := "ghcr.io/burmistery"
image := "fedorium"
tag := "latest"
_:
    just --lit

validate:
    bluebuild validate recipes/recipe.yml

generate:
    bluebuild generate recipes/recipe.yml

build:
    bluebuild build -B podman recipes/recipe.yml

generate-iso:
    bluebuild generate-iso -B podman recipe recipes/recipe.yml

generate-iso-image:
    bluebuild generate-iso -B podman image {{ registry }}/{{ image }}:{{ tag }}

build-qcow2:
    mkdir -p output
    podman save {{ registry }}/{{ image }}:{{ tag }} | sudo podman load
    sudo podman run \
        --rm \
        --privileged \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        ghcr.io/osbuild/image-builder-cli:latest \
        build qcow2 \
        --bootc-ref {{ registry }}/{{ image }}:{{ tag }} \
        --output-dir /output \
        --bootc-default-fs btrfs \
        --output-name {{ image }}
    sudo podman rmi {{ registry }}/{{ image }}:{{ tag }}

run-vm:
    qemu-system-x86_64 \
        -m 4096 \
        -enable-kvm \
        -device virtio-vga -serial stdio \
        -drive file=./output/{{ image }}.qcow2
