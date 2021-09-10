ZYNQMP SPL ROM authentication
===============================

OVERVIEW:

Helper scripts:

 1) generate_bootgen.sh
    patches bootgen with support for spl binaries and buildts bootgen-spl

    must be called first

 2) generate_keys.sh
    generates the keys required for authentication based on the
    bifs/keys.bif definition

    WARNING: Once the PPK fuse has been written, do NOT generate these keys again

3) generate_bootbin.sh
    accepting pmu.bin and u-boot-spl.bin as input parameters (as
    defined by the bifs/boot.bif file) it will generate the PPK fuse
    sha and the boot.bin

 4) check_bootbin.sh
    dumps the boot-header information on boot.bin and verifies the bootable image

 5) generate_fpga.sh
    accepting the keys and a bitstream, generates a signed fpga bitstream. Notice that signed
    FPGAs will be authenticated by the firwmare and therefore they require an adjusted FIT load
    command in SPL or the load will fail.

For clarity, this README shall include references to an hypotetical
target board (from now on THE_TARGET).

I. Generate keys
=================

Uses bootgen to generate primary and secondary keys (the primary key
is being used to verify the secondary key hence why we'll need to fuse
the Primary Public key).

$ cat bif.keys
the_ROM_image:
{
        [ppkfile] <PPK.pem>
        [pskfile] <PSK.pem>
        [spkfile] <SPK.pem>
        [sskfile] <SSK.pem>
}

$ bootgen -arch zynqmp -image bif.keys -generate_keys pem

II. Generate boot.bin and eFUSE
===============================

We need to patch bootgen-native to support generating boot.bin images
using binary bootloaders instead of elf files.

 # https://github.com/Xilinx/bootgen/pull/10

Then build spl and use the following bif file to generate the
flashable boot.bin and eFUSE_PPK.txt file (sha384 for the primary
public key).

$ cat bif
the_ROM_image:
{
        [auth_params] ppk_select=0; spk_id=0x00000000
        [pskfile] keys/PSK.pem
        [sskfile] keys/SSK.pem
        [pmufw_image, load=0xffdc0000] pmu.bin
        [bootloader, authentication=rsa, destination_cpu=a53-0, load=0xfffc0000] u-boot-spl.bin
}

$ ./bootgen -arch zynqmp -image bif -w on -o boot.bin -efuseppkbits eFUSE_PPK.txt

This command therefore will generate two files:
 1) boot.bin
    The bootable image:  bootheaders + certificates + PMUFW + SPL + dtb

    To display the bootheader and certificate information:
    $ ./bootgen -arch zynqmp -read boot.bin

 2) eFUSE_PPK.txt
    The SHA-384 to write to the PPK eFuse

III. Write eFUSE
================

Use the VIVADO Lightweight Provisioning Tool to write to the PPK efuse
the file eFUSE_PPK.txt.

This tool is provided by Xilinx and it only executes in a Vivado
install. Is generic to all Zynqmp platforms.

jramirez@trex ligth_weight_provisioning_tools (master)$ ls -l
total 5996
drwxrwxr-x 5 jramirez jramirez    4096 jul 19 10:54 ..
-rw-rw-r-- 1 jramirez jramirez     629 jun 29 07:40 xlwp_tool.csh
-rwxrwxr-x 1 jramirez jramirez     157 jun 29 07:39 xlwp_term.csh
-rw-rw-r-- 1 jramirez jramirez 1369320 jun 28 15:13 xlwp_zup_60mhz.elf
-rw-rw-r-- 1 jramirez jramirez   14287 jun 28 15:13 xlwp_zup_cmds.tcl
-rw-rw-r-- 1 jramirez jramirez   10820 jun 28 15:13 xlwp_zup_script.tcl
-rw-rw-r-- 1 jramirez jramirez 1369320 jun 28 15:13 xlwp_zup_50mhz.elf
-rw-rw-r-- 1 jramirez jramirez 1369320 jun 28 15:13 xlwp_zup_33mhz.elf
-rw-rw-r-- 1 jramirez jramirez 1369296 jun 28 15:13 xlwp_zup_27mhz.elf
-rw-rw-r-- 1 jramirez jramirez  713365 jun 28 15:13 xlwp_tool.pdf
-rw-rw-r-- 1 jramirez jramirez   26430 jun 28 15:13 xlwp_tool.tcl
-rw-rw-r-- 1 jramirez jramirez   22174 jun 28 15:13 tt_jtag_uart.ini
-rw-rw-r-- 1 jramirez jramirez   12815 jun 28 15:13 xlwp_readme.txt
-rw-rw-r-- 1 jramirez jramirez      76 jun 28 15:13 xlwp_term.bat
-rw-rw-r-- 1 jramirez jramirez     962 jun 28 15:13 xlwp_tool.bat

Note that THE_TARGET might use the 33MHz clock therefore update
xlwp_tool.csh to xlwp_tool_THE_TARGET.sh

jramirez@trex lwip (master)$ cat xlwp_tool_THE_TARGET.sh
#!/bin/bash
xsdb xlwp_tool.tcl -arch zynqmp \
     -mode user \
     -hw_server 127.0.0.1:3121 \
     -ps_ref_clk 33 \ <---------------------- 33 MHz clock
     -term_app xlwp_term.csh \
     -xlwp_script xlwp_zup_script.tcl \
     -log_dir logs

A window will open; use this tool to navigate to the efuse menu and
then pass the content of the previously generated eFUSE_PPK.txt file.

IV. NOTES
========

Note I: secure boot and JTAG
----------------------------
When booting an authenticated image, JTAG will be disabled.

To make sure this is not the case, enable SPL_ZYNQMP_RESTORE_JTAG in
U-boot config.

       https://lists.denx.de/pipermail/u-boot/2021-July/455132.html

Note II: Vivado in a container:
------------------------------
To install Vivado on a container:

Clone this repository
      https://github.com/ldts/petalinux-docker

jramirez@trex petalinux$ cat 0.build.2019.sh

#!/bin/bash
cd petalinux-docker
docker build --build-arg PETA_VERSION=2019.2 --build-arg PETA_RUN_FILE=petalinux-v2019.2-final-installer.run -t petalinux:2019.2 .

jramirez@trex sandbox$ cat 1.run.2019.sh

#!/bin/bash
cd /home/jramirez/Foundries/projects/petalinux/petalinux-docker
docker run --privileged -ti --rm \
       -e DISPLAY=$DISPLAY \
       --net="host" \
       -v /tmp/.X11-unix:/tmp/.X11-unix \
       -v $HOME/.Xauthority:/home/vivado/.Xauthority \
       -v /home/jramirez/Foundries/projects/petalinux/project:/home/vivado/project \
       -v /dev:/dev petalinux:2019.2 \
       /bin/bash

On execution:

* Stopping internet superserver xinetd
* Starting internet superserver xinetd
PetaLinux environment set to '/opt/Xilinx/petalinux'
INFO: Checking free disk space
INFO: Checking installed tools
INFO: Checking installed development libraries
INFO: Checking network and other services

At this point, xdb and program_flash available to use from the command
line

 1) xsdb
    JTAG interface

 2) program_flash:
    to use the jtag to flash to QSPI (notice that we  need zynqmp_fsbl.elf for this operation)

    To program boot.bin (ie, for THE_TARGET)
    $ program_flash -f boot.bin \
                    -offset 0 \
		    -flash_type qspi-x4-single \
		    -fsbl zynqmp_fsbl.elf \
		    -blank_check -verify -cable type xilinx_tcf url TCP:127.0.0.1:3121

    To program FIT (ie, for THE_TARGET)
    $ program_flash -f u-boot.itb \
                    -offset 0x80000 \
		    -flash_type qspi-x4-single \
		    -fsbl zynqmp_fsbl.elf \
		    -cable type xilinx_tcf url TCP:127.0.0.1:3121
