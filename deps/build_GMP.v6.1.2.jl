using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libgmp"], :libgmp),
    LibraryProduct(prefix, ["libgmpxx"], :libgmpxx),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaBinaryWrappers/GMP_jll.jl/releases/download/GMP-v6.1.2+5"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.aarch64-linux-gnu-cxx03.tar.gz", "c8dd7e07cb82260ef34682e08ef6d2924a610569e2f5cd98419bb2dcb6e60524"),
    Linux(:aarch64, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.aarch64-linux-gnu-cxx11.tar.gz", "130bf229c56f25e396366553752f6215be5491520556b3fda8ed79f76af4eca7"),
    Linux(:aarch64, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.aarch64-linux-musl-cxx03.tar.gz", "e39b05c2379a311a426946150e5e10baff03f1d44ae03bb359e2594d9973411e"),
    Linux(:aarch64, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.aarch64-linux-musl-cxx11.tar.gz", "0bb07a22a7cd5dc1028db8b1dc6bfc897bc8bad67d42ea644d58b63c67ac87d8"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.armv7l-linux-gnueabihf-cxx03.tar.gz", "c65ef226121b2f83dff5e0706f9c2a9c89d631a9e696ec4245db8f34d523a1b4"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.armv7l-linux-gnueabihf-cxx11.tar.gz", "4e4694472e941f3f16632bdf532d953948a1d86845867bca324b424a444470d7"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.armv7l-linux-musleabihf-cxx03.tar.gz", "1d027c2279bc7fb965d29936b4fdd94aec6fce73fa078512eb66b112b007a7ed"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.armv7l-linux-musleabihf-cxx11.tar.gz", "bd54dffd382b6a973a3ff3351a2360419efda4d0aed1895b10485b68cc04d2f5"),
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.i686-linux-gnu-cxx03.tar.gz", "924ce570a667e554be131b6f016e7be4a4d9bcb3805674f284dac732be59c664"),
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.i686-linux-gnu-cxx11.tar.gz", "f06a382cf1de344e492dbcc947d32b0344cbe524f95f55de0c26fa0d69e3dd09"),
    Linux(:i686, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.i686-linux-musl-cxx03.tar.gz", "b81b8c73c6a09e6ec9365b3801a5a8694a7b8fec9dbe21575aec45bcb00ebba9"),
    Linux(:i686, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.i686-linux-musl-cxx11.tar.gz", "a9b24f822050a99f20370bb66807d2e011e2d5c8f66db625f636795700b3a7e4"),
    Windows(:i686, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.i686-w64-mingw32-cxx03.tar.gz", "bfa320b37a0c5597809792b33e472ae573c3ae3b9823dcb51bc93f4594f24c59"),
    Windows(:i686, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.i686-w64-mingw32-cxx11.tar.gz", "c02853d8e5cf0c89611030d28ff930c2ca3ff412440a4da74ff49ff9511f8f7c"),
    Linux(:powerpc64le, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.powerpc64le-linux-gnu-cxx03.tar.gz", "c803fa0fa7152091df080c25569fd35e724d33a5761d793e7be9134498eab1ac"),
    Linux(:powerpc64le, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.powerpc64le-linux-gnu-cxx11.tar.gz", "e9e507486448a730e0a87c7229bf360b46254893cadc67da5c7d2306437c0e1e"),
    MacOS(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.x86_64-apple-darwin14-cxx03.tar.gz", "4a7ea5d8efe6909bddb5a82fe497e680c15e2b1c847a06a13fc64597bec32ac5"),
    MacOS(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.x86_64-apple-darwin14-cxx11.tar.gz", "8693d06c3ad2d1442722a85519d754619f4ed998b9189f13659e20db2a2a6681"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.x86_64-linux-gnu-cxx03.tar.gz", "738390b5d59be5650af95c03d82eb90193d53a2deea4f009e574e47748d80cf3"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.x86_64-linux-gnu-cxx11.tar.gz", "ab29a335c8341add421739ee0fbe989b49e5e8b2fd9995904689eeee6bdb5534"),
    Linux(:x86_64, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.x86_64-linux-musl-cxx03.tar.gz", "39342be3866d7171b64ab492499a10030071965549d5d409d8867d06bbac105b"),
    Linux(:x86_64, libc=:musl, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.x86_64-linux-musl-cxx11.tar.gz", "14c421bc4a8a429fadcd42b5206bbfb53bb709f6f95d9af4bf18a6fa58c4cd67"),
    FreeBSD(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.x86_64-unknown-freebsd11.1-cxx03.tar.gz", "bdeeb7504760c248aa8121acc433d8104381d618f5144c21e56bd8ebb4167051"),
    FreeBSD(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.x86_64-unknown-freebsd11.1-cxx11.tar.gz", "324c09761ff49f4cb523fe8ef721bbf40f601029a3b4f3df74daeecaeccf89d7"),
    Windows(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx03)) => ("$bin_prefix/GMP.v6.1.2.x86_64-w64-mingw32-cxx03.tar.gz", "362a38432bfeeda17d1b02bbc83e5f83ef8276ae4dc732b0fc7237966bf58e4e"),
    Windows(:x86_64, compiler_abi=CompilerABI(:gcc_any, :cxx11)) => ("$bin_prefix/GMP.v6.1.2.x86_64-w64-mingw32-cxx11.tar.gz", "2c50fc577ee090d46faba104ba3a4f328cc642024377bcfd968f48fe93954bca"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
# write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
