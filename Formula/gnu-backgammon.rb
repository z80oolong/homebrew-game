class GnuBackgammon < Formula
  desc "GNU Backgammon (GNUbg) plays and analyzes backgammon games and matches."
  homepage "https://www.gnu.org/software/gnubg/"
  url "https://ftp.gnu.org/gnu/gnubg/gnubg-release-1.06.002-sources.tar.gz"
  sha256 "ce1b0b0c1900717cc598032a14cf8c0ee60faf24d84368b39922c0102983bc87"
  license "GPL-3.0-or-later"

  depends_on "autoconf"  => :build
  depends_on "automake"  => :build
  depends_on "libtool"   => :build
  depends_on "bison"     => :build
  depends_on "flex"      => :build
  depends_on "texinfo"   => :build
  depends_on "docbook2x" => :build

  depends_on "glib"
  depends_on "libpng"
  depends_on "freetype"
  depends_on "gtk+"
  depends_on "cairo"
  depends_on "libcanberra"
  depends_on "readline"
  depends_on "python@3.9"
  depends_on "sqlite3"
  depends_on "gmp"

  def install
    system "./configure", "--disable-silent-rules", \
                          "--with-gtk", \
                          "--with-python=#{Formula["python@3.9"].opt_bin}/python3", \
                          *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system "#{opt_bin}/gnubg", "--version"
  end
end
