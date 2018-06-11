#!/usr/bin/env bash
# Copied from cquery-project/cquery
version=$1
root=$(pwd)
cd "$root/release"

case $(uname -s) in
  Darwin)
    libclang=(lib/libclang.dylib)
    strip_option="-x"
    name=cquery-$version-x86_64-apple-darwin ;;
  FreeBSD)
    libclang=(lib/libclang.so.?)
    strip_option="-s"
    name=cquery-$version-x86_64-unknown-freebsd10 ;;
  Linux)
    libclang=(lib/libclang.so.?)
    strip_option="-s"
    name=cquery-$version-x86_64-unknown-linux-gnu ;;
  *)
    echo Unsupported >&2
    exit 1 ;;
esac

cd "$pkg"
strip "$strip_option" "bin/cquery" "${libclang[-1]}"
case $(uname -s) in
  Darwin)
    # https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/tar.1.html
    # macOS's bsdtar is lack of flags to set uid/gid.
    # First, we generate a list of file in mtree format.
    tar -cf filelist --format=mtree --options="!all,time,mode,type" "$name"
    # Then add a line "/set uid=0 gid=0" after the first line "#mtree".
    awk '/#mtree/{print;print "/set uid=0 gid=0";next}1' filelist > newflielist
    # Finally, use the list to generate the tarball.
    tar -zcf "$name.tar.gz" @newflielist ;;
  Linux)
    tar -Jcf "$name.tar.xz" --owner 0 --group 0 --exclude='cquery-clang*' --exclude='release/lib/clang' --exclude='release/include' * ;;
  *)
    tar -Jcf "$name.tar.xz" --uid 0 --gid 0 --exclude='cquery-clang*' --exclude='release/lib/clang' --exclude='release/include' * ;;
esac
