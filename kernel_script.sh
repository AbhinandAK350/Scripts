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
x=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
y=$(awk '/MemFree/ {print $2}' /proc/meminfo)
CLANG_VERSION=r399163b
DEFCONFIG=onclite-perf_defconfig
ANDROID_PATCH=10.0.0_r47

get_tools()
{
	echo -e "\n${BLUE}Installing tools...${NOC}"
	echo " "
	# Install build package for debian based linux
	sudo apt-get -y install bc bash git-core gnupg build-essential zip curl make automake autogen autoconf autotools-dev libtool shtool python m4 gcc libtool zlib1g-dev flex bison libssl-dev

	echo -e "\n${BLUE}Cloning toolchain...${NOC}"
	echo " "
	# Clone toolchain
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-${ANDROID_PATCH} --depth=1 stock
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-${ANDROID_PATCH} --depth=1 stock_32

	echo -e "\n${BLUE}Cloning AnyKernel3...${NOC}"
	echo " "
	# Clone AnyKernel3
	git clone https://github.com/AbhinandAK350/AnyKernel3 -b onclite

	echo -e "\n${BLUE}Downoading clang...${NOC}"
	echo " "
	#Download Clang
	if [ ! -d clang ]; then
	    wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-${CLANG_VERSION}.tar.gz
	    mkdir -p clang/clang-${CLANG_VERSION}
	    tar xvzf clang-r383902c.tar.gz -C clang/clang-${CLANG_VERSION}
	    rm clang-${CLANG_VERSION}.tar.gz
	fi

	echo -e "\n${GREEN}Tools installation done! Starting build...${NOC}"
	echo " "
}

build()
{
	echo -e "\n${YELLOW}Processor cores: "$(nproc)
	echo -e "${YELLOW}Total Memory: "`expr $x \/ 1024 \/ 1024` GB
	echo -e "${YELLOW}Free Memory: "`expr $y \/ 1024 \/ 1024` GB
	echo -e "\n${BLUE}Build started...${NOC}"
	echo ""
	# Main environtment
	KERNEL_DIR=$PWD
	KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
	ZIP_DIR=$KERNEL_DIR/AnyKernel3
	CONFIG=$DEFCONFIG
	CROSS_COMPILE="aarch64-linux-android-"
	CROSS_COMPILE_ARM32="arm-linux-androideabi-"
	PATH=:"${KERNEL_DIR}/clang/clang-${CLANG_VERSION}/bin:${PATH}:${KERNEL_DIR}/stock/bin:${PATH}:${KERNEL_DIR}/stock_32/bin:${PATH}"

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

	cd $ZIP_DIR
	cp $KERN_IMG zImage
	make normal &>/dev/null
	echo -e "\n${BLUE}Flashable zip generated under $ZIP_DIR.${NOC}"
	cd ..
	# Build end
	echo ""
	echo -e "\n${GREEN}Build successfull!${NOC}\n"
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
