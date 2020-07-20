rThese are instructions for install Dosbian 1.5 on to a hard drive suitable for booting a Raspberry Pi 4. It may work for other applications, though these have not been tested.

# Initial setup

1. Ensure your RPi is up to date with the beta firmware (modern RPis may not have this issue as they may come with the release firmware).
    1. You only need to do this once.
    1. Boot Dosbian from SD card.
        1. Note: A bootable SD card can be made by following the instructions for the hard drive, below, and writing the SD card instead.

    1. Do any configuration required so networking anmd keyboard and all that works.
    1. Drop to console and do the update:

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
        1. You can also just `ddrescue` over the whole SD card to the hard drive, if you like.

1. **Note: This only applies if you have an Argon1 case like I do.** Copy over the Argon1 case fan control script so we can run it later:

        cp ~/workspace/retrocomputing/argon1.sh /media/matt/rootfs/home/pi/.

1. Boot up Dosbian and go through the config menus and set it up the way you want, including the appropriate rpi-config stuff.
    1. **Make sure to change the pi user's password.**
    1. Probably want to expand the filesystem too.
    1. And turn on SSH.
    1. And once SSH is on, ssh in to it, copy your key into `authorized_keys` and then edit the SSH config do disable password access.

1. **Note: This only applies if you have an Argon1 case like I do.** Exit to the prompt and run the `./argon1.sh` script to support the power and fan control.
    1. Once installed, it can be configured with `argonone-control`.

# Installing stuff

Once the above is all done, pull the drive and load it full of stuff.

You could just SCP it over, but plugging it in is almost certainly faster.

Everything in this section assumes you're in `rootfs/home/pi/dosbian` unless otherwise specified. 

By default `pi` is UID 1000, which maps quite nicely to my UID. But, failing that, you may need to `sudo` and `chown` copied files as appropriate. `sudo -s` to whomever is UID 1000 on your box would work too.

1. Fix the perms - why is that world writeable? And why is some of it owned by root?

            cd rootfs/home/pi
            sudo chown -R matt:matt dosbian
            chmod -R o-w dosbian

1. Make a `my_cds` dir to go along with `my_floppies` and `my_hdd`.

            mkdir my_cds

    1. And then copy all the stuff from `content/dos/cd_images` into it.

1. Copy `content/dos/drive_c/games/*` to `dosbian/games/.`.
1. Copy `content/dos/drive_c/programs/*` to `dosbian/programs/.`.
1. Make `dosbian/bin`.
1. Copy `content/dos/drive_c/bin/*` to `dosbian/bin/.`.



