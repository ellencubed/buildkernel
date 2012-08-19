#!/bin/sh

src_dir=/usr/src/linux
boot_dir=/boot
img_type=bzImage
name=
jnum=1
odir=
config_kernel=

check_if_root(){
	if [ $(id -u) -ne 0 ]
		then
		return 1
	else
		return 0
	fi
}

getversion(){
	sed -n /^VERSION\ \=\ /p $src_dir/Makefile | awk '{printf "%s.",$3}'
	sed -n /^PATCHLEVEL\ \=\ /p $src_dir/Makefile | awk '{printf "%s.",$3}'
	sed -n /^SUBLEVEL\ \=\ /p /$src_dir/Makefile | awk '{printf "%s",$3}'
	sed -n /^EXTRAVERSION\ \=\ /p $src_dir/Makefile | awk '{printf "%s",$3}'
}

build_image(){
	if [ ! -e $src_dir/.config ] || [ $config_kernel ]
	then
		echo "running menuconfig..."
		make menuconfig
	fi
	
	echo "building kernel image"
	make -j $jnum $img_type 1>/dev/null 2>&1
}

usage(){
	echo "usage: $0 <options>"
	echo ""
	echo "-s source_directory"
	echo "-b boot_directory"
	echo "-i image_type"
	echo "-j number_of_jobs"
	echo "-f filename"
	echo "-m perform menuconfig"
	echo "-h this message"
}

install_image(){
	echo "installing kernel image"
	cp $src_dir/arch/x86/boot/bzImage $boot_dir/${name:-linux-$(getversion)}
}

build_modules(){
	echo "building modules"
	make modules > /dev/null
}

install_modules(){
	echo "installing modules"
	make modules_install > /dev/null
}

echo Linux Kernel Compiling Script
echo Written by Ellen Taylor \($(echo "ellen.doesn't.like.spam.in.her.gmail.account" | cut -d. -f1,7 | awk -F. '{printf "%scubed%c%s.com",$1,"@",$2}')\)
echo ""

if ! check_if_root
then
	echo "script must be run as root"
	exit 1
fi

while getopts :s:b:i:j:f:mh opt
do
	case $opt in
		s)
			src_dir=$OPTARG
			;;
		b)
			boot_dir=$OPTARG
			;;
		i)
			img_type=$OPTARG
			;;
		j)
			jnum=$OPTARG
			;;
		f)
			name=$OPTARG
			;;
		m)
			config_kernel=true
			;;
		h)
			usage
			exit 0
			;;
		'?')
			echo "$0: invalid option -$OPTARG"
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND - 1))

odir=$PWD
cd $src_dir

if ! build_image; then
	echo error building kernel image
	exit 1
fi

if ! build_modules; then
	echo error building modules
	exit 1
fi

if ! install_image; then
	echo error installing kernel
	exit 1
fi

if ! install_modules; then
	echo error installing modules
	exit 1
fi

cd $odir
echo Done
