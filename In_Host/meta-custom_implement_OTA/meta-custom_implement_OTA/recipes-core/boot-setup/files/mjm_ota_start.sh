#!/bin/sh

#You have to change SERVER_URL to yours.
SERVER_URL="https://kr.object.ncloudstorage.com/mjmota"
######################################################

#find 'mjmota'. mjmota is my servername of Ncloud, so you have to change mjmota to your servername.

VERSION_FILE="/etc/version.txt"
LOCAL_VERSION_FILE="/etc/local_version.txt"
OTA_DIR="/ota"


S3TOOL_DIR="/home/root"
S3CMD_SRC_DIR="${S3TOOL_DIR}/s3cmd-master"
ZIP_FILE="${S3TOOL_DIR}/master.zip"
WPA_CONF="/etc/wpa_supplicant.conf"
CONFIG_ORIGIN="/home/root/s3cfg"
CONFIG_TARGET="/home/root/.s3cfg"
STATUS_LOCAL="/home/root/ota_status_fromOrin.txt"

sleep 3
echo "********************************"
echo " OTA ststem will start in 3s."
sleep 3

echo "*********************"
echo "**                 **"
echo "**    OTA Start    **"
echo "**                 **"
echo "*********************"

S3CMD_DIR="/home/root/s3cmd-master"

echo "[OTA] Installing s3cmd from ${S3CMD_DIR}..."

if [ -d "${S3CMD_DIR}" ]; then
    cd "${S3CMD_DIR}" || exit 1
    /usr/bin/python3 /home/root/s3cmd-master/setup.py install 
    echo "[Cloud] s3cmd-master is installed. "
else
    echo " *** [Error] s3cmd-master is not exist"
    exit 1
fi

if [ -f "${CONFIG_ORIGIN}" ]; then
    cp -f "${CONFIG_ORIGIN}" "${CONFIG_TARGET}"
    echo "[Cloud] .s3cfg copy complete"
else
    echo " *** [Error] [Cloud] s3cfg not exist,,,"
    exit 1
fi




echo "***********************************"
echo "**                               **"
echo "**    NCloud Config Complete     **"
echo "**                               **"
echo "***********************************"









# -----------------------------
# 1. Wi-Fi 연결 시도
# -----------------------------
echo "[WIFI] Loading Wi-Fi driver..."
modprobe rtl8822ce

echo "[WIFI] Activating wlan0..."
ip link set wlan0 up
sleep 2
echo "[WIFI] Setting region to KR..."
iw reg set KR


###############################################
# You have to change 'network section' to your Wifi setting.
# 'JL' is my home WIFI..
###############################################
cat <<EOF > "${WPA_CONF}"
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1
country=KR

network={
    ssid="JL"
    psk="33342129"
    key_mgmt=WPA-PSK
}
EOF
sleep 1


echo "[WIFI] Starting wpa_supplicant..."
wpa_supplicant -B -i wlan0 -c "${WPA_CONF}"
sleep 3

echo "[WIFI] Requesting IP via udhcpc..."
udhcpc -i wlan0
sleep 3



echo "[NET] Checking network connectivity..."
if ping -c 2 -W 2 google.com > /dev/null 2>&1; then
    echo "[Network] Network Connecting complete!"
    rdate -s time.bora.net
    echo "[Network] time is complete with GMT"
else
    echo " *** [Error] [Network] time is not setted. stop OTA."
    exit 1
fi

pip3 install python-magic

echo "***********************************"
echo "**                               **"
echo "**    Network Config Complete    **"
echo "**                               **"
echo "***********************************"


# -----------------------------
# 2. ota option 체크
# -----------------------------
cd /home/root
s3cmd get --force s3://mjmota/ota_option/ota_option.conf

OTA_ENABLED=$(grep "^OTA_enabled" "/home/root/ota_option.conf" | cut -d '=' -f2 | tr -d '[:space:]')
RECOVERY_ENABLED=$(grep "^Recovery_enabled" "/home/root/ota_option.conf" | cut -d '=' -f2 | tr -d '[:space:]')

if [ "${OTA_ENABLED}" != "true" ]; then
  echo "***********************************************"
  echo "Your OTA_ENABLED option is not true. Exit OTA. "
  echo "***********************************************"
  sleep 1
  exit 1
fi


echo " **********************************************"
echo " *                                            *"
echo " *    Your OTA_ENABLED option is set true.    *"
echo " *    Yocto - version check will start.       *"
echo " *                                            *"
echo " **********************************************"


# -----------------------------
# 3. 버전체크
# -----------------------------
sleep 1
cd /home/root
s3cmd get --force s3://mjmota/version_check/version_check.txt
sleep 1
VERSION_CHECK_FROM_ORIN=$(grep "^CURRENT_VERSION" "/home/root/current_version.txt" | cut -d '=' -f2 | tr -d '[:space:]')
VERSION_CHECK_FROM_CLOUD=$(grep "^LATEST_VERSION" "/home/root/version_check.txt" | cut -d '=' -f2 | tr -d '[:space:]')

if [ "$VERSION_CHECK_FROM_ORIN" == "$VERSION_CHECK_FROM_CLOUD" ]; then
    echo "Your Yocto rootfs is already Latest version. Don't need to update anymore."
    sleep 1
    exit 1
fi



if [ "$VERSION_CHECK_FROM_ORIN" != "$VERSION_CHECK_FROM_CLOUD" ]; then
    echo "Current Version is not latest version."
    sleep 1
    echo "Boot Partition will changed, and will be rebooted with JetPack."
    
    # NVME 마운트
    mkdir -p /mnt/nvme
    mount /dev/nvme0n1p1 /mnt/nvme

    # extlinux.conf 수정 (DEFAULT를 jetpack으로 변경)
    EXTLINUX_PATH="/mnt/nvme/boot/extlinux/extlinux.conf"
    if [ ! -f "${EXTLINUX_PATH}" ]; then
        echo "extlinux.conf 파일을 찾을 수 없습니다."
        exit 1
    fi

    sed -i 's/^DEFAULT.*/DEFAULT jetpack/' "${EXTLINUX_PATH}"
    echo "****************************************"
    echo "Boot Partition was changed with jetpack."

    #NVMe 마운트 해제
    umount /mnt/nvme


    #로그출력
    NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    {
        echo "OTA_enabled option=${OTA_ENABLED}"
        echo "recovery_enabled=${RECOVERY_ENABLED}"
        echo "time_utc=${NOW}"
        echo "current_version=${VERSION_CHECK_FROM_ORIN}"
        echo "target_version=${VERSION_CHECK_FROM_CLOUD}"
        echo "update_required=true"
    } > "${STATUS_LOCAL}"

    # you have to change mjmota to your Ncloud servername.
    s3cmd put "${STATUS_LOCAL}" s3://mjmota/ota_progress/
    echo " ********************************************************"
    echo " *            OTA - setting notify                      *"
    echo " *    1. OTA_enabled option = ${OTA_ENABLED}            *"
    echo " *    2. recovery_enabled option = ${RECOVERY_ENABLED}  *"
    echo " *    3. current_version = ${VERSION_CHECK_FROM_ORIN}   *"
    echo " *    4. target_version = ${VERSION_CHECK_FROM_CLOUD}   *"
    echo " *    time log is ${NOW}.                               *"
    echo " *    Rootfs update will start in JetPack(NVMe) boot.   *"
    echo " ********************************************************"

    echo " reboot will begin in 5s."
    sleep 5
    reboot
fi


