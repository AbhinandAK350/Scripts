# Kernel compliation script
# © copyright 2021. Abhinand A K

# Env
export PATH="$HOME/proton-clang/bin:$PATH"
SECONDS=0
DEVICE=""
KERNEL_NAME="perf"
export ARCH="arm64"
CONFIG="$DEVICE-perf_defconfig"
ZIPNAME="$KERNEL_NAME-$DEVICE-$(date '+%Y%m%d-%H%M').zip"

# Clang
if ! [ -d "$HOME/proton-clang" ]; then
	echo "Proton clang not found! Cloning..."
	if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang ~/proton; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

mkdir -p out
ccache make O=out ARCH=$ARCH $CONFIG

# Compile
if [[ $1 == "-r" || $1 == "--regen" ]]; then
	cp out/.config arch/$ARCH/configs/$CONFIG
	echo -e "\nRegened defconfig succesfully!"
	exit 0
else
	echo -e "\nStarting compilation...\n"
	if [ $ARCH == "arm64" ]; then IMAGE="Image.gz-dtb" ; elif [ $ARCH == "arm" ]; then IMAGE="zImage-dtb" ; fi
	ccache make -j$(nproc --all) O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- $IMAGE dtbo.img
fi

# Packing
if [ -f "out/arch/$ARCH/boot/Image.gz-dtb" ] && [ -f "out/arch/$ARCH/boot/dtbo.img" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if ! [ -d "AnyKernel3" ]; then
		git clone -q https://github.com/AbhinandAK350/AnyKernel3 -b $DEVICE
	fi

	if [[ $1 == "-m" || $1 == "--miui" ]]; then
		# For MIUI
		# Credit Adek Maulana <adek@techdro.id>
		OUTDIR="$PWD/out/"
		VENDOR_MODULEDIR="$PWD/AnyKernel3/modules/vendor/lib/modules"

		STRIP="$HOME/proton-clang/aarch64-linux-gnu/bin/strip$(echo "$(find "$HOME/proton-clang/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
				sed -e 's/gcc/strip/')"

		for MODULES in $(find "${OUTDIR}" -name '*.ko'); do
			"${STRIP}" --strip-unneeded --strip-debug "${MODULES}"
			"${OUTDIR}"/scripts/sign-file sha512 \
					"${OUTDIR}/certs/signing_key.pem" \
					"${OUTDIR}/certs/signing_key.x509" \
					"${MODULES}"
			find "${OUTDIR}" -name '*.ko' -exec cp {} "${VENDOR_MODULEDIR}" \;

			case ${MODULES} in
					*/wlan.ko)
				cp "${MODULES}" "${VENDOR_MODULEDIR}/pronto_wlan.ko" ;;
			esac

		done
	fi

	cp out/arch/$ARCH/boot/Image.gz-dtb AnyKernel3
	cp out/arch/$ARCH/boot/dtbo.img AnyKernel3
	rm -f *zip
	cd AnyKernel3
	rm -f *zip
	zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
	cd ..
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	rm -rf out/arch/$ARCH/boot
else
	echo -e "\nCompilation failed!"
fi
