FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://inittab"

do_install:append() {
    install -m 0644 ${WORKDIR}/inittab ${D}${sysconfdir}/inittab
}

