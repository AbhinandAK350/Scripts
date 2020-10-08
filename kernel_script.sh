#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2018 Raphiel Rollerscaperers (raphielscape)
# Copyright (C) 2018 Rama Bondan Prakoso (rama982)
# Copyright (C) 2020 Abhinand A K.
# Android Kernel Build Script

RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NOC='\033[0;m'

get_tools()
{
	echo -e "${BLUE}Installing tools...${NOC}"
	echo " "
	# Install build package for debian based linux
	sudo apt-get -y install bc bash git-core gnupg build-essential zip curl make automake autogen autoconf autotools-dev libtool shtool python m4 gcc libtool zlib1g-dev flex bison libssl-dev

	echo -e "${BLUE}Cloning toolchain...${NOC}"
	echo " "
	# Clone toolchain
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-10.0.0_r35 --depth=1 stock
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-10.0.0_r35 --depth=1 stock_32

	echo -e "${BLUE}Cloning AnyKernel3...${NOC}"
	echo " "
	# Clone AnyKernel3
	git clone https://github.com/AbhinandAK350/AnyKernel3 -b onclite

	echo -e "${BLUE}Downoading clang...${NOC}"
	echo " "
	#Download Clang
	if [ ! -d clang ]; then
	    wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r383902c.tar.gz
	    mkdir -p clang/clang-r383902c
	    tar xvzf clang-r383902c.tar.gz -C clang/clang-r383902c
	    rm clang-r383902c.tar.gz
	fi

	echo -e "${BLUE}Downloading libufdt...${NOC}"
	echo " "
	# Download libufdt
	if [ ! -d libufdt ]; then
	    wget https://android.googlesource.com/platform/system/libufdt/+archive/refs/tags/android-10.0.0_r35/utils.tar.gz
	    mkdir -p libufdt
	    tar xvzf utils.tar.gz -C libufdt
	    rm utils.tar.gz
	fi
	echo -e "${GREEN}Tools installation done! Starting build...${NOC}"
	echo " "
}

build()
{
	echo "Entert the name of the defconfig"
	read DEFCONFIG
	echo -e "${BLUE}Build started...${NOC}"
	echo ""
	# Main environtment
	KERNEL_DIR=$PWD
	KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
	ZIP_DIR=$KERNEL_DIR/AnyKernel3
	CONFIG=$DEFCONFIG
	CROSS_COMPILE="aarch64-linux-android-"
	CROSS_COMPILE_ARM32="arm-linux-androideabi-"
	PATH=:"${KERNEL_DIR}/clang/clang-r383902c/bin:${PATH}:${KERNEL_DIR}/stock/bin:${PATH}:${KERNEL_DIR}/stock_32/bin:${PATH}"

	# Export
	export ARCH=arm64
	export CROSS_COMPILE
	export CROSS_COMPILE_ARM32

	# Build start
	make O=out $CONFIG
	make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android-

	if ! [ -a $KERN_IMG ]; then
	    echo ""
	    echo -e "${RED}Build error!${NOC}"
	    exit 1
	fi

	cd $ZIP_DIR
	make clean &>/dev/null
	cd ..

	# For MIUI Build
	# Credit Adek Maulana <adek@techdro.id>
	#OUTDIR="$KERNEL_DIR/out/"
	#VENDOR_MODULEDIR="$KERNEL_DIR/AnyKernel3/modules/vendor/lib/modules"
	#STRIP="$KERNEL_DIR/stock/bin/$(echo "$(find "$KERNEL_DIR/stock/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
    #    	    sed -e 's/gcc/strip/')"
	#for MODULES in $(find "${OUTDIR}" -name '*.ko'); do
	#    "${STRIP}" --strip-unneeded --strip-debug "${MODULES}"
	#    "${OUTDIR}"/scripts/sign-file sha512 \
	#            "${OUTDIR}/certs/signing_key.pem" \
	#            "${OUTDIR}/certs/signing_key.x509" \
	#            "${MODULES}"
	#    find "${OUTDIR}" -name '*.ko' -exec cp {} "${VENDOR_MODULEDIR}" \;
	#done
	#echo -e "\n(i) ${BLUE}Done moving modules${NOC}"

	cd $ZIP_DIR
	cp $KERN_IMG zImage
	make normal &>/dev/null
	echo -e "${BLUE}Flashable zip generated under $ZIP_DIR.${NOC}"
	cd ..
	# Build end
	echo ""
	echo -e "${GREEN}Build successfull!${NOC}"
}

echo "Do you want to setup build environment?(Y/N)"
read env_setup
case $env_setup in
[Yy]* )
	get_tools
	build
;;
[Nn]* )
	build
esac