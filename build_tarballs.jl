# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FreeType2"
version = v"2.10.0"

# Collection of sources required to build FreeType2
sources = [
    "https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.gz" =>
    "955e17244e9b38adb0c98df66abb50467312e6bb70eac07e49ce6bd1a20e809a",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ "${target}" == *mingw* ]]; then

cd freetype-2.10.0/builds
cat > exports.patch << 'END'
--- exports.mk
+++ exports.mk
@@ -30,9 +30,7 @@
   # on the host machine.  This isn't necessarily the same as the compiler
   # which can be a cross-compiler for a different architecture, for example.
   #
-  ifeq ($(CCexe),)
-    CCexe := $(CC)
-  endif
+  CCexe := /opt/x86_64-linux-gnu/bin/gcc   # use hard-coded path

   # TE acts like T, but for executables instead of object files.
   ifeq ($(TE),)
END

patch --ignore-whitespace < exports.patch

cd ..
./configure --prefix=$prefix --host=$target

else

cd freetype-2.10.0
mkdir build && cd build
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.toolchain"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_SHARED_LIBS=true"
cmake .. ${CMAKE_FLAGS}

fi

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libfreetype", :libfreetype)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/staticfloat/Bzip2Builder/releases/download/v1.0.6-1/build_Bzip2.v1.0.6.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl"

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
