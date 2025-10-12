SUMMARY = "Auto login, network config, and OTA version checker"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r3"
PN = "boot-setup"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://mjm_ota_start.sh \
    file://s3cmd-master \
    file://s3cfg \
    file://current_version.txt \
"

RDEPENDS:${PN} += "curl"

FILES:${PN} += " \
    /home/root \
    /etc/profile.d \
"

do_install() {

    install -d ${D}/home/root
    install -m 0755 ${WORKDIR}/mjm_ota_start.sh ${D}/home/root/mjm_ota_start.sh
    install -m 0644 ${WORKDIR}/current_version.txt ${D}/home/root/current_version.txt


    install -d ${D}/home/root/s3tools
    cp -r ${WORKDIR}/s3cmd-master ${D}/home/root/s3cmd-master
    install -m 0600 ${WORKDIR}/s3cfg ${D}/home/root/s3cfg
    rm -f ${D}/home/root/s3cmd-master/format-manpage.pl
 

    install -d ${D}${sysconfdir}/profile.d
    echo 'if [ "$(id -u)" -eq 0 ]; then /home/root/mjm_ota_start.sh; fi' > ${D}${sysconfdir}/profile.d/mjm_ota_start.sh
    chmod 0755 ${D}${sysconfdir}/profile.d/mjm_ota_start.sh


}
