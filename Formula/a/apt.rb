class Apt < Formula
  desc "Advanced Package Tool"
  homepage "https://wiki.debian.org/Apt"
  url "https://deb.debian.org/debian/pool/main/a/apt/apt_2.7.8.tar.xz"
  sha256 "9c09a2c1f18489fb430d616b93e6df5a15f61473856a789d5e3cce0ad2195dc6"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://deb.debian.org/debian/pool/main/a/apt/"
    regex(/href=.*?apt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 x86_64_linux: "906232678a35cb21021f5fce526d197d2afd8cadf5f9996669c99b612cf97651"
  end

  keg_only "not linked to prevent conflicts with system apt"

  depends_on "cmake" => :build
  depends_on "docbook" => :build
  depends_on "docbook-xsl" => :build
  depends_on "doxygen" => :build
  depends_on "googletest" => :build
  depends_on "libxslt" => :build
  depends_on "po4a" => :build
  depends_on "w3m" => :build

  depends_on "berkeley-db@5" # keep berkeley-db < 6 to avoid AGPL-3.0 restrictions
  depends_on "bzip2"
  depends_on "dpkg"
  depends_on "gettext"
  depends_on "gnupg"
  depends_on "gnutls"
  depends_on :linux
  depends_on "lz4"
  depends_on "perl"
  depends_on "xxhash"
  depends_on "zlib"

  fails_with gcc: "5"

  # List this first as the modules below require it.
  resource "Module::Build" do
    url "https://cpan.metacpan.org/authors/id/L/LE/LEONT/Module-Build-0.4234.tar.gz"
    sha256 "66aeac6127418be5e471ead3744648c766bd01482825c5b66652675f2bc86a8f"
  end

  resource "SGMLS" do
    url "https://cpan.metacpan.org/authors/id/R/RA/RAAB/SGMLSpm-1.1.tar.gz"
    sha256 "550c9245291c8df2242f7e88f7921a0f636c7eec92c644418e7d89cfea70b2bd"
  end

  resource "triehash" do
    url "https://github.com/julian-klode/triehash/archive/refs/tags/v0.3.tar.gz"
    sha256 "289a0966c02c2008cd263d3913a8e3c84c97b8ded3e08373d63a382c71d2199c"
  end

  resource "Unicode::GCString" do
    url "https://cpan.metacpan.org/authors/id/N/NE/NEZUMI/Unicode-LineBreak-2019.001.tar.gz"
    sha256 "486762e4cacddcc77b13989f979a029f84630b8175e7fef17989e157d4b6318a"
  end

  resource "Locale::gettext" do
    url "https://cpan.metacpan.org/authors/id/P/PV/PVANDRY/Locale-gettext-1.07.tar.gz"
    sha256 "909d47954697e7c04218f972915b787bd1244d75e3bd01620bc167d5bbc49c15"
  end

  resource "Term::ReadKey" do
    url "https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz"
    sha256 "5a645878dc570ac33661581fbb090ff24ebce17d43ea53fd22e105a856a47290"
  end

  resource "Text::WrapI18N" do
    url "https://cpan.metacpan.org/authors/id/K/KU/KUBOTA/Text-WrapI18N-0.06.tar.gz"
    sha256 "4bd29a17f0c2c792d12c1005b3c276f2ab0fae39c00859ae1741d7941846a488"
  end

  resource "YAML::Tiny" do
    url "https://cpan.metacpan.org/authors/id/E/ET/ETHER/YAML-Tiny-1.74.tar.gz"
    sha256 "7b38ca9f5d3ce24230a6b8bdc1f47f5b2db348e7f7f9666c26f5955636e33d6c"
  end

  resource "Pod::Parser" do
    url "https://cpan.metacpan.org/authors/id/M/MA/MAREKR/Pod-Parser-1.66.tar.gz"
    sha256 "22928a7bffe61b452c05bbbb8f5216d4b9cf9fe2a849b776c25500d24d20df7c"
  end

  resource "ExtUtils::CChecker" do
    url "https://cpan.metacpan.org/authors/id/P/PE/PEVANS/ExtUtils-CChecker-0.11.tar.gz"
    sha256 "117736677e37fc611f5b76374d7f952e1970eb80e1f6ad5150d516e7ae531bf5"
  end

  resource "XS::Parse::Keyword::Builder" do
    url "https://cpan.metacpan.org/authors/id/P/PE/PEVANS/XS-Parse-Keyword-0.38.tar.gz"
    sha256 "2500c47869cf5ca8c61dd23c67badabf66b8f1efb5e279207657c1ce693e211e"
  end

  resource "Syntax::Keyword::Try" do
    url "https://cpan.metacpan.org/authors/id/P/PE/PEVANS/Syntax-Keyword-Try-0.29.tar.gz"
    sha256 "cc320719d3608daa9514743a43dac2be99cb8ccd989b1fefa285290cb1d59d8f"
  end

  def install
    # Find our docbook catalog
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    ENV.prepend_create_path "PERL5LIB", buildpath/"lib/perl5"
    ENV.prepend_path "PERL5LIB", buildpath/"lib"
    ENV.prepend_path "PATH", buildpath/"bin"

    resource("triehash").stage do
      (buildpath/"bin").install "triehash.pl" => "triehash"
    end

    cpan_resources = resources.to_set(&:name) - ["triehash"]
    cpan_resources.each do |r|
      resource(r).stage do
        if File.exist?("Build.PL") && r != "Module::Build"
          system "perl", "Build.PL", "--install_base", buildpath
          system "./Build"
          system "./Build", "install"
        else
          chmod 0644, "MYMETA.yml" if r == "SGMLS"
          system "perl", "Makefile.PL", "INSTALL_BASE=#{buildpath}"
          system "make"
          system "make", "install"
        end
      end
    end

    system "cmake", "-S", ".", "-B", "build",
                    "-DDPKG_DATADIR=#{Formula["dpkg"].opt_libexec}/share/dpkg",
                    "-DDOCBOOK_XSL=#{Formula["docbook-xsl"].opt_prefix}/docbook-xsl",
                    "-DBERKELEY_INCLUDE_DIRS=#{Formula["berkeley-db@5"].opt_include}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    (pkgetc/"apt.conf.d").mkpath
  end

  test do
    assert_match "apt does not have a stable CLI interface. Use with caution in scripts",
                 shell_output("#{bin}/apt list 2>&1")
  end
end
