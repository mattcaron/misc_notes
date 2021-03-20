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
1. Mappings for stuff from Archive.org:

    1. `everdrivepack`
        1. **Notes:**
            1. Filenames prepended with @ are MiSTer ready - apparently, MiSTer can unzip zip files and just read them, which is good to know, and makes updates very convenient (just move the zip, don't move and rsync). In that case, rather than unzipping things, I've just copied the whole zip file. 7z files were unzipped.
        1. `@Atari 2600 2020-04-30.zip` -> `ATARI2600`
        1. `Atari 5200 - Atarimax v1.0.7z` -> `ATARI5200`
        1. `Colecovision - Atarimax 2019-11-30.7z` -> `Coleco`
        1. `Darksoft Neo Geo 2020-05-12.7z` -> `NEOGEO`
        1. `@MiSTer Pack Add-on - NEOGEO 2020-05-12.zip` -> `NEOGEO`
            1. **This is case specific** and was created wrong by the update script, but it was FAT, so it worked. Moving to to ext4 broke it. I had to rename it. It's fine now.
            1. This also needs a ROMset. I copied over everything in the `misc/NeoGeo` subdir to `NEOGEO`. There are extras, but who cares.
        1. `@NES - EverDrive N8 2020-06-03.zip` -> `NES`
        1. `@NES - EverDrive N8 Game Series Collections Add-On 2020-04-21.zip` -> `NES`
        1. `@MiSTer Pack Add-on - NES 2020-04-15.zip` -> `NES`
        1. `@Game Boy - EverDrive GB 2020-06-21.zip` -> `GAMEBOY`
            1. This includes Gameboy color.
        1. `@Game Boy - EverDrive GB Game Series Collections Add-On 2020-04-24.zip` -> `GAMEBOY`
        1. `@GBA - EverDrive GBA 2020-04-22.zip` -> `GBA`
        1. `@GBA - EverDrive GBA Game Series Collections Add-On 2020-04-22.zip` -> `GBA`
        1. `@Game Gear - EverDrive GG 2020-01-12.zip` -> `SMS`
            1. This is not a mistake - the MiSTer SMS game gear core does both.
        1. `@Master System - Master EverDrive 2020-06-03.zip` -> `SMS`
            1. This is Sega's 8 bit console which was repackaged as the Game Gear portable later.
        1. `MegaCD` -> `MegaCD`
            1. Zip is supported but not recommended. So:
                1. Copied over the whole directory.
                1. Did `unzip_mkdir *.zip` to unzip each into its own directory (they are bin/cue files, so this makes sense).
                1. Then removed all the zipfiles.
                1. And then I did this for each subdir, except for `@Multi-Disc`, for which I used `unzip_mkdir` so all the disks are organized by folder.
            1. And this needs a ROM. Fortunately, the update_all script will download it for you.
        1. `@Genesis - MegaSD - Mega EverDrive 2020-06-04.zip` -> `Genesis`
        1. `@Genesis - MegaSD - Mega EverDrive Game Series Collections 2020-05-03.zip` -> `Genesis`
        1. `@SNES - SD2SNES - Super EverDrive 2020-06-22.zip` -> `SNES`
        1. `@SNES - SD2SNES - Super EverDrive Game Series Collections 2020-04-30.zip` -> `SNES`
        1. `@MiSTer Pack Add-on - SNES 2020-04-15.7z` -> `SNES`
            1. I un7zipped this, then rezipped it as a .zip and copied that over.
        1. `@TurboGrafx - PC Engine - Turbo EverDrive 2020-06-06.zip` -> `TGFX16`
        1. `@Vectrex - Vextreme 2020-04-28.zip` -> `VECTREX`
        1. `@MiSTer Pack Add-on - Amiga Minimig MegaAGS 2020-06-06.7z` -> `Amiga/EverDrivePack`
            1. This was a .7z that I copied over, un7zipped, then deleted the non-7zip files.
            1. Subdir is to differentiate it from the other Amiga collections.
        1. `@MiSTer Pack Add-on - ao486 2020-06-27.7z` -> `AO486`
            1. This was a .7z that I copied over, un7zipped, then deleted the non-7zip files.
        1. `@MiSTer Pack Add-on - AtariST 2020-06-07.7z` -> `AtariST`
            1. This was a .7z that I copied over, un7zipped, then deleted the non-7zip files.
        1. `@MiSTer Pack Add-on - C64 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - C64 Demos 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - MSX 2020-05-17.7z` -> `MSX`
            1. This was a .7z that I copied over, un7zipped, then deleted the non-7zip files.
        1. `@MiSTer Pack Add-on - Spectrum 2020-04-15.zip` -> `Spectrum`
        1. `@MiSTer Pack Add-on - TSConf 2020-04-15.7z` -> `Spectrum`
    1. `gaplus-for-nes` -> Put in `NES`
    1. `pac-man-championship-edition-nes-demake` -> `NES`
    1. `TOSEC_V2017-04-23` (this has many things):
        1. **Note**: I wrote this before I realized that I didn't need to unzip things. But, I haven't updated it with newer versions of anything, and I don't need the disk space, so I'm leaving it for now. Newer things added to this list will remain zipped, because I'm lazy and it works.
        1. `Apple/1`-> `Apple-I`
            1. And then I had to unzip everything in each directory. They're disk images, so I made directories for each.
        1. `Apple/II` -> `Apple-II`
            1. And then I had to unzip everything in each directory. They're disk images, organized by format, with one image per zip file, so I unzipped them all in to the given format directory.
            1. The theory is that the core may not be able to read all disk formats, so I may delete the ones it doesn't read (or, at least, stay away from them). Or, if it reads all of them, I'll just combine them by main category.
        1. `Amstrad/CPC` -> `Amstrad`
            1. And then I had to unzip everything in each directory. They're disk images, organized by format, with one image per zip file, so I unzipped them all in to the given format directory.
            1. Theory is the same as above.
        1. `MITS/Altair 8800` -> `Altair8800`
            1. And then I had to unzip everything in each directory. They're disk images, organized by format, with one image per zip file, so I unzipped them all in to the given format directory.
            1. Theory is the same as above.
    1. `Never_Ending_Amiga_Collection_2019-11` -> `games/Amiga/Never_Ending_Amiga_Collection_2019-11/.`
        1. This is a single zip file containing many subdirs of what look to be disk dumps from 5 people, plus some random files. I left them alone because there may be dupes and it just needs to be gone through.
        1. And then there's the add-ons from the MiSTer above, so this whole thing is a pile of discovery and spelunking, since I know nothing about the Amiga at all.

1. Mame Mappings
    1. Put the MAME ROMS `games/mame`
    1. Put the HBMAME ROMS in `games/hbmame`
    1. **Don't unzip the ROM files**
    1. The download I got required some cleanup - there are a pile of multipart zip files which needed to be combined and uncompressed.
        1. I didn't copy over any of the other directories (yet).

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