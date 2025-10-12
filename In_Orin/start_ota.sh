#!/bin/sh
set -eu

#클라우드 계정에 따라 변경 필요
BUCKET="s3://mjmota"

#디렉토리 및 유저명에 따른 파일 이름 변경 필요.
#ota_status_fromOrin / ota_status_fromJetPack은 클라우드에 저장되는 텍스트파일명임.
#클라우드에 저장할 파일 이름으로 변경해야함.

STATUS_FROM_ORIN_LOCAL="/home/misys/ota_status_fromOrin.txt"
STATUS_FROM_JETPACK_LOCAL="/home/misys/ota_status_fromJetpack.txt"
DEVICE="/dev/mmcblk0p1"
EXTLINUX="/boot/extlinux/extlinux.conf"
YOCTO_LABEL="yocto"   


sleep 2
NOW_UTC(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }
sleep 1
sudo rdate -s time.bora.net
sleep 1

s3cmd get --force s3://mjmota/ota_progress/ota_status_fromOrin.txt
sleep 2

if [ ! -s "${STATUS_FROM_ORIN_LOCAL}" ]; then
  echo "[Error] ota_status_fromOrin.txt does not exist. Stopped. "
  exit 0
fi


## Customer can use Jetpack deliberately.. not for OTA
## so, ifthe status from Orin file not exists, OTA not start

UPDATE_REQUIRED=$(grep "^update_required" "${STATUS_FROM_ORIN_LOCAL}" | cut -d '=' -f2 | tr -d '[:space:]' | tr 'A-Z' 'a-z')
RECOVERY_ENABLED=$(grep "^recovery_enabled" "${STATUS_FROM_ORIN_LOCAL}" | cut -d '=' -f2 | tr -d '[:space:]' | tr 'A-Z' 'a-z' || true)
CURRENT_VERSION=$(grep "^current_version" "${STATUS_FROM_ORIN_LOCAL}" | cut -d '=' -f2 | tr -d '[:space:]' || true)
TARGET_VERSION=$(grep "^target_version"  "${STATUS_FROM_ORIN_LOCAL}" | cut -d '=' -f2 | tr -d '[:space:]' || true)

if [ "${UPDATE_REQUIRED}" != "true" ]; then
  echo "*** UPDATE is not REQUIRED. Stopped. ***"
  exit 1
fi


echo "*************************************"
echo "current=${CURRENT_VERSION}"
echo "target=${TARGET_VERSION}"
echo "recovery_enabled=${RECOVERY_ENABLED}"
echo "*************************************"
echo " OTA Start in 3s..."
echo "*************************************"
sleep 2




if [ "${RECOVERY_ENABLED}" = "true" ] || [ "${RECOVERY_ENABLED}" = "true" ]; then

  IMG_PATH="./yocto_rootfs.ext4"
  echo "Backing up rootfs from ${DEVICE}..."
  echo "***********************************"
  sudo dd if="${DEVICE}" bs=4M status=progress | gzip > "${IMG_PATH}.gz"
  sync
  sleep 1
  echo "Done Backup"
  s3cmd put --force "yocto_rootfs.ext4.gz" "${BUCKET}/recovery_image/"
  sleep 1
  echo "Done zip"
else
  echo "Your OTA Option 'recovery_enabled' is set not 'true'."
  echo "Making recovery image skipped."
  echo "****************************************************"
fi


echo "***************************************"
echo " Rootfs Update Start "
echo "***************************************"

#빌드된 yocto 이미지는 클라우드의 ota_package 디렉토리 하위, yocto_rootfs.ext4.gz로 업로드되어있어야 함.
s3cmd get --force "${BUCKET}/ota_package/yocto_rootfs.ext4.gz"

if [ ! -f "yocto_rootfs.ext4.gz" ]; then
    echo "[Error] OTA Package does not exist. Stopped"
    exit 1
fi

echo "********************"
echo "Writing Yocto rootfs"
echo "********************"
gunzip -c "yocto_rootfs.ext4.gz" | sudo dd of=/dev/mmcblk0p1 bs=4M status=progress
sync
echo "***********************"
echo "write and sync complete"
echo "***********************"


if [ -f "${EXTLINUX}" ]; then
  sudo sed -i "s/^DEFAULT.*/DEFAULT ${YOCTO_LABEL}/" "${EXTLINUX}"
else
  exit 1
fi

{
  echo "time_utc=$(NOW_UTC)"
  echo "device= Jetson-Orin-Agx-Devkit"
  echo "before_update_version=${CURRENT_VERSION}"
  echo "after_version_update=${TARGET_VERSION}"
  echo "written_device=${DEVICE}"
  echo "ota_result=success"
} > "${STATUS_FROM_JETPACK_LOCAL}"

s3cmd put --force "ota_status_fromJetpack.txt" "${BUCKET}/ota_progress/"

: > "${STATUS_FROM_ORIN_LOCAL}"
s3cmd put --force "${STATUS_FROM_ORIN_LOCAL}" "${BUCKET}/ota_progress/"
echo "***************************"
echo "  Update was successful!   "
echo "  System will reboot in 3s."
echo "***************************"
sync 
sleep 2
sudo reboot
