# Instructions for installing XUbuntu 24.04

Note that this was the result of an upgrade of 20.04 to 22.04 and then
to 24.04 - these may not be completely accurate for a clean install,
as that has not been vetted.

## Base Install - RAID

As the minimal CD is no more, and the installer doesn't do everything we need,
we'll need to boot a live image, do some console stuff, then do the install. So,
without further ado....

Refs: <https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019>

1. Boot the desktop LiveCD

1. Choose "Try and Install Xubuntu"

1. Once it boots, choose language and "Try Xubuntu".

1. Once you get a desktop, open a terminal and start setting things up.

   You need to become root (or enter `sudo` way too many times):

   1. Partitioning

          sudo -i

      For the purposes of the following, we'll assume that disk 1 is
   `/dev/nvme0n1` and disk 2 is `/dev/nvme1n1`. Adjust as appropriate for your
   system. We start with exports to save some typing.

          export DEV1="/dev/nvme0n1"
          export DEV2="/dev/nvme1n1"

      And, stealing from the clever trick in the reference, account for the NVME
      drives having a "p" for the partition.

          export DEV1P="${DEV1}$( if [[ "$DEV1" =~ "nvme" ]]; then echo "p"; fi )"
          export DEV2P="${DEV2}$( if [[ "$DEV2" =~ "nvme" ]]; then echo "p"; fi )"

      Delete all the partitions on both drives:

          sgdisk --zap-all $DEV1
          sgdisk --zap-all $DEV2

      You probably want to reboot at this time, because the installer tries to
      be helpful by doing things like activating swap.. which means you need to
      deactivate everything it activated in order to do the following steps.
      Rebooting makes this easier.

      After that, create some new ones, set their types and names correctly,
      and create a hybrid MBR.

          sgdisk --new=1:0:+1G $DEV1
          sgdisk --new=2:0:+2M $DEV1
          sgdisk --new=3:0:+1G $DEV1
          sgdisk --new=4:0:0 $DEV1
          sgdisk --typecode=1:FD00 --typecode=2:EF02 --typecode=3:EF00 --typecode=4:FD00 $DEV1
          sgdisk --change-name=1:"Encrypted boot RAID" --change-name=2:"BIOS boot partition" --change-name=3:"EFI system partition" --change-name=4:"Encrypted LVM RAID" $DEV1
          sgdisk --hybrid 1:2:3 $DEV1

      Print the table to check it.

          sgdisk --print $DEV1

      Assuming it's good, copy the partition info from the first drive to the
      second, so they match, making sure to create new GUIDs for the disk (so
      they're not just plain copies).

          sgdisk -R $DEV2 $DEV1
          sgdisk -G $DEV2

      And make sure the kernel has the new partition table in memory:

          partprobe

   1. RAID array creation

      First, install the mdadm tool

          sudo apt install mdadm

      Then create the RAID arrays:

          mdadm --create md0 --level=1 --raid-devices=2 ${DEV1P}1 ${DEV2P}1
          mdadm --create md1 --level=1 --raid-devices=2 ${DEV1P}4 ${DEV2P}4

   1. Set crypto for boot array.

      Note that, due to GRUB limitations, the older LUKS1 format is required for
      the boot partition. See [the explanation
      here](https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019#LUKS_Encrypt)
      for more information.

          cryptsetup luksFormat --type=luks1 /dev/md/md0

   1. And for the main array:

          cryptsetup luksFormat /dev/md/md1

   1. Then open both of them

          cryptsetup open /dev/md/md0 md0_crypt
          cryptsetup open /dev/md/md1 md1_crypt

   1. Again, because of installer limitations, it doesn't let you create a
      filesystem on the boot partition, so let's do that:

          mkfs.ext4 -L boot /dev/mapper/md0_crypt

      Alternatively, create a btrfs filesystem similarly:

          mkfs.btrfs -L boot /dev/mapper/md0_crypt

   1. Since we're formatting things, format the EFI partitions:

          mkfs.vfat -n EFI ${DEV1P}3
          mkfs.vfat -n EFI ${DEV2P}3

   1. Create the LVM stuff (again, installer limitations...)

          pvcreate /dev/mapper/md1_crypt
          vgcreate drives /dev/mapper/md1_crypt
          lvcreate --size 8G  --name swap drives
          lvcreate --size 25G --name tmp drives
          lvcreate --size 50G --name var drives
          lvcreate --size 200G --name root drives
          lvcreate --extents 100%FREE --name home drives

      Which corresponds to the following partitions and sizes (mountpoints are
      for reference and used later)

          LVM Partition Size  Mountpoint
          swap           8GB
          tmp           25GB  /tmp
          var           50GB  /var
          root          200GB /
          home          Rest  /home

      Note that a larger swap is necessary for machines where you want to
hibernate. If so, you need at least as much swap space as you have RAM, so do
that plus a bit. See [this article](https://help.ubuntu.com/community/SwapFaq)
for suggestions, but 64GB RAM gets 72GB swap. If you don't care about
hibernation, you can go as small as you like. I typically use 8GB for most
machines.

      **Note 1:** Over time, `/var` has gotten larger due to the proliferation
  of containers (docker, snap, etc.). If you do not plan to use these, it can be
  smaller.

      **Note 2:** For some machines, a common area of `/pub`, or `/shared`,
  might be appropriate, and should be taken out of `/home`.

   1. Once that is all done, minimize the terminal window (you'll want to leave
      it open for later) and start the installer by double clicking the icon on
      the desktop.

1. The installer

   Proceed through as normal, selecting sane choices until you get to the
   "Installation Type" screen, where you want to choose "Something else". It
   will detect all of the volumes already created and you can set mountpoints
   and filesystems as normal.

   Set the boot loader installation to be on the first hard drive (doesn't
   matter, it will fail anyway).

   Let the installer run and then it will fail to install grub. This is expected
   and is a result of some naming issues. Tell the installer to continue without
   installing a bootloader - we'll do so manually in the next step.

   The installer crashes (because, obviously, this is the correct behavior), but
   this is the last step of the install, so we're okay. Let it continue and
   crash, and then go on to the next step.

   (You may need to kill the installer with `killall ubiquity`)

1. Manual bootloader installation

   The core issue is that, the installer isn't set up for working with
   metadisks, so we need to set it up ourselves. But, we need to be in a chroot
   environment to do the `grub-install`, so, mount our root fs:

       mount /dev/mapper/drives-root /target

   If using btrfs, the above needs to be like:

       mount /dev/mapper/drives-root /target -o subvol=@

   Then do:

       for n in proc sys dev etc/resolv.conf; do mount --rbind /$n /target/$n; done
       chroot /target
       mount -a

   We also need to tell grub to use crypto disks:

       echo "GRUB_ENABLE_CRYPTODISK=y" > /etc/default/grub.d/local.cfg

   And, neither the mdadm nor the cryptsetup tools are installed in the chroot,
   and we need those for grub to be able to do useful things with the md arrays,
   and to be able to boot afterwards. So, install them.

       apt install mdadm cryptsetup-initramfs

   And now, finally, we can install grub:

       grub-install /dev/sda
       grub-install /dev/sdb

   But, we also need to tell linux to unlock our filesystems and rebuild the inittab:

       echo "md0_crypt UUID=$(blkid -s UUID -o value /dev/md0) none luks,discard" >> /etc/crypttab

       echo "md1_crypt UUID=$(blkid -s UUID -o value /dev/md1) none luks,discard" >> /etc/crypttab

       update-initramfs -u -k all

   Once this is all done, you can reboot into your newly created machine.

### Save typing with keyfiles (Optional)

(You can do this after you've booted into the new machine, but remember to set
`DEV1`, `DEV2`, `DEV1P`, and `DEV2P` first, as described at the beginning of this section.)

If you want to save some typing, you can create keyfiles which are built into
the initramfs and used to unlock the encrypted volumes. Note that they are
relatively safe because they are installed on an encrypted volume - but, if
someone were to compromise the running system, they could conceivably grab the
file then use it to decrypt the volume - your call.

 1. Configure it to build the keyfile into the initramfs:

        echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook

        echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

 1. Create the keyfile (a 512 byte random number), and add it as a key to the
    volume.

        mkdir /etc/luks
        dd if=/dev/urandom of=/etc/luks/boot.keyfile bs=512 count=1
        chmod 0500 /etc/luks
        chmod 0400 /etc/luks/boot.keyfile
        cryptsetup luksAddKey /dev/md0 /etc/luks/boot.keyfile
        cryptsetup luksAddKey /dev/md1 /etc/luks/boot.keyfile

 1. Remove the existing `crypttab`, add the new lines which say to use the keys
    we just created, then rebuild the `initramfs`.

       rm /etc/crypttab

       echo "md0_crypt UUID=$(blkid -s UUID -o value /dev/md0) /etc/luks/boot.keyfile luks,discard" >> /etc/crypttab

       echo "md1_crypt UUID=$(blkid -s UUID -o value /dev/md1) /etc/luks/boot.keyfile luks,discard" >> /etc/crypttab

       update-initramfs -u -k all

 1. Reboot and you'll enter your password less.

## Base Install - Single Disk

As the minimal CD is no more, and the installer doesn't do everything we need,
we'll need to boot a live image, do some console stuff, then do the install. So,
without further ado....

Refs: <https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019>

1. Boot the desktop LiveCD

1. Choose "Try and Install Xubuntu"

1. Once it boots, choose language and "Try Xubuntu".

1. Once you get a desktop, open a terminal and start setting things up.

   You need to become root (or enter `sudo` way too many times):

   1. Partitioning

          sudo -i

      For the purposes of the following, we'll assume that the disk is
   `/dev/nvme0n1`. Adjust as appropriate for your system. We start with exports
   to save some typing.

          export DEV="/dev/nvme0n1"

      And, stealing from the clever trick in the reference, account for the NVME
      drives having a "p" for the partition.

          export DEVP="${DEV}$( if [[ "$DEV" =~ "nvme" ]]; then echo "p"; fi )"

      Delete all the partitions:

          sgdisk --zap-all $DEV

      You probably want to reboot at this time, because the installer tries to
      be helpful by doing things like activating swap.. which means you need to
      deactivate everything it activated in order to do the following steps.
      Rebooting makes this easier.

      After that, create some new ones, set their types and names correctly,
      and create a hybrid MBR.

          sgdisk --new=1:0:+1G $DEV
          sgdisk --new=2:0:+2M $DEV
          sgdisk --new=3:0:+1G $DEV
          sgdisk --new=4:0:0 $DEV
          sgdisk --typecode=1:FD00 --typecode=2:EF02 --typecode=3:EF00 --typecode=4:FD00 $DEV
          sgdisk --change-name=1:"Encrypted boot" --change-name=2:"BIOS boot partition" --change-name=3:"EFI system partition" --change-name=4:"Encrypted LVM" $DEV
          sgdisk --hybrid 1:2:3 $DEV

      Print the table to check it.

          sgdisk --print $DEV

      And make sure the kernel has the new partition table in memory:

          partprobe

   1. Set crypto for boot array.

      Note that, due to GRUB limitations, the older LUKS1 format is required for
      the boot partition. See [the explanation
      here](https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019#LUKS_Encrypt)
      for more information.

          cryptsetup luksFormat --type=luks1 ${DEVP}1

   1. And for the main partition:

          cryptsetup luksFormat ${DEVP}4

   1. Then open both of them

          cryptsetup open ${DEVP}1 boot_crypt
          cryptsetup open ${DEVP}4 lvm_crypt

   1. Again, because of installer limitations, it doesn't let you create a
      filesystem on the boot partition, so let's do that:

          mkfs.ext4 -L boot /dev/mapper/boot_crypt

      Alternatively, create a btrfs filesystem similarly:

          mkfs.btrfs -L boot /dev/mapper/boot_crypt

   1. Since we're formatting things, format the EFI partition:

          mkfs.vfat -n EFI ${DEVP}3

   1. Create the LVM stuff (again, installer limitations...)

          pvcreate /dev/mapper/lvm_crypt
          vgcreate drives /dev/mapper/lvm_crypt
          lvcreate --size 8G  --name swap drives
          lvcreate --size 25G --name tmp drives
          lvcreate --size 50G --name var drives
          lvcreate --size 200G --name root drives
          lvcreate --extents 100%FREE --name home drives

      Which corresponds to the following partitions and sizes (mountpoints are
      for reference and used later)

          LVM Partition Size  Mountpoint
          swap           8GB
          tmp           25GB  /tmp
          var           50GB  /var
          root          200GB /
          home          Rest  /home

       (See the discussion in the RAID section for information about swap size, etc.)

   1. Once that is all done, minimize the terminal window (you'll want to leave
      it open for later) and start the installer by double clicking the icon on
      the desktop.

1. The installer

   Proceed through as normal, selecting sane choices until you get to the
   "Installation Type" screen, where you want to choose "Something else". It
   will detect all of the volumes already created and you can set mountpoints
   and filesystems as normal.

   Set the boot loader installation to be on the first hard drive (doesn't
   matter, it will fail anyway).

   Let the installer run and then it will fail to install grub. This is expected
   and is a result of some naming issues. Tell the installer to continue without
   installing a bootloader - we'll do so manually in the next step.

   The installer crashes (because, obviously, this is the correct behavior), but
   this is the last step of the install, so we're okay. Let it continue and
   crash, and then go on to the next step.

   (You may need to kill the installer with `killall ubiquity`)

1. Manual bootloader installation

   Technically, you can get the bootloader to install if you edit some config
   files while it is working, but we need to do some post-install setup anyway,
   so we might as well just install the bootloader manually as well. But, we
   need to be in a chroot environment to do the `grub-install`, so, mount our
   root fs:

       mount /dev/mapper/drives-root /target

   If using btrfs, the above needs to be like:

       mount /dev/mapper/drives-root /target -o subvol=@

   Then do:

       for n in proc sys dev etc/resolv.conf; do mount --rbind /$n /target/$n; done
       chroot /target
       mount -a

   We also need to tell grub to use crypto disks:

       echo "GRUB_ENABLE_CRYPTODISK=y" > /etc/default/grub.d/local.cfg

   And, the cryptsetup tools are installed in the chroot. So, install them.

       apt install cryptsetup-initramfs

   And now, finally, we can install grub:

       grub-install /dev/sda

   But, we also need to tell linux to unlock our filesystems and rebuild the inittab:

       echo "boot_crypt UUID=$(blkid -s UUID -o value ${DEVP}1) none luks,discard" >> /etc/crypttab

       echo "lvm_crypt UUID=$(blkid -s UUID -o value ${DEVP}4) none luks,discard" >> /etc/crypttab

       update-initramfs -u -k all

   Once this is all done, you can reboot into your newly created machine.

### Save typing with keyfiles (Optional)

(You can do this after you've booted into the new machine, but remember to set
`DEV` and `DEVP` first, as described at the beginning of this section.

If you want to save some typing, you can create keyfiles which are built into
the initramfs and used to unlock the encrypted volumes. Note that they are
relatively safe because they are installed on an encrypted volume - but, if
someone were to compromise the running system, they could conceivably grab the
file then use it to decrypt the volume - your call.

 1. Configure it to build the keyfile into the initramfs:

        echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook

        echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf

 1. Create the keyfile (a 512 byte random number), and add it as a key to the
    volume.

        mkdir /etc/luks
        dd if=/dev/urandom of=/etc/luks/boot.keyfile bs=512 count=1
        chmod 0500 /etc/luks
        chmod 0400 /etc/luks/boot.keyfile
        cryptsetup luksAddKey /dev/${DEVP}1 /etc/luks/boot.keyfile
        cryptsetup luksAddKey /dev/${DEVP}4 /etc/luks/boot.keyfile

 1. Remove the existing `crypttab`, add the new lines which say to use the keys
    we just created, then rebuild the `initramfs`.

       rm /etc/crypttab

       echo "boot_crypt UUID=$(blkid -s UUID -o value /dev/${DEVP}1) /etc/luks/boot.keyfile luks,discard" >> /etc/crypttab

       echo "lvm_crypt UUID=$(blkid -s UUID -o value /dev/${DEVP}4) /etc/luks/boot.keyfile luks,discard" >> /etc/crypttab

       update-initramfs -u -k all

 1. Reboot and you'll enter your password less.

## Things common to most machines

  1. Install useful base things

         sudo apt install synaptic

  1. After machine is up, run synaptic and:
      1. go to settings->repositories make sure the following are enabled:
          * main
          * universe
          * restricted
          * multiverse
          * And then have it select a close mirror (select "Other"
            from the drop down and have it select the best mirror).

      1. (or just grab sources.list from some reasonable machine)

  1. Do:

         sudo apt update && sudo apt dist-upgrade

  1. Update do the HWE stack

         sudo apt install --install-recommends linux-generic-hwe-24.04

  1. Install generally useful things:

         sudo apt install traceroute emacs emacs-goodies-el elpa-go-mode elpa-rust-mode elpa-f elpa-let-alist elpa-markdown-mode elpa-yaml-mode elpa-flycheck cpufrequtils tigervnc-viewer symlinks sysstat ifstat dstat apg whois powertop printer-driver-cups-pdf units tofrodos ntp unrar mesa-utils mono-runtime aspell aspell-en geeqie input-utils p7zip latencytop apt-show-versions apt-file keepassxc ipcalc iftop atop gkrellm gnote cheese tree gdisk lm-sensors ppa-purge locate gddrescue lzip lziprecover net-tools clusterssh smartmontools nvme-cli fdupes internetarchive wget apt-transport-https vorbis-tools opus-tools shutter cpu-x
  
  1. Firefox and Thunderbird are still snaps, and snaps suck, so
     add the PPA and install from there.

         sudo add-apt-repository ppa:mozillateam/ppa

     Ignore the "It's only for 16.04 and 18.04" message. It's
     not. There are 24.04 packages too.

         echo '
         Package: thunderbird*
         Pin: release o=LP-PPA-mozillateam
         Pin-Priority: 1000
         ' | sudo tee /etc/apt/preferences.d/thunderbird
          
         echo '
         Package: firefox*
         Pin: release o=LP-PPA-mozillateam
         Pin-Priority: 1000
         ' | sudo tee /etc/apt/preferences.d/firefox

         sudo apt install firefox thunderbird

  1. Add nushell repo

         wget -O- https://apt.fury.io/nushell/gpg.key | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/fury-nushell.gpg --import
         sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" >> /etc/apt/sources.list.d/fury-nushell.list'
         sudo apt update
         sudo apt install nushell

     Also, install `ddgr`, which is needed by `ai.nu`

         sudo apt install ddgr

  1. **LAPTOP ONLY** Set CPU throttling so it doesn't overheat when it decides to turbo all the CPUs.

     **NOTE**: This may be deprecated. I need to see if the P53 actually has this problem. Additionally, it might go away on the P51 with a reapplication of thermal paste.

     1. Rant: Turbo boost is a stupid idea. "Oh, let's run our CPU hot
        and let the thermal throttling stop it from actually
        melting". Are you really serious with this foolishness?  This
        results in die temps upwards of 90C, a pile of thermal
        throttling messages in the logs, and heat buildup elsewhere in
        the system.

     1. Methodology for arriving at the numbers:

        a. Rough: Set it to the value that the CPU is rated for with no turbo
           boosting.

        b. Optimal: Run something computationally intensive for a long
           period of time (lzip a big file). The goal here is for it
           to be stable and ideally stay below 80C. What you really
           want is for it to never thermally throttle (which will show
           in the syslog). If it ever does, back the speed down.

        1. Create `/etc/default/cpufrequtils` and set the content as
           follows, with MAX_SPEED set as determined above. The
           following values are for my current Lenovo P51.

                ENABLE="true"
                GOVERNOR="powersave"
                MAX_SPEED="3200000"
                MIN_SPEED="0"

  1. Make ssh (server) work:

      1. Install it, if not already installed:

             sudo apt install openssh-server

      1. For an old machine, use the old keys - you did save /etc
         before you wiped it, didn't you?
      1. For a new machine, use the new keys generated by the distro.
      1. make sure to add to the firewall:

              sudo ufw allow ssh

      1. In `/etc/ssh/sshd_config`, set:

             PermitRootLogin no

      1. once you've set up public key auth, turn off password access. Edit `/etc/ssh/sshd_config` and set

             PasswordAuthentication no

      1. Then kick it:

              sudo service ssh restart

  1. Disable firewall logging (it can be quite verbose on a busy network), then
     turn on the firewall.

            sudo ufw logging off
            sudo ufw enable

  1. Make sure to let printers through the firewall. All printers are
     modern enough that they'll just appear and we can print to them -
     no lengthy configuration required anymore. Yay progress!

            sudo ufw allow cups
            sudo ufw allow mdns

  1. ntpd (for fixed machines only, for mobile, the default is fine)

     1. for server, make sure to add to ufw:

            sudo ufw allow ntp

     1. for client
        1. edit `/etc/ntp.conf` and comment out the "pool" lines

        1. then add the line:

               server router

  1. Add the fstab line for ramfs so I can easily mount a ramdisk whenever I
     have need of one:

         none    /mnt/ramfs    ramfs  noauto,user,mode=0770    0    0

     make sure to make the mountpoint too:

         sudo mkdir /mnt/ramfs

  1. Allow normal users to read `dmesg` again.

     Edit `/etc/sysctl.d/10-kernel-hardening.conf` and uncomment the following
     line at the bottom of the file:

         kernel.dmesg_restrict = 0

     then do:

         sudo service procps restart

     To apply the change.

  1. Fix the too long timeout for the boot selection menu

     Edit `/etc/default/grub` and add:

         GRUB_RECORDFAIL_TIMEOUT=5

     And change:

         GRUB_CMDLINE_LINUX_DEFAULT="splash quiet"

     to:

         GRUB_CMDLINE_LINUX_DEFAULT="splash quiet usbcore.autosuspend=-1"

     (to disable usb power management, which doesn't play nicely with my
      external PCIe card and my Griffin powermate)

     Then do:

         sudo update-grub

  1. Add the `efi_sync` to the daily cron list:

         cd /etc/cron.daily
         sudo ln -s /home/matt/bin/efi_sync .

## Things common to most desktop machines

  1. More applications

         sudo apt install xfce4-goodies xfce4-mount-plugin usb-creator-gtk cifs-utils gnome-calculator tumbler tumbler-plugins-extra audacious usbview

  1. Install real chrome.

     * The Ubuntu packaged chromium is broken in a couple of ways -
      NaCL support, etc. NaCL support is required for Hangouts to
      work. Solution: Install Chrome from a PPA.

     * Instructions from:
      [https://www.ubuntuupdates.org/ppa/google_chrome](https://www.ubuntuupdates.org/ppa/google_chrome)

     * But they do not follow best practices, so I adapted them according to
       [https://github.com/docker/docker.github.io/issues/11625](https://github.com/docker/docker.github.io/issues/11625)

     * See the following for more info on chromium fail:
      [https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942](https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942)

     * Do:

           wget -O- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/google.gpg --import
           sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
           sudo apt update
           sudo apt install google-chrome-stable

  1. Install slack

         sudo snap install slack --classic

  1. Install element (matrix client)

         wget -O- https://packages.element.io/debian/element-io-archive-keyring.gpg | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/element-io-archive-keyring.gpg --import
         echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
         sudo apt update
         sudo apt install element-desktop

  1. Install Joplin

         sudo snap install joplin-desktop

     1. Make sure to set it up for NextCloud sync. The sync URL is
        `https://owncloud.mattcaron.net/remote.php/webdav/Joplin-sync`

  1. Install and set  up ktorrent:

         sudo apt install ktorrent
         sudo ufw allow 6881
         sudo ufw allow 8881

  1. Make java pretty

     1. Edit both `/etc/java-21-openjdk/swing.properties` and uncomment:

            swing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel

  1. Add STL thumbnailer support

     1. See <https://github.com/unlimitedbacon/stl-thumb> for the latest, but
        basically download the deb and install it:

            sudo apt install libosmesa6-dev
            sudo dpkg -i ./stl-thumb_0.5.0_amd64.deb

  1. Floorplan software

         sudo apt install sweethome3d sweethome3d-furniture sweethome3d-furniture-nonfree

     Once installed, grab asset packs from
       <http://www.sweethome3d.com/download.jsp> and install them. Note that I've saved a bunch in ~/workspace/sweethome3d

  1. Remove audio apps that I don't use (mostly to stop them from showing in the
     volume control menu):

         sudo apt remove --purge clementine rhythmbox

  1. Remove minidlna.. why is this installed by default?

         sudo apt remove --purge minidlna

## Things for monitored machines (servers, etc.), not standalone "islands"

  1. Fix cron - add the following to the top of personal crontab:

         MAILTO="matt@mattcaron.net"

  1. Install and set up ssmtp

         sudo apt install ssmtp mailutils
         cd /etc/ssmtp
         mv ssmtp.conf ssmtp.conf.old
         cp ~/system_stuff/ssmtp/ssmtp.conf .
         chgrp mail ssmtp.conf
         chmod a+r ssmtp.conf

## Things for some machines

### Development machines

(This is all the development tools, libraries, utilities, etc. that I commonly use. There may be redundancy with the base list)

  1. Install development tools.

         sudo apt install nmap gcc make g++ gdb autoconf libtool automake libc6-dev meld xmlstarlet libtk-gbarr-perl subversion monodoc-manual glade kcachegrind kcachegrind-converters graphviz mysql-client sqlite3 dia gsfonts-x11 python3-pycurl python3-paramiko python3-pip python3-virtualenv python-is-python3 python3-setuptools regexxer git gitk git-svn libmath-round-perl picocom manpages-posix manpages-posix-dev manpages-dev manpages dh-make devscripts mercurial libboost-all-dev libboost-all-dev libhunspell-dev libwxgtk3.2-dev libwxbase3.2-1t64 ccache npm gdc libgphobos-dev libsqlite3-dev openscad slic3r arduino adb cmake libncurses-dev flex bison gperf astyle okteta f3d fonts-hack

  1. Set up KVM and management tools

         sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager virtiofsd
         sudo systemctl enable --now libvirtd
         sudo usermod -aG libvirt,kvm matt

       The KVM guest drivers are available from <https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md>.

       1. And then add a backup for the current libvirt config

              cd /etc/cron.daily
              sudo ln -s /home/matt/workspace/code/scripts/backup_scripts/libvirt_config_backup

  1. Install OpenAndroidBackup dependencies

     * Ref <https://github.com/mrrfv/open-android-backup/blob/master/README.md#linux>

           sudo apt install p7zip-full adb curl whiptail pv bc secure-delete zenity

  1. Install freecad

         sudo add-apt-repository ppa:freecad-maintainers/freecad-stable
         sudo apt install freecad

  1. Install VSCodium and some plugins
  
         wget -O- https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/vscodium.gpg --import
         echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main | sudo tee /etc/apt/sources.list.d/vscodium.list
         sudo apt update
         sudo apt install codium
         codium --install-extension DavidAnson.vscode-markdownlint
         codium --install-extension rust-lang.rust-analyzer
         codium --install-extension tamasfe.even-better-toml
         codium --install-extension James-Yu.latex-workshop
         codium --install-extension streetsidesoftware.code-spell-checker
         codium --install-extension ms-azuretools.vscode-docker
         codium --install-extension ms-vscode.cpptools
         codium --install-extension ms-vscode.cmake-tools
         codium --install-extension chiehyu.vscode-astyle
         codium --install-extension leathong.openscad-language-support

  1. (Maybe) install some extra filesystems (as needed)

         sudo apt install davfs2 sshfs jmtpfs ecryptfs-utils exfatprogs exfat-fuse hfsplus libguestfs-tools

  1. Install qbrew build dependencies:

         sudo apt install qt5-qmake qtbase5-dev qttools5-dev-tools

  1. Install docker and give users permission to use it:

         sudo apt install docker.io
         sudo usermod -a -G docker matt

  1. Install iperf and add firewall exception

         sudo apt install iperf
         sudo ufw allow 5001

  1. Install wireshark and add users to wireshark group

         sudo apt install wireshark
         sudo usermod -a -G wireshark matt

  1. Set up logic analyzer stuff (sigrok/pulseview)

      1. Install:

             sudo apt install pulseview sigrok-firmware-fx2lafw

      1. But, it needs udev rules installed. Get the two rules files from here:
          1. [https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/60-libsigrok.rules;hb=HEAD](https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/60-libsigrok.rules;hb=HEAD
)
          1. [https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/61-libsigrok-plugdev.rules;hb=HEAD](https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/61-libsigrok-plugdev.rules;hb=HEAD)
      1. And install them in to `/etc/udev/rules.d`. Note that this allows all plugdev users to use the logic analyzer (which is fine, because I am in that group).
      1. Note that the device I have uses the `fx2lafw` driver.

  1. Arduino hackery

     * Make sure you have dialout perms:

         sudo usermod -a -G dialout matt

  1. Install RPi SD card imager (if you need to make RPi images)

         sudo apt install rpi-imager

### Publishing/media/etc. machines

(This includes all kinds of desktop publishing, media manipluation and transcoding, video editing, etc.)

  1. LaTeX
      1. install the "full boat" options:

             sudo apt install --install-suggests texlive-full latex2html

      1. And set things up:

             cd /usr/share/texmf/tex/latex
             sudo cp -a ~/system_stuff/latex/local .
             sudo chown -R root:root local
             sudo cp -a ~/system_stuff/latex/fonts/cookingsymbols.tfm /usr/share/texmf/fonts/tfm/public/.
             sudo mkdir -p /usr/share/texmf/fonts/source/public/
             sudo chmod a+rx /usr/share/texmf/fonts/source/public/
             sudo cp -a ~/system_stuff/latex/fonts/cookingsymbols.mf /usr/share/texmf/fonts/source/public/.
             sudo texhash

  1. Install publishing tools from apt:

         sudo apt install xsane scribus scribus-template gnuplot gnuplot-mode digikam kipi-plugins okular okular-extra-backends k3b libk3b-extracodecs gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly kaffeine xine-ui libvdpau-va-gl1 mpg123 sox rhythmbox graphviz libsox-fmt-all dvdbackup dia gsfonts-x11 ubuntustudio-fonts vorbisgain clementine krita sound-juicer djvulibre-bin djvulibre-desktop pdf2djvu ubuntu-restricted-extras cheese arandr blender tesseract-ocr mp3info libreoffice meshlab pithos handbrake mp3gain gimp-plugin-registry

  1. Install dvdstyler:
      1. Refs: <http://ubuntuhandbook.org/index.php/2019/05/dvdstyler-3-1-released-with-hd-videos-support-how-to-install/>

             sudo add-apt-repository ppa:ubuntuhandbook1/dvdstyler
             sudo apt install dvdstyler

  1. Set up video editing:

      1. Add user to video group so I can capture video

             sudo usermod -a -G video matt

  1. Change wodim to be suid root to limit having to sudo.

         sudo chmod u+s `which wodim`

  1. Install Kdenlive

     This is an older version, but it's stable and lets us avoid that snap/flatpack garbage.  Hopefully, when the new Ubuntu LTS with Qt6/KDE6 is released, we can go back to using a native build (possibly with a PPA), but until then, we'll use this. See <https://ubuntuhandbook.org/index.php/2024/03/install-kdenlive-new-ppa/>.

         sudo apt install kdenlive

  1. Add updated Audacity PPA

     The one in the base repos is too old.

         sudo add-apt-repository ppa:ubuntuhandbook1/audacity
         sudo apt install audacity

  1. Add a udev rule so my Griffin Powermate works. Create `/etc/udev/rules.d/99-powermate.rules` as follows:

         # Griffin Powermate
         SUBSYSTEM=="input", ATTRS{idVendor}=="077d", ATTRS{idProduct}=="0410", SYMLINK+="powermate", MODE="660", GROUP="video"

     This does 2 main things:

     1. Fixes the perms so it is usable by members of the `video` group.
     1. Creates a symlink as `/dev/powermate` for ease of use.

     You can then set it up in the JogShuttle config screen in Kdenlive (which should just autodetect it).

  1. Make DVDs work

      * From: <http://www.videolan.org/developers/libdvdcss.html>

            sudo apt install libdvd-pkg
            sudo dpkg-reconfigure libdvd-pkg

  1. Install OBS Studio

         sudo add-apt-repository ppa:obsproject/obs-studio
         sudo apt install obs-studio

  1. Install updated Hugo

     Yeah, it's a snap, and snaps suck, but the one in apt is too old.

         sudo snap install hugo 

### Crazy desktop machine with too many drives

This machine has 2 NVMe drives set up in a RAID setup, as described above, and
then a bunch of single drives for working, etc. - basically, stuff that doesn't
need to be redundant because if I lose it, it's not a big deal, because I can
download it again.

  1. The mouse controller software

         sudo add-apt-repository ppa:solaar-unifying/stable
         sudo apt install solaar

  1. Steam drive

      1. Partition it and make a filesystem for it. Note the UUID it generated.
      1. Edit `/etc/fstab` and add the following lines:

             UUID=6f67768b-958d-4b8d-8dd8-e6c6ec2aea98 /home/matt/storage1   ext4    defaults        0       2
             UUID=34106401-02ac-4148-9ac2-50e29847208f /home/matt/storage2   ext4    defaults        0       2
             UUID=4a3f0b96-e61e-461a-a3f8-215799516415 /home/matt/storage3   ext4    defaults        0       2
             UUID=d58b4aa3-e32a-460a-9734-a84ccab5a61d /home/matt/storage4   ext4    defaults        0       2

         (Fill out the UUID appropriately.)

      1. Make the mount points

             mkdir ~/storage1 ~/storage2 ~/storage3 ~/storage4

      1. Mount it all:

             sudo mount -a

      1. Fix all the perms

             sudo chown -R matt:matt /home/matt/storage*

  1. `udev` rule to program programmable keyboard (Keychron K10 pro)
     1. Edit `/etc/udev/rules.d/50-keychron-k10-pro.rules`
     1. Add this line:

            KERNEL=="hidraw*", ATTRS{idVendor}=="3434", MODE="0664", GROUP="plugdev"

     1. Fix perms:

            chmod a+r /etc/udev/rules.d/50-keychron-k10-pro.rules

     1. Reload the rules and rerun them:

            udevadm control --reload-rules
            udevadm trigger

  1. Video drivers (5070 TI)

     The video drivers included in 24.04 are wrong, as is what `ubuntu-drivers install` installs. The following works.

         sudo add-apt-repository ppa:graphics-drivers/ppa
         sudo apt install nvidia-driver-575-open

### Laptop

1. Video drivers (Quadro RTX 5000 Mobile)

    This has a discrete nVidia RTX 5000 which I don't use for video
    games, but actually for AI compute. It's too old for the new
    nVidia open source drivers, and the Nouveau drivers don't support
    compute applications, so I'm installing the proprietary drivers -
    and the PPA has the most recent ones.

        sudo add-apt-repository ppa:graphics-drivers/ppa
        sudo ubuntu-drivers install

2. There is also a weird screen flickering / tearing / corruption issue which
   seems to be related to a bug in the i915 driver as it relates to the IOMMU
   configuration (see <https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2062951>). For now, to fix:

   1. Edit `/etc/default/grub`
   2. Add `intel_iommu=igfx_off` to the end of `GRUB_CMDLINE_LINUX_DEFAULT`
   3. `sudo update-grub`

    And then reboot.

3. The fans seem to be overly aggressive. Let's fix that.

   Ref: <https://blog.monosoul.dev/2021/10/17/how-to-control-thinkpad-p14s-fan-speed-in-linux/>

   1. `sudo apt install thinkfan`
   2. Then edit `/etc/thinkfan.conf` and set it as follows:

          sensors:
            # CPU
            - tpacpi: /proc/acpi/ibm/thermal
              indices: [0]
            # GPU
            - tpacpi: /proc/acpi/ibm/thermal
              indices: [1]
            # NVMe0
            - hwmon: /sys/class/hwmon/hwmon3/temp1_input
            # NVMe1
            - hwmon: /sys/class/hwmon/hwmon5/temp1_input
            # NVMe2
            - hwmon: /sys/class/hwmon/hwmon4/temp1_input
            # Motherboard sensors (I think)
            - tpacpi: /proc/acpi/ibm/thermal
              indices: [4, 5, 6]
          fans:
            - tpacpi: /proc/acpi/ibm/fan

          levels:
            - [0, 0,  35]
            - [1, 35, 40]
            - [2, 40, 50]
            - [3, 50, 60]
            - [4, 60, 70]
            - [5, 70, 75]
            - [6, 75, 80]
            - [7, 80, 85]
            - ["level full-speed", 85, 32767]

       (You can test changes with `sudo thinkfan -n`).

   3. Finally, set it to start automatically, and then start it:
          echo 'THINKFAN_ARGS="-c /etc/thinkfan.conf"' | sudo tee -a /etc/default/thinkfan
          sudo systemctl enable thinkfan
          sudo systemctl start thinkfan

### Video game machines

**Note:** A lot of the old video game stuff has moved to MiSTer (because FPGA).
 This is what remains, generally because was originally a PC game and therefore
 I'm using software to emulate software (which makes more sense than software
 emulating hardware. FPGAs are for emulating hardware).

  1. Install video game things from apt:

         sudo apt install wine-stable playonlinux steam jstest-gtk pcsx2 gamemode protontricks wine32:i386

  1. And from snap

         sudo snap install dolphin-emulator

  1. Add users to gamemode group so they can do gamemode things

         sudo usermod -aG gamemode matt

  1. Allow steam in-home streaming ports.
    1. Ref: <https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711>

         sudo ufw allow from 192.168.9.0/24 to any port 27031 proto udp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27036 proto udp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27036 proto tcp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27037 proto tcp comment 'steam'

  1. Add gcdemu

         sudo apt-add-repository ppa:cdemu/ppa
         sudo apt install gcdemu

  1. Install modern DOSBox (dosbox-x) and fluidsynth.
  
     * We can now go back to using prepackaged `dosbox-x` because my
        commit was accepted in November 2023 and the current packaged
        version is `2024.03.01`.

     * fluidsynth is installed for the good tunes.

           sudo apt install dosbox-x fluidsynth fluid-soundfont-gm fluid-soundfont-gs

  1. Set up additional video card libraries and tools:

      * Refs:
          * [https://github.com/ValveSoftware/Proton/wiki/Requirements](https://github.com/ValveSoftware/Proton/wiki/Requirements)

       1. Install the Vulkan tools, libraries, and so forth:

              sudo apt install vulkan-tools mesa-vulkan-drivers mesa-vulkan-drivers:i386

          * One can then check things with `vulkaninfo`.

  1. Install the Steam controller

      * Refs: <https://steamcommunity.com/app/353370/discussions/2/1735465524711324558/>

      1. Create `/etc/udev/rules.d/60-steam-controller-perms.rules` with the following contents:

             # This rule is needed for basic functionality of the controller in Steam and keyboard/mouse emulation
             SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"

             # This rule is necessary for gamepad emulation; make sure you replace 'matt' with a group that the user that runs Steam belongs to
             KERNEL=="uinput", MODE="0660", GROUP="matt", OPTIONS+="static_node=uinput"

             # Valve HID devices over USB hidraw
             KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"

             # Valve HID devices over bluetooth hidraw
             KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0666"

             # DualShock 4 over USB hidraw
             KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"

             # DualShock 4 wireless adapter over USB hidraw
             KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ba0", MODE="0666"

             # DualShock 4 Slim over USB hidraw
             KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"

             # DualShock 4 over bluetooth hidraw
             KERNEL=="hidraw*", KERNELS=="*054C:05C4*", MODE="0666"

             # DualShock 4 Slim over bluetooth hidraw
             KERNEL=="hidraw*", KERNELS=="*054C:09CC*", MODE="0666"

             # Nintendo Switch Pro Controller over USB hidraw
             KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666"

             # Nintendo Switch Pro Controller over bluetooth hidraw
             KERNEL=="hidraw*", KERNELS=="*057E:2009*", MODE="0666"

  1. Install Rise of The Triad (ROTT), symlink game files where expected, and configure it properly.

         sudo apt install rott
         cd /usr/share/games/
         sudo ln -s ~/storage1/dosbox/drive_c/games/rott .
         sudo update-alternatives --set rott /usr/games/rott-commercial

  1. Install Quake and symlink game files where expected.

         sudo apt install quake
         cd /usr/share/games/quake/
         sudo ln -s ~/storage1/dosbox/drive_c/games/quake/id1 .

       1. Allow Quake server port through

              sudo ufw allow 26000 comment 'quake'

  1. Install doomsday (modernized Doom/Doom2/Heretic/Hexen native engine)

     * The version in the 24.04 repos crashes, likely due to: <https://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg1960121.html>
     * I tried compiling it from source, but it still crashed when starting the game.
     * So, flatpak.

           sudo apt install flatpak
           sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
           flatpak install flathub net.dengine.Doomsday

        and then run it with:

           flatpak run net.dengine.Doomsday

  1. Install eureka (doom level editor)

          sudo apt install eureka

     (this is configured from inside its own menus)

  1. Install latest Descent 1 and 2 rebirth, and symlink things to the correct places
  
       1. Compile it (if necessary - and we do a `--clean` first, just in case):

              sudo apt install build-essential scons libsdl1.2-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libphysfs-dev
              cd ~/workspace/code/dxx-rebirth
              scons --clean
              scons -j 16 prefix=/usr
              cp -a build/d1x-rebirth/d1x-rebirth build/d2x-rebirth/d2x-rebirth ~/games/bin/.

       1. Put things in the correct places (these are the same places as used
          by the Ubuntu packaged versions, to make switching between them easy.)

              cd /usr/share/games/
              sudo mkdir -p d1x-rebirth/Data d2x-rebirth/Data
              cd d1x-rebirth/Data
              sudo ln -s ~/storage1/dosbox/drive_c/games/descent/descenta/* .
              cd d2x-rebirth/Data
              sudo ln -s ~/storage1/dosbox/drive_c/games/descent/descnt2v/* .

       1. Allow the network port through the firewall (so we can host games)

              sudo ufw allow 42424/udp comment 'descent'

  1. Install prerequisites to compile bstone
       (<https://github.com/bibendovsky/bstone>)

         sudo apt install libsdl2-dev

  1. Add repo and install ECWolf (Wolfenstein 3D and Spear of Destiny source
     port)
  
         wget -O- http://debian.drdteam.org/drdteam.gpg | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/drdteam.gpg --import
         sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/drdteam.gpg] https://debian.drdteam.org/ stable multiverse" >> /etc/apt/sources.list.d/drdteam.list'
         sudo apt update
         sudo apt install ecwolf

  1. Install and set up devilutionX (for Diablo/Hellfire)

         sudo snap install devilutionx

     and then copy `*.mpq` from the respective CDs to

         ~/snap/devilutionx/common

  1. Install Return to Castle Wolfenstein and symlink things to the correct
     places:

         sudo apt install rtcw
         sudo ln -s ~/storage1/video_games/installed/rtcw /usr/share/games/.

  1. Install mangohud

         sudo apt install mangohud

  1. Enable variable refresh rate (aka FreeSync / G-Sync) for machines with
     appropriate hardware and displays.

     1. Check that the display supports it with `xrandr --props | grep
        vrr_capable` and make sure that the connected display can do it.

     1. Create `/etc/X11/xorg.conf.d/r.conf` as follows:

            Section "Device"
                Identifier "AMD"
                Driver "amdgpu"
                Option "DRI" "3"
                Option "VariableRefresh" "true"
            EndSection

     1. And make sure it can be read via `sudo chmod a+r
        /etc/X11/xorg.conf.d/r.conf`

     1. Reboot

     1. Check that it got enabled with `grep VariableRefresh /var/log/Xorg.0.log`

  1. Install racing wheel stuff
  
     NOTE: This will likely be deprecated once they are included in mainline
     kernels.

     NOTE: This is mainly for Assetto Corsa. For setting that up, see
     <https://steamcommunity.com/app/244210/discussions/0/3824163953451160286/>
     and <https://steamcommunity.com/sharedfiles/filedetails/?id=2828364666>

     1. Install `hid-tmff2` for the wheel (including DKMS setup)

        Ref: <https://github.com/Kimplul/hid-tmff2>

            cd ~/workspace/code
            git clone --recurse-submodules https://github.com/Kimplul/hid-tmff2.git
            cd hid-tmff2
            sudo ./dkms/dkms-install.sh
            echo 'blacklist hid_thrustmaster' | sudo tee /etc/modprobe.d/blacklist-hid-thrustmaster.conf
            echo "options hid-tmff-new timer_msecs=2" | sudo tee /etc/modprobe.d/hid-tmff-new.conf
            sudo cp -a udev/99-thrustmaster.rules /etc/udev/rules.d/.
            sudo chown root:root /etc/udev/rules.d/99-thrustmaster.rules
            sudo chmod a+r /etc/udev/rules.d/99-thrustmaster.rules

     1. Install oversteer

        Ref: <https://github.com/berarma/oversteer>

            sudo apt install meson appstream-util
            cd ~/workspace/code
            git clone https://github.com/berarma/oversteer.git
            cd oversteer
            meson build
            cd build
            sudo ninja install
            sudo cp -a data/udev/99-thrustmaster-wheel-perms.rules /etc/udev/rules.d/.
            sudo chown root:root /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules
            sudo chmod a+r /etc/udev/rules.d/99-thrustmaster-wheel-perms.rules
            sudo udevadm control --reload-rules && sudo udevadm trigger

     1. After that, wheel should work when plugging it in.

     1. Create the following udev rule as
        `/etc/udev/rules.d/99-thrustmaster_t-lcm_pedals.rules` to fix
        permissions for the pedals when plugged in via USB. The ENV bit also
        forces it to be a joystick for SDL (and therefore wine/proton)
        visibility purposes.

            SUBSYSTEM=="input", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="b371", MODE="0664", ENV{ID_INPUT_JOYSTICK}="1", TAG+="uaccess"

        and then kick udev to reread it all:

            sudo udevadm control --reload-rules && sudo udevadm trigger

  1. Install Minecraft bedrock launcher

         wget -O- https://minecraft-linux.github.io/pkg/deb/pubkey.gpg | sudo gpg --no-default-keyring --keyring=/usr/share/keyrings/minecraft-linux-pkg.gpg --import
         echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/minecraft-linux-pkg.gpg] https://minecraft-linux.github.io/pkg/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/minecraft-linux-pkg.list
         sudo apt update
         sudo apt install mcpelauncher-manifest mcpelauncher-ui-manifest msa-manifest

### Random other things that may be needed on a case by case basis

  1. Set up samba:
      1. All machines:

             sudo apt install samba cifs-utils
             cd /etc/samba
             sudo mv smb.conf smb.conf.old
             sudo cp ~/system_stuff/samba/smb.conf.`hostname` ./smb.conf

      1. Servers

             sudo update-rc.d smbd defaults
             sudo update-rc.d nmbd defaults
             sudo service smbd start
             sudo service nmbd start

      1. Other machines (laptops, etc)
          1. Remember to turn it off on places you don't want the server, just
             the client.

                 echo "manual" | sudo tee /etc/init/smbd.override
                 echo "manual" | sudo tee /etc/init/nmbd.override
                 sudo service smbd stop
                 sudo service nmbd stop

          1. Make sure to add ufw rules for them

                 sudo ufw allow from 192.168.9.0/24 to any port netbios-ns
                 sudo ufw allow from 192.168.9.0/24 to any port netbios-dgm
                 sudo ufw allow from 192.168.9.0/24 to any port netbios-ssn
                 sudo ufw allow from 192.168.9.0/24 to any port microsoft-ds

      1. Set up apache (if necessary)
         1. see [Apache Installation Instructions](./install.apache)

      1. Set up sensors (if not set up automagically):
          1. For bluebox / Ryzen 3700 w/ B550 board:
              1. add the following to `/etc/modules`:

                     nct6775

          1. For hiro / Thinkpad P53:
              1. add the following to `/etc/modules`:

                     coretemp
                     jc42

          1. For new machines, you figure out what you need by running
             `sensors-detect` and following the prompts - the defaults are
             typically fine.

      1. Add temperature monitoring script to crontab (servers only):

             @hourly              /home/matt/bin/tempChecker

  1. Fix Wake On Lan

     1. Click the Network Manager Applet, then click "Edit Connections..."
     1. Pick the connection in question, then double click it.
     1. Under the "Ethernet" tab, in the "Wake on LAN" section, untick "Default" and tick "Magic".
