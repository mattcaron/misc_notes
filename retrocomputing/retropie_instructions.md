# Basic install

1. Run `rpi-imager` and image the drive / SD card with the latest Retropie image for the given RPi hardware.

1. When it boots up, drops you at a command prompt (at least, it did for me)

1. `update` and `dist-upgrade` as normal

1. Reboot

1. Run `sudo ./Retropie-Setup/retropie_setup.sh`
   1. Do NOT do the `Basic Install` - we are using a stripped down version
      because we have a MiSTer.
   1. Select "Manage packages -> core -> Install all core packages" and let it
      run.
   1. Once that is done, install the following emulators. Note that you'll have
      to poke around and find which menu:

      |System|Emulator|ROM Location|Supported Extensions|BIOS|Notes|Link|
      |------|--------|------------|--------------------|----|-----|----|
      |3DO   |`lr-opera`|`roms/3do`  | `.iso, .bin/.cue, .chd, .zip`|`panafz10.bin`| |https://retropie.org.uk/docs/3do/|
      |Saturn|`lr-beetle-saturn`|`roms/saturn`|`.cue,.bin,.iso, .mdf`|`sega_101.bin, mpr-17933.bin`| |https://retropie.org.uk/docs/Saturn/|
      |PSP   |`ppsspp`|`roms/psp`|`.cso, .iso, .pbp`|none | |https://retropie.org.uk/docs/PSP/|
      |N64|`Mupen64Plus`|`roms/n64`|`.z64, .n64, .v64, .zip`|none|has many scaling/config options for higher resolutions|https://retropie.org.uk/docs/Nintendo-64/|
      |Game and Watch|`lr-gw`|`roms/gameandwatch`|`.mgw`|none||https://retropie.org.uk/docs/Game-%26-Watch/|
      |Dreamcast|`lr-flycast`|`roms/dreamcast`|`.cdi, .chd, .gdi, .zip`|`dc_boot.bin, dc_flash.bin`||https://retropie.org.uk/docs/Dreamcast/|

      **Notes:**
      1. All BIOS goes in Retropie/BIOS
   