# rocm-torch

Minimal PyTorch + ROCm Docker image for **AMD RDNA 4** GPUs (RX 9070 XT, RX 9070, etc.)

**No ROCm SDK base image required.** The PyTorch wheels bundle their own ROCm user-space runtime. The base is plain `ubuntu:24.04` + Python + `libatomic1`. That's it.

## What's included

| Component | Version |
|-----------|---------|
| Ubuntu | 24.04 |
| Python | 3.12 |
| PyTorch | 2.12.0+rocm7.2 |
| torchvision | 0.27.0+rocm7.2 |
| torchaudio | 2.11.0+rocm7.2 |

## Quick start

```bash
docker run --rm -it \
  --device=/dev/kfd --device=/dev/dri \
  --group-add video --group-add render \
  -e HSA_OVERRIDE_GFX_VERSION=12.0.1 \
  -e PYTORCH_ROCM_ARCH=gfx1201 \
  ghcr.io/carbonneuron/rocm-torch:latest \
  python3.12 -c "import torch; print(torch.cuda.get_device_name(0))"
```

## Environment variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `HSA_OVERRIDE_GFX_VERSION` | `12.0.1` | Target RDNA 4 instruction set (Navi 48) |
| `PYTORCH_ROCM_ARCH` | `gfx1201` | PyTorch GPU architecture target |

These are **required** for RDNA 4. Set them in your `docker run`, `docker-compose.yml`, or Dockerfile.

## Kernel cache

The first time you run inference on a new GPU, ROCm JIT-compiles optimized kernels. This takes ~60 seconds. The compiled kernels are cached in:

- `/root/.cache/comgr` — LLVM compiled kernels (~335MB)
- `/root/.cache/miopen` — MIOpen convolution tuning database
- `/root/.config/miopen` — MIOpen configuration

These are declared as `VOLUME`s in the Dockerfile, so they persist across container restarts by default. For even faster cold starts, bind-mount them from your host:

```yaml
volumes:
  - ~/.cache/comgr:/root/.cache/comgr
  - ~/.cache/miopen:/root/.cache/miopen
  - ~/.config/miopen:/root/.config/miopen
```

## Using as a base image

```dockerfile
FROM ghcr.io/carbonneuron/rocm-torch:latest

RUN pip3.12 install --break-system-packages diffusers transformers accelerate

COPY my_app.py .
CMD ["python3.12", "my_app.py"]
```

## Device access

Your container needs access to the AMD GPU kernel interfaces:

```yaml
devices:
  - /dev/kfd:/dev/kfd
  - /dev/dri:/dev/dri
group_add:
  - video
  - render  # or use numeric GIDs if the names don't exist in the container
```

## Supported GPUs

Tested on:
- AMD Radeon RX 9070 XT (gfx1201, Navi 48)

Should work on any RDNA 4 GPU with `HSA_OVERRIDE_GFX_VERSION` set appropriately:
- RX 9070 XT / RX 9070 → `12.0.1`
- RX 9060 XT → `12.0.0`

## Building locally

```bash
docker build -t rocm-torch .
```

Or with custom versions:

```bash
docker build \
  --build-arg TORCH_VERSION=2.12.0 \
  --build-arg ROCM_VERSION=7.2 \
  -t rocm-torch:custom .
```

## Host requirements

- Linux with `amdgpu` kernel driver (ROCm 7.1+ recommended)
- Docker with GPU device passthrough (`--device=/dev/kfd --device=/dev/dri`)
- No ROCm installation required on the host beyond the kernel driver

## Why this exists

The official `rocm/pytorch` Docker images are 30GB+ and ship with the full ROCm SDK. This image proves you don't need any of that — the PyTorch ROCm wheels are fully self-contained. The result is a smaller, simpler image that just works.

## License

MIT
