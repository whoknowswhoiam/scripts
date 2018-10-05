#!/bin/bash
#curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build started for commit $(git log --pretty=format:'%h : %s' -1)" -d chat_id=$CHAT_ID
rm -rf out
mkdir -p out
make O=out ARCH=arm64 test_defconfig
ZIPNAME="WeebKernelOOS_$(date '+%Y-%m-%d_%H:%M:%S').zip"
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="${pwd}/android_prebuilts_clang_host_linux-x86/clang-r328903/bin/clang" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="$(pwd)/aarch64-linux-android/bin/aarch64-opt-linux-android-"
rm -rf ${pwd}/anykernel/ramdisk/modules/wlan.ko
rm -rf ${pwd}/anykernel/kernels/oos/Image.gz-dtb
chmod +x -R $(pwd)/out
mkdir anykernel/kernels
mkdir anykernel/kernels/oos
mkdir anykernel/ramdisk/modules
cp ${pwd}/out/arch/arm64/boot/Image.gz-dtb ${pwd}/anykernel/kernels/oos/
cp ${pwd}/out/drivers/staging/qcacld-3.0/wlan.ko ${pwd}/anykernel/ramdisk/modules
find ${pwd}/anykernel/ramdisk/modules -name '*.ko' -exec${pwd}/out/scripts/sign-file sha512 ${pwd}/out/certs/signing_key.pem ${pwd}/out/certs/signing_key.x509 {} \;
cd $(pwd)/anykernel
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
cd ..

#curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Branch: $(git rev-parse --abbrev-ref HEAD)" -d chat_id=$CHAT_ID
#curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Commit: $(git log --pretty=format:'%h : %s' -1)" -d chat_id=$CHAT_ID
#curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Download:" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"path_to_zip" https://api.telegram.org/bot$BOT_API_KEY/sendDocument