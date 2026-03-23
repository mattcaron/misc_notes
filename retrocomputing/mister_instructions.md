# MiSTer install instructions

## Basic install

### Notes

* Use Mr. Fusion from: <https://github.com/MiSTer-devel/mr-fusion>

* I installed it on to a 16 GB SanDisk Industrial MicroSD card.

### Procedure

1. Download the latest release `.img` file.
   * Note - I saved the version I used it in `~/workspace/retrocomputing/mister`.
2. Unzip it.
3. Image the SD card:

       sudo ddrescue -f mr-fusion.img /dev/sdX

   Where `sdX` is the raw SD card device. `-f` is because it exists, so we need the force flag to make it happy.
4. Make sure that the external SSD (if using) is disconnected from the MiSTer.
   * I have no reason to think that this would do something like blank the SSD, I'm just paranoid.
5. You can also pre-set up the WiFi stuff by dropping it in the root of the SD card and the installer will copy it to the correct place. Since I always just plug it in to wired Ethernet, I didn't bother setting up WiFi.
6. Plug it in to the MiSTer and boot it. It automagically loads the OS and then reboots.
7. Once rebooted, press F9 to drop to the prompt and login. The default login is user `root` with password `1`.
8. Change the root password as normal using `passwd`.
9. Power off, plug in the external drive, then power it back on.
10. Hit F9, drop to the prompt, login, then do:

        cd /media/fat/Scripts
        ./update.sh

    And let it run updates. It will reboot automatically.

11. Once rebooted, `ssh` is now on by default, so `ssh` in with the credentials you set above, and continue setup.

        cd /media/fat/Scripts
        ./timezone.sh
        ./fast_USB_polling_on.sh

    And then it will reboot again.

12. Log in again and...

    1. Install the `update_all` script ([GitHub](https://github.com/theypsilon/Update_All_MiSTer)):

           cd /media/fat/Scripts
           wget https://github.com/theypsilon/Update_All_MiSTer/releases/latest/download/update_all.zip
           unzip update_all.zip
           rm update_all.zip
           ./update_all.sh

        Let it run once to do the default download and setup. Once it's self-updated and everything is all set up, we'll configure additional things (wallpapers, etc).

        Then, run `./update_all.sh` and press `arrow up` to get into the config screen and change the following:
          * `Other Cores` ->
              * `Arcade Offset` -> `On`
              * `agg23's MiSTer Cores` -> `On` (for Game N Watch)
              * `Dual RAM Console Cores` -> `On` (I have a dual RAM setup).
          * `Tools & Scripts` ->
              * `Arcade Organizer` -> `On`
                * It pops you into a sub menu. Leave the defaults and hit `Back`.
              * `Names TXT` -> `On`
                * It pops you into a sub menu. Set:
                  * `Names TXT` -> `Yes`
                  * `Arcade Names TXT` -> `Yes`
                  * `Region` -> `US`
                * Then hit `Back`
          * `Extra Content` ->
              * `BIOS Database` -> `On`
              * `Arcade ROMs Database` -> `On`
                  * This pops you into a sub menu. Hit `Yes` for everything.
              * `Ranny Snice Wallpapers` -> `On`
                  * `Wallpapers Enabled` -> `Yes`
              * `Uberyoji Boot ROMs` -> `On`
              * `Dinierto GBA Borders` -> `On`

        Once the above is all configured, choose `SAVE`, and then `EXIT and RUN UPDATE ALL`. It will get everything and then reboot again. Make sure to log in before continuing...

    1. Install the Sinden Lightgun cores:

           cd /media/fat/Scripts
           wget https://raw.githubusercontent.com/MrLightgun/MiSTerSindenDriver/main/Install_SindenLightgunDriver.sh
           ./Install_SindenLightgunDriver.sh

       And then it will reboot.

    1. Install ScummVM ([GitHub](https://github.com/bbond007/MiSTer_ScummVM)):

           cd /media/fat/Scripts
           wget https://raw.githubusercontent.com/bbond007/MiSTer_ScummVM/refs/heads/master/Install_ScummVM.sh
           ./Install_ScummVM.sh

## Configuration (INI files)

Log in and do:

    cd /media/fat
    cp MiSTer_example.ini MiSTer.ini
    vi MiSTer.ini

Read through it and edit it for correctness. Most notably is screen resolution. My deviations from the example are noted below:

    vga_scaler=1      ; scale VGA
    vscale_mode=1     ; for integer scaling
    osd_timeout=0     ; always display menu
    reset_combo=2     ; ctrl + alt + del to reboot
    video_mode=8      ; 1920 x 1080 @ 60Hz video
    vsync_adjust=2    ; Low latency video
    video_mode_ntsc=8 ; 1920 x 1080 @ 60Hz video
    video_mode_pal=9  ; 1920 x 1080 @ 50Hz video

Save and quit.

And then copy the above and make a different one for ScummVM.

    cp MiSTer.ini MiSTer_ScummVM.ini
    vi MiSTer_ScummVM.ini

And change the following:

    video_mode=6      ; 640 x 480 @ 60Hz video

Note that Multiple versions can be switched between, see [here](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Configuration-Files#Switching-INI-Files-On-the-Fly).

## Configuration (Cores and Inputs)

### Config location

The configuration is stored in `/media/fat/config`, and if you do something (like, say, reload the system from scratch), you can copy it over to save everything.

### Sinden Lightgun

In order to use the Sinden light gun, you need to start the driver first. Use the keyboard or gamepad to open the menu, navigate to the Scripts dir, and select one of the `SindenLightgunStart_*.sh` scripts to load the driver. Then it should work as normal. Note that `SindenLightgunStart_Default.sh` is recommended.

Once it's set up, you need to make sure to use a core that supports the light gun. It should have something like "Sinden" or "Lightgun" in the name and add a border around the edge of the screen.

See [The README](https://github.com/MrLightgun/MiSTerSindenDriver/blob/main/README.md) for more information.

### Joysticks / gamepads /etc

These need to be set up for the core system first

1. Plug one in.
1. Press F12 twice to get to the System Settings.
1. Choose "define joystick buttons"
1. Follow instructions.

### Cores

When a core is loaded, press F12. The core setup is there. Press left or right to flip between menus.

Set it however you like. I generally aimed for nostalgia, setting it up how I remember it being.

## Updates

Log in, then do:

    cd /media/fat/Scripts
    ./update_all.sh
    ./Install_SindenLightgunDriver.sh
    ./Install_ScummVM.sh

## Roms

1. [Filesystem reference](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Folders-and-File-naming)
1. Software for most things goes in the `games` subdir. It's organized by platform. Put your roms in the right subdir for your platform.
1. The directory names (filesystem case) are not always correct if using an ext4 formatted drive, as I am. It will also change over time.
1. The [MiSTer FPGA Documentation](https://mister-devel.github.io/MkDocs_MiSTer/) seems to have a reasonably up to date list of cores and their corresponding directories.

**MiSTer copy TODO:**

* @MegaCD CHD 1G1R for MiSTer
* @TGFX16-CD CHD 1G1R for MiSTer

1. Mappings for stuff from Archive.org.
    1. `htgdb-gamepacks`
        * **Notes:**
            1. Filenames prepended with @ are MiSTer ready - apparently, MiSTer can unzip zip files and just read them, which is good to know, and makes updates very convenient (just move the zip, don't move and rsync). In that case, rather than unzipping things, I've just copied the whole zip file. 7z files were put into the stated directory, then un7zipped.
            1. Anything not listed was ignored.
        1. `@Atari 2600 2021-04-06.zip` -> `ATARI2600`
            1. I also made a symlink: `ln -s ATARI2600 Atari2600`. I am not sure why, but it fixed something (that may no longer be broken).
        1. `Atari 5200 2021-03-20.7z` -> `ATARI5200`
        1. `@Atari 7800 2021-04-26.zip` -> `ATARI7800`
        1. `@Atari Lynx 2021-03-17.7z` -> `AtariLynx`
        1. `@Channel F 2022-09-06.zip` -> `ChannelF`
        1. `@Colecovision 2023-05-11.zip` -> `Coleco`
            1. Also supports SG-1000.
            1. SG-1000 games are in the `SG1000` directory.
        1. `@Famicom Disk System 2022-05-16.zip` -> `NES`
        1. `@Game Boy Color SMDB 2022-05-12.zip` -> `GAMEBOY`
        1. `@Game Boy - EverDrive GB 2020-12-22.zip` -> `GAMEBOY`
        1. `@Game Boy SMDB 2022-05-20.zip` -> `GAMEBOY`
        1. `@Game Gear - EverDrive GG 2020-01-12.zip` -> `SMS`
            1. This is not a mistake - the MiSTer SMS core does Master System, Game Gear, and SG-1000.
            1. SG-1000 games are in the `SG1000` directory.
        1. `@GBA - EverDrive GBA 2022-08-08.zip` -> `GBA`
        1. `@GBA - EverDrive GBA Game Series Collections Add-On 2022-08-08.zip` -> `GBA`
        1. `@Genesis - MegaSD Mega EverDrive 2024-01-03.zip` -> `MegaDrive`
        1. `@Genesis - MegaSD Mega EverDrive Game Series Collections 2024-01-03.zip` -> `MegaDrive`
        1. `@Master System - Master EverDrive 2022-05-04.zip` -> `SMS`
            1. This is Sega's 8 bit console which was repackaged as the Game Gear portable later.
        1. `MegaCD` -> Special note - did nothing with this as it is superseded by `@MegaCD CHD 1G1R for MiSTer`.
        1. `@MegaCD CHD 1G1R for MiSTer` -> `MegaCD`
        1. `@MiSTer Pack Add-on - Acorn Archimedes 2020-09-30.7z` -> `ARCHIE`
        1. `@MiSTer Pack Add-on - Amiga Minimig MegaAGS 2022-03-03.7z` -> `Amiga/htgdb`
            1. In a subdir because I want to know where these came from if I get images from other places.
        1. `@MiSTer Pack Add-on - AtariST 2020-06-07.7z` -> `AtariST`
        1. `@MiSTer Pack Add-on - C64 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - C64 Demos 2020-04-15.zip` -> `C64`
        1. `@MiSTer Pack Add-on - MSX 2022-05-26.7z` -> `MSX`
            1. There was a hard disk image in the `MSX` subdir so I just moved it to the root `MSX` dir so I didn't end up with `MSX/MSX`, because that would be dumb.
        1. `@MiSTer Pack Add-on - NEC PC8801 2022-01-08.zip` -> `PC8801`
        1. `@MiSTer Pack Add-on - NEC PC8801 2022-01-08.zip` -> `NEOGEO`
        1. `@MiSTer Pack Add-on - SNES 2020-04-15.zip` -> `SNES`
        1. `@MiSTer Pack Add-on - Spectrum 2020-04-15.zip` -> `Spectrum`
        1. `@MiSTer Pack Add-on - TSConf 2020-04-15.7z` -> `TSConf`
        1. `N64 - EverDrive 64 2023-12-08.7z` -> `N64`
        1. `N64 - EverDrive 64 Game Series Collections Add-On 2023-05-15.7z` -> `N64`
        1. `@NES2.0 2022-09-15.zip` -> `NES`
        1. `@NES - EverDrive N8 2021-03-23.zip` -> Ignore. Superceded by `@NES2.0 2022-09-15.zip`.
        1. `@NES - EverDrive N8 Game Series Collections Add-On 2020-09-17.zip` -> Ignore. Superceded by `@NES2.0 2022-09-15.zip`.
        1. `NSF Music 2020-12-17.7z` -> `NES`
            1. This is a music player for NES music.
        1. `PC Engine CD Redump Supplement` -> This is redundant with `@TGFX16-CD CHD 1G1R for MiSTer`
        1. `PlayStation Redump Supplement` -> This is redundant with the separate Playstation (PSX) instructions below.
        1. `Project Peacock` -> This is redundant with `@TGFX16-CD CHD 1G1R for MiSTer`
            1. This is "Every Shoot ’em Up for the PC Engine Platform (CD, PCE/TG16, SGX)"
            1. See <https://www.retrorgb.com/project-peacock-2-0-every-shoot-em-up-for-the-pc-engine-platform-cd-pce-tg16-sgx.html>
        1. `Saturn Redump Supplement` -> This is redundant with the Saturn instructions, below.
        1. `@Sega 32X - 2024-01-04.zip` -> `S32X`
        1. `@Sega SG-1000 2022-05-20.zip` -> `SG1000`
        1. `@SNES - SD2SNES - Super EverDrive 2023-12-12.zip` -> `SNES`
        1. `@SNES - SD2SNES - Super EverDrive Game Series Collections 2023-12-12.zip` -> `SNES`
        1. `@SPC Music 2023-12-26.zip` -> `SNES`
            1. This is a collection of SNES music that the core can play.
        1. `@TGFX16-CD CHD 1G1R for MiSTer` -> `TGFX16-CD`
            1. You also need to run the script `create_arcade_card_symlinks.sh` **while in the MiSTer** to create the correct symlinks.
            1. **Important**. It assumes the dir is `/media/fat/games/TGFX16-CD`. Change this if using an external drive.
        1. `@TurboGrafx - PC Engine - Turbo EverDrive 2023-12-13.zip` -> `TGFX16`
        1. `@Vectrex - Vextreme 2020-12-28.zip` -> `VECTREX`
        1. `@Watara Supervision 2022-05-20.zip` -> `SuperVision`
        1. `@WonderSwan 2023-11-14.zip` -> `WonderSwan`
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
    1. `18-game-watch-games-for-mister-fpga-20220610` -> Unzipped into `GameNWatch`
        1. This is the older Game and Watch core. It uses `.bin` files.
    1. `fpga-gnw-opt` -> `games/Game\ and\ Watch`
        1. This is the newer Game and Watch core. It uses `.gnw` files and replicates the whole handheld. It also supports a bunch of Tiger Electronics games.
    1. `sony-playstation-usa-translations-1g1r-chd-perfect-collection_202310` -> `PSX`

## Mame

These are now handled automatically by the `update_all` script.

## ScummVM

This setup is a little bit different, in that running it gives you a user interface and then you add games to that, pointing it at directories. As such, you can either put them on the SD card (current setup creates a `/media/fat/ScummVM/GAMES`) directory or, if using an external drive, for example, put them wherever you like. To this end, I made `/media/usb0/scummvm` and put all my games there, then told ScummVM where to find them.

## Output issues

The following cores have issues when outputting to a US (NTSC) TV. Fix them by hooking them to a real monitor and setting the video output correctly. Note that this is not exhaustive, because I know I fixed some already:

* Archie
* BK001M
* Galaksija
* MC10
* TSConf
* Game of Life

## AO486 core notes

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
        1. Ref: <https://misterfpga.org/viewtopic.php?t=1247>

## Notes on using a USB hard drive

    1. Do the above, but put it goes in the `games` subdir of the USB HDD.
    1. The easiest way to do this is to let the update script set up the `games` folder on the SD card and then copy the hierarchy over.
    1. ext4 works, BTW.
        1. Make sure to `sudo chmod -R a+rwx *` the whole directory structure - permissions are pretty loose on this setup.
    1. Case specifity will cause issues. Make sure to set the directory's case correctly. You may also need symlinks all pointing to the same spot.
