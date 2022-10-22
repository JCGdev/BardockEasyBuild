#! /bin/bash

# BardockEasyBuild v0.0.1 - By JCGdev
VERSION="v0.0.1"

##################################################################################
# Cleaning is done on three levels.						 #
# make clean     Delete most generated files					 #
#                Leave enough to build external modules				 #
# make mrproper  Delete the current configuration, and all generated files	 #
# make distclean Remove editor backup files, patch leftover files and the like	 #
##################################################################################

RUNTIME_PATH="$(dirname $(realpath $0))"

device="bq aquaris X"
product="bardock"
ARCHITECTURE="arm64"
device_defconfig="${product}_defconfig"

KERNEL_PATH="${RUNTIME_PATH}/aquaris-X"
KERNEL_OUT_PATH="${RUNTIME_PATH}/KERNEL_OUT"
defconfig_path="$KERNEL_PATH/arch/arm64/configs/bardock_defconfig"
TOOLCHAIN_PATH="${RUNTIME_PATH}/aarch64-linux-android-4.9"

cores=$(nproc --all)
                                                                                                         
RED="\033[0;31m"                                                                                         
GREEN="\e[0;92m"                                                                                         
RESET="\033[0m"

#------------------------------------------------------------------------------


# PARAM1 -> name of defconfig (usually located in KERNEL/arch/arm64/configs/*_deconfig)
createConfigs(){
	defconfig=$1

	make -j $cores -C $KERNEL_PATH O=$KERNEL_OUT_PATH ARCH=$ARCHITECTURE \
	CROSS_COMPILE=$TOOLCHAIN_PATH $defconfig
	printFinishedTaskWithExitCode "Creating .config file from defconfig"

}

compile(){
	make -j $cores -C $KERNEL_PATH O=$KERNEL_OUT_PATH ARCH=$ARCHITECTURE \
	CROSS_COMPILE=${TOOLCHAIN_PATH}/bin/aarch64-linux-android-
	printFinishedTaskWithExitCode "Compiling kernel codebase"
}

cleanCodebase(){
	make -C $KERNEL_PATH mrproper
	printFinishedTaskWithExitCode "Cleaning codebase (mrproper)"

}

hardRestoreOriginalCodebase(){
	git -C $KERNEL_PATH reset --hard HEAD
	printFinishedTaskWithExitCode "Restoring to original codebase"
}

#PARAM1 --> message
printFinishedTaskWithExitCode(){
    
    exitCode=$?
    if [ "$exitCode" == "0" ]
    then
        echo -e "${GREEN}[SUCCESS] While $1 (EXIT CODE: ${exitCode})${RESET}"
        sleep 3
    else
        echo -e "${RED}[ERROR] While $1 (EXIT CODE ${exitCode})${RESET}"
        exit 1
    fi
}

#------------------------------------------------------------------------------



echo "[BardockEasyBuild] ${VERSION} - By JCGdev"


if [ ! -d $TOOLCHAIN_PATH ]
then
	git clone "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9" \
	--branch "android-8.1.0_r41"
fi

if [ ! -d $KERNEL_PATH ]
then
	git clone "https://github.com/bq/aquaris-X.git" --branch "2.11.0_20191121-1509"
fi

if [ -d ${KERNEL_OUT_PATH} ]
then
	rm -rf ${KERNEL_OUT_PATH}
else 
	mkdir ${KERNEL_OUT_PATH}
fi


# Adding extern keyword in order to avoid this issue: 
# usr/bin/ld: scripts/dtc/dtc-parser.tab.o:(.bss+0x10): multiple definition of 'yylloc'; script#s/dtc/dtc-lexer.lex.o:(.bss+0x0): first defined here

grep -o "extern YYLTYPE" "${KERNEL_PATH}/scripts/dtc/dtc-lexer.l" 1>&2 2>/dev/null
exitCode1=$?
grep -o "extern YYLTYPE" "${KERNEL_PATH}/scripts/dtc/dtc-lexer.lex.c_shipped" 1>&2 2>/dev/null
exitCode2=$?

if [[ exitCode1 -ne 0 ]] && [[ exitCode2 -ne 0 ]]
then
	sed -i  "s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" ${KERNEL_PATH}/scripts/dtc/dtc-lexer.l 1>&2 2>/dev/null 
	printFinishedTaskWithExitCode "Adding extern keywork to 'YYLTYPE yylloc' in '${KERNEL_PATH}/scripts/dtc/dtc-lexer.l' "

	sed -i  "s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" ${KERNEL_PATH}/scripts/dtc/dtc-lexer.lex.c_shipped 1>&2 2>/dev/null
	printFinishedTaskWithExitCode "Adding extern keywork to 'YYLTYPE yylloc' in '${KERNEL_PATH}/scripts/dtc/dtc-lexer.lex.c_shipped' "
fi
	
	
cleanCodebase
createConfigs $device_defconfig

make -C $KERNEL_PATH menuconfig
compile
	




