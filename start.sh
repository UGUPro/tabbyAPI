#!/bin/bash

cd "$(dirname "$0")" || exit

# NOTE: This deployment uses a hand-managed uv environment with a GPU-specific
# torch build and a local exllamav3. The stock start.py auto-installer could
# replace either one with an incompatible release, so activate the existing
# environment and launch main.py directly.

# ROCm runtime settings for the Strix Halo (gfx1151) GPU. The override pins the
# HSA target to gfx1151 (11.5.1) so GPU kernels (Triton, and the CK flash-attn
# backend) target the correct ISA. Without it, flash-attn kernels abort the GPU
# with HSA_STATUS_ERROR_EXCEPTION. Allow the caller's environment to override
# these if already set. TABBYAPI_ROCM=1 forces these settings, while
# TABBYAPI_ROCM=0 disables automatic detection.
if [ "${TABBYAPI_ROCM:-auto}" = "1" ] || {
    [ "${TABBYAPI_ROCM:-auto}" = "auto" ] && command -v rocminfo >/dev/null 2>&1
}; then
    export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.5.1}"
    export ROCM_INIT_FLAGS="${ROCM_INIT_FLAGS:-0x1}"
fi

if [ -n "$CONDA_PREFIX" ]; then
    echo "It looks like you're in a conda environment. Skipping venv check."
elif [ -d ".venv" ]; then
    echo "Activating venv"
    # shellcheck source=/dev/null
    source .venv/bin/activate
else
    echo "ERROR: venv not found."
    echo "This deployment relies on a manually managed GPU environment rather than"
    echo "start.py's auto-installer. Create .venv and install the appropriate torch,"
    echo "tabbyAPI dependencies, and local exllamav3 before launching."
    exit 1
fi

# Create a default config on first run (mirrors the old start.py behaviour)
if [ ! -f "config.yml" ]; then
    echo "config.yml not found; creating one from config_sample.yml"
    cp config_sample.yml config.yml
fi

python3 main.py "$@"
