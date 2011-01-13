# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-extra/gnome-media/gnome-media-2.32.0.ebuild,v 1.1 2010/10/17 18:56:04 pacho Exp $

EAPI="3"
GCONF_DEBUG="no"

inherit autotools eutils gnome2

DESCRIPTION="Multimedia related programs for the GNOME desktop"
HOMEPAGE="http://ronald.bitfreak.net/gnome-media.php"

LICENSE="LGPL-2 GPL-2 FDL-1.1"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="pulseaudio"

# FIXME: automagic dev-util/glade:3 support
RDEPEND=">=dev-libs/glib-2.18.2:2
	>=x11-libs/gtk+-2.18.0:2
	>=gnome-base/gconf-2.6.1
	>=media-libs/gstreamer-0.10.23
	>=media-libs/gst-plugins-base-0.10.23
	>=media-libs/gst-plugins-good-0.10
	>=dev-libs/libunique-1

	pulseaudio? ( >=media-sound/pulseaudio-0.9.16[glib] )
	>=media-libs/libcanberra-0.13[gtk]
	dev-libs/libxml2
	>=media-libs/gst-plugins-base-0.10.23:0.10
	>=media-plugins/gst-plugins-meta-0.10-r2:0.10
	>=media-plugins/gst-plugins-gconf-0.10.1"
DEPEND="${RDEPEND}
	>=dev-util/pkgconfig-0.9
	>=app-text/scrollkeeper-0.3.11
	>=app-text/gnome-doc-utils-0.3.2
	>=dev-util/intltool-0.35.0"

src_prepare() {
	# FIXME: gstmix will not work with gnome-shell and will clash with g-v-c,
	#        so disable it till we can figure out gnome-shell vs fallback etc.
	G2CONF="${G2CONF}
		--disable-static
		--disable-scrollkeeper
		--disable-schemas-install
		--enable-gstprops
		--enable-grecord
		--enable-profiles
		$(use_enable pulseaudio)
		--disable-gstmix"
	DOCS="AUTHORS ChangeLog* NEWS MAINTAINERS README"

	# This has been moved to media-libs/libgnome-media-profiles:3,
	# but the library libgnome-media-profiles.so.0 is still used
	epatch "${FILESDIR}/${P}-disable-gnome-audio-profile-properties.patch"
	eautoreconf
}

src_install() {
	gnome2_src_install

	if ! use pulseaudio; then
		# These files are now provided by gnome-control-center-2.91's sound applet
		# These won't be used if gnome-volume-control is not installed
		rm -v "${ED}"/usr/share/sounds/gnome/default/alerts/*.ogg || die
	fi
}

pkg_postinst() {
	gnome2_pkg_postinst
	ewarn
	ewarn "If you cannot play some music format, please check your"
	ewarn "USE flags on media-plugins/gst-plugins-meta"
	ewarn
}
