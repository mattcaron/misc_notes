This is a synthesis of the docs and the `MiSTer-sd-installer-linux.sh` script from `https://github.com/michaelshmitty/SD-Installer-macos_MiSTer`.

1. Get the latest installer .rar file from https://github.com/MiSTer-devel/SD-Installer-Win64_MiSTer

1. Get the latest core release from https://github.com/MiSTer-devel/Main_MiSTer/tree/master/releases

1. Get the latest menu file from https://github.com/MiSTer-devel/Menu_MiSTer/tree/master/releases

1. Make an appropriately named director.

1.  `unrar x` the file into that directory.

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

1. Unmount and eject it, put it in the MiSTer, hook it up, and boot it.

1. Once booted:
    1. Press F9 to get to linux.

    1. Get the wallpapers:

            cd /meda/fat/Scripts
            ./Update_MiSTerWallpapers.sh

    1. Press F12 to get back to the main menu and then select update to run a full update.

    1. Press F1 to load a wallpaper.

    1. Useful scripts to run (these are in `/media/fat/Scripts` after update);
        1. `./fast_USB_polling_on.sh`
        1. `./firewall_on.sh`
        1. `./ftp_off.sh`
        1. `./samba_off.sh`
        1. `./security_fixes.sh` <- this one is especially important.
        1. `./soundfont_install.sh`

1. Other access:
    1. Default User: `root`, pass `1`
    1. Console ([ref](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Console-connection)) is the port next to the ethernet jack. It's 115200 8N1.
    1. Network: ([ref](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Network-access)]

1. Joysticks / gamepads /etc

These need to be set up.

    1. Plug one in.
    1. Press F12 twice to get to the System Settings.
    1. Choose "define joystick buttons"
    1. Follow instructions.

1. Core config

When a core is loaded, press F12. The core setup is there. Press left or right to flip between menus.

Config notes follow. Note that I was aiming for nostalgia - what I remember it looking like when I played that system.

**Make sure to save these when you change them.**

    1. Genesis:
        1. Genesis:
            1. Region: US
            1. 320x224 Aspect: Corrected
            1. 
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
        


1. Roms
    1. [Filesystem reference](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Folders-and-File-naming)
    1. Software for most things goes in the `games` subdir. It's organized by platform. Put your roms in the right subdir for your platform.
    1. Note that I only installed base packs. I figure, once I go through that, I can install the extras/specials/etc.

    1. Everdrive mappings (from 9-5-2018 EverDrive pack from SmokeMonster)
        1. `Atari 2600` -> `ATARI2600`
        1. `Atari 5200` -> `ATARI5200`
        1. `ColecoVision Atarimax` -> `Coleco`
        1. `Darksoft Neo Geo` -> `NeoGeo`
        1. `Everdrive N8` -> `NES`
        1. `EverDrive GB` -> `GAMEBOY`
            1. This includes Gameboy color.
        1. `EverDrive GBA` -> `GBA`
        1. `EverDrive GG` -> `SMS/GG`
            1. This is not a mistake - the MiSTer SMS game gear core does both.
            1. To differentiate, I put them in subdirs.
            1. And then, [this list](https://www.smspower.org/Tags/SMS-GG) has things which need to be renamed to work (but I didn't rename any - I figure I'll just note it and see if it works anyway).
        1. `Master Everdrive` -> `SMS/SMS`
            1. This is Sega's 8 bit console which was repackaged as the Game Gear portable later.
            1. I put it in a subdir (see below)
        1. `Mega EverDrive` -> `Genesis`
        1. `Super EverDrive & SD2SNES` -> `SNES`            
        1. `Turbo EverDrive` -> `TGFX16`
        1. `Vectrex` -> `VECTREX`

