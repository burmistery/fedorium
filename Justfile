registry := "ghcr.io/burmistery"
image := "fedorium"
tag := "latest"
_:
    just --lit

validate:
    bluebuild validate "recipes/recipe.yml"

generate:
    bluebuild generate "recipes/recipe.yml"

build:
    bluebuild build -B podman "recipes/recipe.yml"

generate-iso:
    bluebuild generate-iso -B podman recipe "recipes/recipe.yml"

generate-iso-image:
    bluebuild generate-iso -B podman image "{{ registry }}/{{ image }}:{{ tag }}"

build-qcow2:
    mkdir -p output
    podman save "{{ registry }}/{{ image }}:{{ tag }}" | sudo podman load
    sudo podman run \
        --rm \
        --privileged \
        -v "./output:/output" \
        -v "./files/qcow2/:/files:ro" \
        -v "/var/lib/containers/storage:/var/lib/containers/storage" \
        ghcr.io/osbuild/image-builder-cli:latest \
        build qcow2 \
        --blueprint "/files/config.toml" \
        --bootc-ref "{{ registry }}/{{ image }}:{{ tag }}" \
        --output-dir /output \
        --bootc-default-fs btrfs \
        --output-name "{{ image }}"
    sudo podman rmi "{{ registry }}/{{ image }}:{{ tag }}"
    sudo chmod 777 "output/{{ image }}.qcow2"

local-build-qcow2:
    just --set registry localhost build-qcow2

run-qcow2 qcow2="./output/fedorium.qcow2":
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4G \
        -display gtk,gl=on \
        -device virtio-vga-gl \
        -serial stdio \
        -drive file="{{ qcow2 }}",format="qcow2"

run-iso iso:
    qemu-img create -f qcow2 "/tmp/{{ image }}.qcow2" 32G
    qemu-img create -f raw "/tmp/oemdrv.img" 64M
    mkfs.vfat -n "OEMDRV" "/tmp/oemdrv.img"
    mcopy -i "/tmp/oemdrv.img" "ks.cfg" ::/ks.cfg

    qemu-system-x86_64 \
        -enable-kvm \
        -m 4G \
        -display gtk,gl=on \
        -device virtio-vga-gl \
        -serial stdio \
        -cdrom "{{ iso }}" \
        -drive file="/tmp/{{ image }}.qcow2",format=qcow2 \
        -drive file="/tmp/oemdrv.img",format=raw
    rm -f "/tmp/{{ image }}.qcow2"
