# custom/blobs/

This directory previously held prebuilt .so files for Rockchip RK3568/Z96A
GPU/VPU/RGA/NPU support. As of the `rockchip-multimedia` extension this is
no longer required — components are now provisioned at image build time:

1. **MPP (VPU)** — cross-compiled from rockchip-linux/mpp (develop) by
   `custom/extensions/rockchip-multimedia.sh`; installs librockchip-mpp,
   headers, pkg-config and test tools (mpi_dec_test, ...).
2. **RGA** — prebuilt aarch64 librga.so + im2d headers from
   airockchip/librga (staged by the extension).
3. **RKNN runtime** — librknnrt.so + rknn_api.h downloaded from
   airockchip/rknn-toolkit2 v2.3.2 (staged by the extension).
4. **GLES** — Mesa Panfrost from Debian bookworm (kernel CONFIG_DRM_PANFROST=y);
   no blob needed.
5. **Vulkan** — not provided on bookworm (panvk needs Mesa >= 24.2).

## libmali.so (deprecated, unused)

`libmali.so` is the proprietary Mali blob kept for reference only. It is NOT
installed into images anymore: it requires the proprietary CONFIG_MALI_BIFROST
kernel driver (conflicts with Panfrost) and contains no Vulkan symbols. Safe
to delete.
