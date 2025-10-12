# Stair controller instructions

## Background

This is a Raspberry Pi 3 model B hooked to a relay board which turns on / off a
contactor which then turns on / off the heating coil. The GPIO drives the relay
which switches 110V which controls the contactor which switches 220V.

The whole thing is controlled via NodeRED.

## Instructions

### Base install and upgrades

Initialize the MicroSD card with RPi-imager and install **Raspberry Pi OS Lite
(32-bit)**. This is minimal and has no desktop OS, which is what we need.

Once installed, login with default creds (`pi` / `raspberry`) apply updates.

    sudo apt update
    sudo apt dist-upgrade
    sudo shutdown -r now

### System setup

1. Make a normal user account

1. Set the `pi` account to a random password, then lock it. In this way,
   everything that assumes it is there should work, but no one can log into it
   interactively.

1. Run `sudo raspi-config` and:

    1. Set the hostname.
    1. Enable SSH.
       1. Disable all other interface options.
    1. Set the locale, timezone, keyboard, and WiFi country appropriately.
    1. Expand the filesystem.
    1. Reboot.

1. Copy over your user's SSH authorized keys.

1. Edit `/etc/ssh/sshd_config` and:

   1. Set `PermitRootLogin` to `no`.
   1. Set `PasswordAuthentication` to `no`.
   1. Then restart ssh:

          sudo service ssh restart

1. Set up NodeRED / Apache / etc.

    1. Install necessary dependencies:

           sudo apt install nodered apache2 libapache2-mod-authnz-external

   1. Generate a PEM cert/key pair via your favorite method and put them in a
      useful place. The config below assumes they will be in `/etc/ssl/private`
      and be called `apache.pem` and `apache.key`.
