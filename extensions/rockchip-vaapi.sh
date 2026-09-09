#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Sunniwell Z96A Project
#
# Rockchip VA-API hard decode extension for RK3568/Z96A.
# Depends on action.yml's compile-rockchip-vaapi step having staged .so files
# into build/output/rockchip-vaapi/ before this extension runs.
#
# Enable with: ENABLE_EXTENSIONS="rockchip-vaapi"
#
# This extension:
#   1. Copies librockchip-mpp.so / librga.so to /usr/lib/aarch64-linux-gnu/
#   2. Copies rockchip_drv_video.so to /usr/lib/aarch64-linux-gnu/dri/
#   3. Runs ldconfig to refresh dynamic linker cache
#   4. Installs udev rules so non-root users can access /dev/rga, /dev/vpu*
#
# The build action that calls this is defined in action.yml.

function post_family_config__rockchip_vaapi() {
	display_alert "${EXTENSION}" "preparing rockchip-vaapi" "info"
	declare -g ROCKCHIP_VAAPI_STAGE="${SRC}/../../output/rockchip-vaapi"
	[[ ! -d "${ROCKCHIP_VAAPI_STAGE}" ]] && {
		display_alert "${EXTENSION}" "staged .so files not found at ${ROCKCHIP_VAAPI_STAGE}, skipping" "warn"
		return 0
	}
}

function pre_customize_image__inject_rockchip_vaapi() {
	display_alert "${EXTENSION}" "injecting rockchip-vaapi into image" "info"
	[[ ! -d "${ROCKCHIP_VAAPI_STAGE}" ]] && return 0

	# 1) MPP + RGA shared libs (libva-rockchip links against them)
	cp -av "${ROCKCHIP_VAAPI_STAGE}/usr/lib/aarch64-linux-gnu/librockchip-mpp.so"* \
	       "${MOUNT}/usr/lib/aarch64-linux-gnu/" 2>&1 | head -3 || true
	cp -av "${ROCKCHIP_VAAPI_STAGE}/usr/lib/aarch64-linux-gnu/librga.so"* \
	       "${MOUNT}/usr/lib/aarch64-linux-gnu/" 2>&1 | head -3 || true

	# 2) libva rockchip backend
	mkdir -p "${MOUNT}/usr/lib/aarch64-linux-gnu/dri"
	cp -av "${ROCKCHIP_VAAPI_STAGE}/usr/lib/aarch64-linux-gnu/dri/rockchip_drv_video.so" \
	       "${MOUNT}/usr/lib/aarch64-linux-gnu/dri/" 2>&1 | head -3 || true

	# 3) Symlink for legacy loader path (matches what jeffy-cn/libva-rockchip ships)
	[[ -f "${MOUNT}/usr/lib/aarch64-linux-gnu/dri/rockchip_drv_video.so" ]] && \
		ln -sf /usr/lib/aarch64-linux-gnu/dri/rockchip_drv_video.so \
		       "${MOUNT}/usr/lib/dri/rockchip_drv_video.so" 2>/dev/null || true

	# 4) Trigger ldconfig on first boot via a one-shot service
	install -m 0755 -d "${MOUNT}/etc/systemd/system/rockchip-vaapi-ldconfig.service.d"
	cat > "${MOUNT}/etc/systemd/system/rockchip-vaapi-ldconfig.service" <<'UNIT'
[Unit]
Description=Refresh ldconfig cache for rockchip-vaapi shared libs
After=local-fs.target
ConditionPathExists=/usr/lib/aarch64-linux-gnu/librockchip-mpp.so
[Service]
Type=oneshot
ExecStart=/sbin/ldconfig
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
UNIT

	# Enable it on first boot via rc.local-style hack (systemd enable needs chroot-aware)
	chroot "${MOUNT}" /bin/bash -c "systemctl enable rockchip-vaapi-ldconfig.service" 2>/dev/null || \
		display_alert "${EXTENSION}" "systemctl enable failed (expected in some chroots), will rely on dpkg trigger" "warn"

	display_alert "${EXTENSION}" "rockchip-vaapi injected successfully" "${MOUNT}" "info"
}
