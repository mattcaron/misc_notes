These are instructions for install Dosbian 1.5 on to a hard drive suitable for booting a Raspberry Pi 4. It may work for other applications, though these have not been tested.

1. Ensure your RPi is up to date with the beta firmware (modern RPis may not have this issue as they may come with the release firmware).
    1. You only need to do this once.
    1. Boot any bootable RPi OS image (this can be Rasbian, Raspberry Pi OS, RetroPie, Dosbian, etc.) from SD card.
        1. Note: A bootable SD card can be made by following the instructions for the hard drive, below, and writing the SD card instead.

    1. Do any configuration required so networking anmd keyboard and all that works.
    1. Do the update:

            sudo apt update
            sudo apt dist-upgrade

    1. Edit `/etc/default/rpi-eeprom-update` and change `FIRMWARE_RELEASE_STATUS` to be `beta`.
    1. Install the beta firmware:

            sudo rpi-eeprom-update -d -f /lib/firmware/raspberrypi/bootloader/beta/pieeprom-2020-06-15.bin

        1. The reason here is that we need to upgrade the firmware on the board as USB booting is a function of the onboard firmware, not the operating system.
    1. **Reboot back to the SD card.** I cannot stress this enough. I chased this for half an hour. When it says "update pending, reboot to apply", it doesn't mean "reboot for it to take effect". It needs to actually be rebooted to flash the firmware.

1. Make the bootable USB Drive
    1. Copy the image to the drive:

             sudo ddrescue -f Dosbian1.5.img /dev/sdX

    1. Take the SD card you used to update the firmware, above, and copy the contents of the `/boot`/ partition over those on the hard drive - they've been updated and have the new binaries used by the bootloader to boot the USB device.
        1. **Note** This will likely be obsolete with the next build of Dosbian.

1. Copy over the Argon1 case fan control script so we can run it later:

        cp ~/workspace/retrocomputing/argon1.sh /media/matt/rootfs/home/pi/.

1. Boot up Dosbian and go through the config menus and set it up the way you want, including the appropriate rpi-config stuff.
    1. **Make sure to change the pi user's password.**
    1. Probably want to expand the filesystem too.

1. Exit to the prompt and run the `./argon1.sh` script to support the power and fan control.
    1. Once installed, it can be configured with `argonone-control`.

1. And once that's all done, pull the drive and load it full of stuff.
