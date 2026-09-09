# custom/blobs/

This directory contains proprietary .so files for Rockchip RK3568/Z96A GPU/VPU/RGA/NPU support.

**Required files (must be placed here before building):**

1. `libmali.so` - Mali-G52 GPU blob
2. `librockchip-mpp.so` - Rockchip MPP VPU library  
3. `librga.so` - Rockchip RGA API library
4. `librknnrt.so` - Rockchip RKNN runtime

**How to obtain:**
- From Rockchip official SDK or your armbian build repository
- Or from the GitHub repositories mentioned in the Armbian build documentation

**Important:** Without these .so files, the Armbian image will not have full hardware acceleration support.
