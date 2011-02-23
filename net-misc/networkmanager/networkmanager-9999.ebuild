# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/networkmanager/networkmanager-0.8.2-r4.ebuild,v 1.1 2011/01/25 02:46:46 qiaomuf Exp $

EAPI="2"
GCONF_DEBUG="no"

inherit gnome2 linux-info

# NetworkManager likes itself with capital letters
MY_PN=${PN/networkmanager/NetworkManager}
MY_P=${MY_PN}-${PV}

DESCRIPTION="Network configuration and management in an easy way. Desktop environment independent."
HOMEPAGE="http://www.gnome.org/projects/NetworkManager/"

LICENSE="GPL-2"
SLOT="0"
IUSE="avahi bluetooth doc nss gnutls dhclient dhcpcd +introspection kernel_linux
resolvconf connection-sharing wimax"
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
	EGIT_REPO_URI="git://anongit.freedesktop.org/${MY_PN}/${MY_PN}"
	KEYWORDS=""
else
	SRC_URI="${SRC_URI//${PN}/${MY_PN}}"
	KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"
fi

# gobject-introspection-0.10.2-r1 is needed due to gnome bug 642300
RDEPEND=">=sys-apps/dbus-1.2
	>=dev-libs/dbus-glib-0.75
	>=net-wireless/wireless-tools-28_pre9
	>=sys-fs/udev-145[extras]
	>=dev-libs/glib-2.18
	>=sys-auth/polkit-0.92
	>=dev-libs/libnl-1.1
	>=net-misc/modemmanager-0.4
	>=net-wireless/wpa_supplicant-0.5.10[dbus]
	bluetooth? ( net-wireless/bluez )
	|| ( sys-libs/e2fsprogs-libs <sys-fs/e2fsprogs-1.41.0 )
	avahi? ( net-dns/avahi[autoipd] )
	gnutls? (
		nss? ( >=dev-libs/nss-3.11 )
		!nss? ( dev-libs/libgcrypt
			net-libs/gnutls ) )
	!gnutls? ( >=dev-libs/nss-3.11 )
	dhclient? (
		dhcpcd? ( >=net-misc/dhcpcd-4.0.0_rc3 )
		!dhcpcd? ( net-misc/dhcp ) )
	!dhclient? ( >=net-misc/dhcpcd-4.0.0_rc3 )
	introspection? ( >=dev-libs/gobject-introspection-0.10.2-r1 )
	resolvconf? ( net-dns/openresolv )
	connection-sharing? (
		net-dns/dnsmasq
		net-firewall/iptables )
	wimax? ( >=net-wireless/wimax-1.5.1 )"

DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/intltool
	>=net-dialup/ppp-2.4.5
	doc? ( >=dev-util/gtk-doc-1.8 )"

S=${WORKDIR}/${MY_P}

sysfs_deprecated_check() {
	ebegin "Checking for SYSFS_DEPRECATED support"

	if { linux_chkconfig_present SYSFS_DEPRECATED_V2; }; then
		eerror "Please disable SYSFS_DEPRECATED_V2 support in your kernel config and recompile your kernel"
		eerror "or NetworkManager will not work correctly."
		eerror "See http://bugs.gentoo.org/333639 for more info."
		die "CONFIG_SYSFS_DEPRECATED_V2 support detected!"
	fi
	eend $?
}

pkg_setup() {

	if use kernel_linux; then
		get_version
		if linux_config_exists; then
			sysfs_deprecated_check
		else
			ewarn "Was unable to determine your kernel .config"
			ewarn "Please note that if CONFIG_SYSFS_DEPRECATED_V2 is set in your kernel .config, NetworkManager will not work correctly."
			ewarn "See http://bugs.gentoo.org/333639 for more info."
		fi

	fi

	G2CONF="--disable-more-warnings
		--localstatedir=/var
		--with-distro=gentoo
		--with-dbus-sys-dir=/etc/dbus-1/system.d
		--with-udev-dir=/etc/udev
		--with-iptables=/sbin/iptables
		$(use_with doc docs)
		$(use_with resolvconf)
		$(use_enable introspection)
		$(use_enable wimax)"

	# default is dhcpcd (if none or both are specified), ISC dchclient otherwise
	if use dhclient ; then
		if use dhcpcd ; then
			G2CONF="${G2CONF} --with-dhcpcd --without-dhclient"
		else
			G2CONF="${G2CONF} --with-dhclient --without-dhcpcd"
		fi
	else
		G2CONF="${G2CONF} --with-dhcpcd --without-dhclient"
	fi

	# default is NSS (if none or both are specified), GnuTLS otherwise
	if use gnutls ; then
		if use nss ; then
			G2CONF="${G2CONF} --with-crypto=nss"
		else
			G2CONF="${G2CONF} --with-crypto=gnutls"
		fi
	else
		G2CONF="${G2CONF} --with-crypto=nss"
	fi

}

src_prepare() {
	# dbus policy patch
	epatch "${FILESDIR}/${PN}-0.8.2-confchanges.patch"
	# fix shared connection wrt bug #350476
	# fix parsing dhclient.conf wrt bug #352638
	# FIXME: does not apply
	#epatch "${FILESDIR}/${PN}-0.8.2-shared-connection.patch"

	# https://bugzilla.gnome.org/show_bug.cgi?id=643011
	epatch "${FILESDIR}/${PN}-more-gi-annotations.patch"

	gnome2_src_prepare
}

src_install() {
	gnome2_src_install

	# Need to keep the /var/run/NetworkManager directory
	keepdir /var/run/NetworkManager

	# Need to keep the /etc/NetworkManager/dispatched.d for dispatcher scripts
	keepdir /etc/NetworkManager/dispatcher.d

	dodoc AUTHORS ChangeLog NEWS README TODO || die "dodoc failed"

	# Add keyfile plugin support
	keepdir /etc/NetworkManager/system-connections
	insinto /etc/NetworkManager
	newins "${FILESDIR}/nm-system-settings.conf-ifnet" nm-system-settings.conf \
		|| die "newins failed"
}

pkg_postinst() {
	gnome2_pkg_postinst

	elog "You will need to reload DBus if this is your first time installing"
	elog "NetworkManager, or if you're upgrading from 0.7 or older."
	elog ""
}
