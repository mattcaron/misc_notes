# Basic install

This is a synthesis of the docs and the `MiSTer-sd-installer-linux.sh` script from `https://github.com/michaelshmitty/SD-Installer-macos_MiSTer`.

1. Get the latest installer .rar file from https://github.com/MiSTer-devel/SD-Installer-Win64_MiSTer

1. Get the latest core release from https://github.com/MiSTer-devel/Main_MiSTer/tree/master/releases

1. Get the latest menu file from https://github.com/MiSTer-devel/Menu_MiSTer/tree/master/releases

1. Make an appropriately named directory.

1. `unrar x` the file into that directory.

1. Make sure the SD card is unmounted so you can do low level stuff with it.

1. On this box, it's `/dev/mmcblk0`

1. Run this sfdisk command. It creates 2 partitions, in backwards order - the large one, created as partition 1, is created first, but is second on the disk. The notes say this is so it can be expanded. (Just read the script).

        sudo sfdisk /dev/mmcblk0 << EOF
        4096;
        2048,2048
        EOF

1. Make sure the disk is unmounted, then eject and reinsert it to ensure it is using the current partition table.

1. Set the partition ID for the first partition to be 7 and the second to be a2.

        sudo sfdisk -d /dev/mmcblk0 | sed '0,/type=.*$/s//type=7/' | sed '0,/type=.*$/! s/type=.*$/type=a2/' | sudo sfdisk /dev/mmcblk0

1. Write u-boot:

        sudo ddrescue release_20200429/files/linux/uboot.img /dev/mmcblk0p2  --force --sync

1. Create the filesystem:

        sudo mkfs.exfat -n "MiSTer_Data" /dev/mmcblk0p1

1. `sudo sync` and eject the card, then reinsert it to trigger automount.

1. Copy the installer files to the disk:

        cp -a release_20200429/files/* /media/matt/MiSTer_Data/.

1. Copy the main MiSTer binary over, making sure to rename it:

        cp -a MiSTer_20200602 /media/matt/MiSTer_Data/MiSTer

1. Copy the menu over, making sure to rename it:

        cp -a menu_20200429.rbf /media/matt/MiSTer_Data/menu.rbf

1. Copy the example ini file `MiSTer_example.ini` to the root of the SD card (`/media/matt/MiSTer_Data/MiSTer.ini`). Read through it and edit it for correctness. Most notably is screen resolution. My deviations from the example are noted below:  

        vscale_mode=1    ; for integer scaling
        reset_combo=2    ; ctrl + alt + del to reboot
        video_mode=8     ; 1920 x 1080 @ 60Hz video
        vsync_adjust=2   ; Low latency video

    1. Note that Multiple versions can be switched between, see [here](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Configuration-Files#Switching-INI-Files-On-the-Fly).

1. Set up WiFi ([reference](https://github.com/MiSTer-devel/Main_MiSTer/wiki/WiFi-setup)):
    1. cp `/media/matt/MiSTer_Data/linux/_wpa_supplicant.conf /media/matt/MiSTer_Data/linux/wpa_supplicant.conf`
    1. Edit `/media/matt/MiSTer_Data/linux/wpa_supplicant.conf`
    1. Change the country code
    1. Fill out the SSID and password.

1. Wallpapers ([GitHub](https://github.com/RetroDriven/MiSTerWallpapers)):
    1. Copy stuff:

            cp Update_MiSTerWallpapers.* /media/matt/MiSTer_Data/Scripts/.

    1. By default, it will randomly display wallpapers. Edit `Update_MiSTerWallpapers.ini` and set `SELF_MANAGED=True` to select them manually (I did).
        1. To manage them manually, copy the wallpapers from `/wallpapers` subfolders to the main `/wallpapers` folder. Only the ones there will be displayed.

1. Update all script ([GitHub](https://github.com/theypsilon/Update_All_MiSTer)):
    1. Copy Stuff:

           cp ~/workspace/retrocomputing/mister/Update_All_MiSTer/update*.* /media/matt/MiSTer_Data/Scripts/.

1. ScummVM installer script ([GitHub](https://github.com/bbond007/MiSTer_ScummVM)):
    1. Copy stuff:

           cp ~/workspace/retrocomputing/mister/MiSTer_ScummVM/Install_ScummVM.* /media/matt/MiSTer_Data/Scripts/.

1. Unmount and eject it, put it in the MiSTer, hook it up, and boot it.

1. Once booted:
    1. Press F9 to get to linux.

    1. Get the wallpapers:

           cd /meda/fat/Scripts
           ./Update_MiSTerWallpapers.sh

    1. Update everything:

           cd /meda/fat/Scripts
           ./update_all.sh

    1. Install ScummVM:

           cd /meda/fat/Scripts
           ./Install_ScummVM.sh

    1. Press F1 to load a wallpaper.

    1. Useful scripts to run (these are in `/media/fat/Scripts` after update). **Note: These must be run after every update. **
        1. `./fast_USB_polling_on.sh`
        1. `./firewall_on.sh`
        1. `./ftp_off.sh`
        1. `./samba_off.sh`
        1. `./security_fixes.sh` <- this one is especially important.
        1. `./soundfont_install.sh`

1. Other access:
    1. Default User: `root`, pass `1`
    1. Console ([ref](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Console-connection)) is the port next to the ethernet jack. It's 115200 8N1.
    1. Network: ([ref](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Network-access))

1. Joysticks / gamepads /etc

These need to be set up.

1. Plug one in.
1. Press F12 twice to get to the System Settings.
1. Choose "define joystick buttons"
1. Follow instructions.

# Core config

When a core is loaded, press F12. The core setup is there. Press left or right to flip between menus.

Config notes follow. Note that I was aiming for nostalgia - what I remember it looking like when I played that system.

**Make sure to save these when you change them.**

**Also, these seem to reset every time you update.**

1. Genesis:
    1. Genesis:
        1. Region: US
        1. 320x224 Aspect: Corrected
    1. System:
        1. Scale filter: Custom, then choose "Scanlines (Bright Sharp)"
1. NES:
    1. NES:
        1. Palette: Composite
    1. System:
        1. Scale filter: Custom, then choose "Scanlines (Bright Sharp)"
1. SNES
    1. SNES: No changes
    1. System:
        1. Scale filter: Custom, then choose "SNES Scanlines (Bright Sharp)" under the "SNES Specific" subdir.

# Roms

1. [Filesystem reference](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Folders-and-File-naming)
1. Software for most things goes in the `games` subdir. It's organized by platform. Put your roms in the right subdir for your platform.
1. The directory names (filesystem case) are not always correct if using an ext4 formatted drive, as I am. Correct case is listed below:
    * AcornAtom
    * AcornElectron
    * AliceMC10
    * Altair8800
    * Amiga
    * Amstrad
    * 'Amstrad PCW'
    * AO486
    * APOGEE
    * APPLE-I
    * Apple-II
    * AQUARIUS
    * Arcadia
    * ARCHIE
    * Arduboy
    * Astrocade
    * ATARI2600
    * ATARI5200
    * ATARI7800
    * ATARI800
    * AtariLynx
    * AtariST
    * AVision
    * AY-3-8500
    * BBCMicro
    * BK0011M
    * C16
    * C64
    * ChannelF
    * Chip8
    * CO2650
    * CoCo2
    * CoCo3
    * Coleco
    * EDSAC
    * Electron
    * EpochGalaxyII
    * Galaksija
    * GAMEBOY
    * GAMEBOY2P
    * GameNWatch
    * GBA
    * GBA2P
    * Genesis
    * hbmame
    * Intellivision
    * Interact
    * Jaguar
    * Jupiter
    * Laser
    * Lynx48
    * MACPLUS
    * mame
    * MegaCD
    * MEMTEST
    * MSX
    * MultiComp
    * NEOGEO
    * NES
    * ODYSSEY2
    * Ondra_SPO186
    * ORAO
    * Oric
    * PC88
    * PC8801
    * PDP1
    * PET2001
    * PMD85
    * PSX
    * QL
    * RX78
    * S32X
    * SAMCOUPE
    * sharpmz
    * SMS
    * SNES
    * 'Sord M5'
    * Spectrum
    * SPMX
    * SuperJacob
    * SVI328
    * TatungEinstein
    * TGFX16
    * TGFX16-CD
    * TI-99_4A
    * TomyScramble
    * TRS-80
    * TSConf
    * UK101
    * VC4000
    * VECTOR06
    * VECTREX
    * VIC20
    * WonderSwan
    * X68000
    * zx48
    * ZX81
    * ZXNext

1. Mappings for stuff from Archive.org:

    1. `htgdb-gamepacks`
        1. **Notes:**
            1. Filenames prepended with @ are MiSTer ready - apparently, MiSTer can unzip zip files and just read them, which is good to know, and makes updates very convenient (just move the zip, don't move and rsync). In that case, rather than unzipping things, I've just copied the whole zip file. 7z files were unzipped.
        1. `@MiSTer Pack 2021-03-22.7z`
            1. This has a pile of stuff in it. It is basically a skeleton that one can use to set up a drive for MiSTer (see README Pack-List.TXT). Since I already have one, I didn't copy over everything. I unzipped it to a directory and picked through it.
            1. `_Computer` has some additional files. Copied those over.
            1. `_Console` has some additional files. Copied those over.
            1. `Doom` needs to go into `/media/fat/Doom`, because that's where the script puts prboom. Of course, we could move it, and maybe I will at some point, but for now, that's good enough.
            1. All the items in `Games` are generally just copied over, except where they are redundant with what I had. Notes follow:
                1. `ao486` was uninteresting - I made my own FreeDOS vhd, so their default DOS 6.22 is not useful to me.
                1. `Apple-II` had a lot of stuff, but I have stuff from TOSEC too, so I made `TOSEC` and `htgdb` directories. There is likely redundancy.
                1. `ATARI2600` - There's a `MiSTer Fixed` subdir that I copied over, but I'm not sure what was broken in the first place.
                1. `ATARI5200` had a pile of .car files (disk images?) and I also have a pile of stuff from (I think) TOSEC, so I put these in an `htgdb` subdirectory. There is likely duplication there.
                1. `Coloeco` had interesting stuff and I also had a pile of stuff from (I think) TOSEC, so I put these in an `htgdb` subdirectory. There is likely duplication there.
            1. `Scripts/Download*` goes into `/media/fat/Scripts/`. I don't need all of them (I have ScummVM and Jotego cores documented elsewhere), but the Intellivision and PrBoom scripts are of interest.
        1. `@Atari 2600 2021-04-06.zip` -> `ATARI2600`
        1. `Atari 5200 - Atarimax v1.0.7z` -> `ATARI5200`
        1. `@Atari 7800 2021-04-26.zip` -> `ATARI7800`
        1. `Atari Jaguar 2020-10-28.7z` -> `Jaguar`
        1. `@Atari Lynx 2021-03-17.7z` -> `Lynx`
        1. `@Channel F 2022-09-06.zip` -> ChannelF
        1. `@Colecovision 2020-12-17.zip` -> `Coleco`
        1. `@Famicom Disk System 2022-05-16.zip` -> `NES`
        1. `@Game Boy Color SMDB 2022-05-12.zip` -> `GAMEBOY`
        1. `@Game Boy - EverDrive GB 2020-12-22.zip` -> `GAMEBOY`
        1. `@Game Boy SMDB 2022-05-20.zip` -> `GAMEBOY`
        1. `@Game Gear - EverDrive GG 2020-01-12.zip` -> `SMS`
            1. This is not a mistake - the MiSTer SMS game gear core does both.
        1. `@GBA - EverDrive GBA 2022-08-08.zip` -> `GBA`
        1. `@GBA - EverDrive GBA Game Series Collections Add-On 2022-08-08.zip` -> `GBA`
        1. `@Genesis - MegaSD Mega EverDrive 2022-05-18.zip` -> `Genesis`
        1. `@Genesis - MegaSD Mega EverDrive Game Series Collections 2022-05-18.zip` -> `Genesis`
        1. `@Master System - Master EverDrive 2022-05-04.zip` -> `SMS`
            1. This is Sega's 8 bit console which was repackaged as the Game Gear portable later.
        1. `MegaCD` -> `MegaCD`
            1. This is several directories full of .7z files, and MiSTer doesn't grok those, so I ran `un7z_mkdir` on all of them, then removed all the .7z files.
        1. `@MiSTer Pack Add-on - Acorn Archimedes 2020-09-30.7z` -> `ARCHIE`
        1. `@MiSTer Pack Add-on - Amiga Minimig MegaAGS 2021-03-13.7z` -> `Amiga/htgdb`
            1. The various kickstart ROMs need to be moved out of there into the `games` root because the core can't go into subdirs for kickstart ROMs.
        1. `@MiSTer Pack Add-on - ao486 2020-06-27.7z` -> `AO486/htgdb`
        1. `@MiSTer Pack Add-on - AtariST 2020-06-07.7z` -> `AtariST`
        1. `@MiSTer Pack Add-on - C64 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - C64 Demos 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - MSX 2022-05-26.7z` -> `MSX`
            1. There was a hard disk image in the `MSX` subdir so I just moved it to the root `MSX` dir so I didn't end up with `MSX/MSX`, because that would be dumb.
        1. `@MiSTer Pack Add-on - NEC PC8801 2022-01-08.zip` -> `PC8801`
        1. `@MiSTer Pack Add-on - NEOGEO 2020-05-12.zip` -> `NEOGEO`
        1. `@MiSTer Pack Add-on - SNES 2020-04-15.zip` -> `SNES`
        1. `@MiSTer Pack Add-on - Spectrum 2020-04-15.zip` -> `Spectrum`
        1. `@MiSTer Pack Add-on - TSConf 2020-04-15.7z` -> `TSConf`
        1. `@NES2.0 2022-09-15.zip` -> `NES`
        1. `@NES - EverDrive N8 2021-03-23.zip` -> `NES`
        1. `@NES - EverDrive N8 Game Series Collections Add-On 2020-09-17.zip` -> `NES`
        1. `PC Engine CD Redump Supplement` -> `TGFX16-CD/PC Engine CD Redump Supplement`
            1. This is several directories full of .7z files, and MiSTer doesn't grok those, so I ran `un7z_mkdir` on all of them, then removed all the .7z files.
        1. `Project Peacock` -> `TGFX16-CD/Project Peacock`
            1. This is "Every Shoot ’em Up for the PC Engine Platform (CD, PCE/TG16, SGX)"
            1. See https://www.retrorgb.com/project-peacock-2-0-every-shoot-em-up-for-the-pc-engine-platform-cd-pce-tg16-sgx.html
            1. I put it in TGFX16-CD because I had a shot that it should be able to run all of them (even the non-CD titles). We'll see.
            1. This is several directories full of .7z files, and MiSTer doesn't grok those, so I ran `un7z_mkdir` on all of them, then removed all the .7z files.
        1. `@Sega 32X - 2022-04-21.zip` -> `S32X`
        1. `@Sega SG-1000 2022-05-20.zip` -> `Coleco` (The hardware is close
       t    enough that the core supports both machines)
        1. `@SNES - SD2SNES - Super EverDrive 2022-09-11.zip` -> `SNES`
        1. `@SNES - SD2SNES - Super EverDrive Game Series Collections 2022-09-11.zip` -> `SNES`
        1. `@TurboGrafx - PC Engine - Turbo EverDrive 2020-06-06.zip` -> `TGFX16`
        1. `@Vectrex - Vextreme 2020-12-28.zip` -> `VECTREX`
        1. `@WonderSwan 2022-04-22.zip` -> `WonderSwan`
    1. `gaplus-for-nes` -> Put in `NES`
    1. `pac-man-championship-edition-nes-demake` -> `NES`
    1. `TOSEC_V2017-04-23` (this has many things):
        1. **Note**: MiSTer can't handle zips within zips. So, check that anything you copy over is a zip of something like disk images, and doesn't contain any zips.
        1. `Apple/1`-> `Apple-I`
        1. `Apple/II` -> `Apple-II`
        1. `Amstrad/CPC` -> `Amstrad`
        1. `MITS/Altair 8800` -> `Altair8800`
    1. `Never_Ending_Amiga_Collection_2019-11` -> `games/Amiga/Never_Ending_Amiga_Collection_2019-11/.`
        1. This is a single zip file containing many subdirs of what look to be disk dumps from 5 people, plus some random files. I left them alone because there may be dupes and it just needs to be gone through.
    1. `macpack-20210626` -> `games/MACPLUS/macpack-20210626`
        1. Unzipped `MacPack-20210626.7z` and put the contents above.
        1. This is a great multi-OS setup (HD20SC.vhd) with a disk image
           (DSK.zip) full of games and such.
    1. `Sony-Playstation-USA-Redump.org-2019-05-27` -> `games/PSX`
        1. Unzipped all the files with `unzip_mkdir` (so each ends up in its own
           directory)
        1. Then I consolidated multiple disc games into a single directory.
    1. `gnw-games` -> `games/GameNWatch`
        1. This is the older Game and Watch core.
    1. `fpga-gnw-opt` -> `games/Game\ and\ Watch`
        1. This is the newer Game and Watch core.

1. Mame Mappings
    1. Put the MAME ROMS `games/mame`
    1. Put the HBMAME ROMS in `games/hbmame`
    1. **Don't unzip the ROM files**

1. The following cores have issues when outputting to a US (NTSC) TV. Fix them by hooking them to a real monitor and setting the video output correctly. Note that this is not exhaustive, because I know I fixed some already:
    * Archie
    * BK001M
    * Galaksija
    * MC10
    * TSConf
    * Game of Life

1. AO486 core notes
    1. There are a compiled list of drivers [here](https://misterfpga.org/viewtopic.php?t=71)
    1. And some Windows drivers [here](https://github.com/MiSTer-devel/ao486_MiSTer/tree/master/releases/drv)
    1. Copy `boot0.rom` and `boot1.rom` from [the readme](https://github.com/MiSTer-devel/ao486_MiSTer) and put them in `games/AO486`.
    1. Remember, it's Win+F12 to get the menu to come up.
    1. The BIOS sees disk images up to 137GB.
        1. And DOS 6.22 can only use 2GB Partitions.
        1. FreeDOS can handle one, large partition just fine.
    1. It can mount ISO, BIN and CUE format images as CDs.
    1. For DOS 6.22:
        1. Create an empty image with `dd if=/dev/zero of=dos_base.vhd bs=1M count=8000`
            1. Or larger, but 4 partitions is a lot.
        1. Copy over the Dos 6.22 install disks downloaded from [winworldpc](https://winworldpc.com/product/ms-dos/622).
        1. Mount the drive and the first disk and proceed through the install.
            1. Partition it in to 4 partitions, roughly 2GB each.
                1. This ends up being 1 primary and 3 logical.
                1. The last partition ends up being short of maximum possible by about 100MB, but I'm too lazy to recreate it, to be honest.
        1. Once the DOS install is done, run the Sound Blaster install (disk images from `Sound Blaster 2.0 Bundle (1994) (3.5-720k)`.
        1. And make sure that `HIMEM.SYS` and `EMM386.EXE` are loaded in `CONFIG.SYS`.
            1. Digitized sound on Wolf3D doesn't work without it.
        1. Once that is all installed, save that one (so we don't need to reinstall it every time we run out of space), and have everything else be a copy of it. I lzipped it and put the archive copy in `~/workspace/retrocomputing/mister/dos_base.vhd.zip`,
            1. You can mount the partitions using `guestmount`, e.g.:

                    guestmount --add dos1.vhd --rw /mnt/vhd/ -m /dev/sda1

                1. You likely will need to be root, and likely will need to be root to work with the drive as well.

        1. To make a 1.44MB floppy image, do:

                    mkfs.msdos -C floppy.img 1440

             1. And then mount it with:

                        sudo mkdir /media/floppy1/
                        sudo mount -o loop floppy.img /media/floppy1

             1. Copy files as normal, then unmount it when done.
    1. For FreeDOS
        1. Create an empty image with `dd if=/dev/zero of=freedos.vhd bs=1M count=140288`
        1. Boot the `FD12CD.iso`.
        1. Exit to DOS and partition it as one huge drive.
            1. It complains that Windows will get pissy, but we don't care for this purpose.
        1. Do a full install.
        1. Mount `ao486_driver_floppy.img` and copy over everything from that (DOS32A and all the AO486 driver stuff)
    1. General tweaks:
        1. **Memory**:
            1. To make the `misterfs` shared folder work, the memory region CE00-CFFF needs to be reserved. To do this on EMM386 / JEMMEX / JEMM386, specify:

                    X=CE00-CFFF

                On their command line.
            1. Suggested EMM386 command line (for DOS) (derived through experimentation):
            1. Suggested JEMMEMM386 command line (for FreeDOS) (derived through experimentation):
            1. Ref: https://misterfpga.org/viewtopic.php?t=1247

1. Using a USB hard drive.
    1. Do the above, but put it goes in the `games` subdir of the USB HDD.
    1. The easiest way to do this is to let the update script set up the `games` folder on the SD card and then copy the hierarchy over.
    1. ext4 works, BTW.
        1. Make sure to `sudo chmod -R a+rwx *` the whole directory structure - permissions are pretty loose on this setup.

# ScummVM

This setup is a little bit different, in that running it gives you a user interface and then you add games to that, pointing it at directories. As such, you can either put them on the SD card (curent setup creates a `/media/fat/ScummVM/GAMES`) directory or, if using an external drive, for example, put them wherever you like. To this end, I made `/media/usb0/scummvm` and put all my games there, then added them via the menu.

# TODO - 20210726

## General

1. Copy over the 2020 TOSEC archive and update the TOSEC section accordingly.
    1. Make sure to unzip the files on move this time, so I don't need to drop to a prompt and do it later.
1. Fix the resolution issues on systems listed above.

## Controllers

Figure out controller mappings for the following:

1. Atari 2600
1. Atari 5200
1. Atari 7800
1. GBA
1. Intellivision

In most of the case, there are a pile of buttons - more than many modern controllers (by my recollection, Intellivision had a D pad, 4 side buttons, and a 12 character keypad.. so 16 buttons and a pad?), though some of these look to be related to the core (open save states, turbo, etc.) and should probably be mapped to keyboard buttons.

## MacPlus

1. Install OS 7.5.3 on to a bare drive.
1. Upgrade to 7.5.5
1. Copy over games, etc. on to this image.
1. Note that this core supports multiple configs, so I can have this setup and still easily run others from HTGDB and so forth.

## Amiga

1. Figure out how to work this better. I got the HTGDB image set up and working, but there's so much more here that I don't understand because I don't know the Amiga at all.

## Commodore, Spectrum and other similar machines

1. Back in the day, when computers came with a basic interpreter in ROM, this was your basic (see what I did there?) shell. But, it's been 32+ years since I used one, and I never owned one - I would use them over friends' houses.
