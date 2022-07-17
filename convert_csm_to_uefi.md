# How to convert legacy (CSM) mode to UEFI without reinstalling

## Introduction

This assumes a filesystem with some free space (I'm using home), inside an LVM
volume, inside a crytpo volume, inside a RAID array. Because that's how I run
most things. Doesn't everyone?

The basic theory of operation here is, to avoid having to do precise math while
making sure all the space on the drive is allocated, we make sure to shrink
everything in the above "onion" more than we need, then expand it all back at
the end.

## Procedure

  1. Boot from an appropriate rescue image. I used
     [System Rescue](https://www.system-rescue.org/), burned to a USB drive.
     This is necessary because then we can ensure that nothing is using any of
     the volumes/partitions/etc. we want to resize.

  1. Find the encrypted volume.

         cat /proc/mdstat

     (It's the bigger one.)

  1. Start the crypto volume

         cryptsetup open /dev/md126 drives

  1. Check the filesystem we're going to resize

         e2fsck -f /dev/mapper/drives-home

  1. Resize it. Note that the number should be 50G less than the current
     filesystem size.

         resize2fs /dev/mapper/drives-home 1650G

  1. Resize the logical volume

         lvresize --size -45G /dev/mapper/drives-home

  1. Resize the physical volume.

     This isn't as convenient as the above. First, you need to do:

         pvs --unit m

     Note the size, subtract 40000 from it, and then do:

         pvresize --setphysicalvolumesize size /dev/mapper/drives

     Where size is the size you calculated - **make sure the suffix m is
     specified**.

     At this point, the resize may fail with an error of `cannot resize to XXXX
     extents as later ones are allocated`. This doesn't mean that there isn't
     enough free space, just that the resize doesn't automatically move extents
     around when resizing. Note the above number in the error message.

     To fix this, do:

         lvdisplay -m

     And look through trying to find any physical extents that are a larger
     number than that, and note them. Then, issue a command to move them,
     allowing them to be moved anywhere.

         pvmove /dev/mapper/drives:start-end --alloc anywhere

     Where start and end are the beginning extent we want to free (should be the
     one it was complaining about less one, that is XXXX-1 above) and the
     highest extent we found allocated in our `lvdisplay`. So, you would end up
     with something like:

         pvmove /dev/mapper/drives:462429-476656 --alloc anywhere

     The `--alloc anywhere` option seems to favor packing the data at the
     beginning, and it's easier than manually figuring out where to put
     everything.

  1. Resize the crypto volume

     Using the same size you got from `pvs`, above, now subtract 35000 from it, and use it below:

         cryptsetup resize drives --verbose --device-size size

     Where size is the size you calculated - **make sure the suffix m is
     specified**.

  1. Resize the metadisk

     Despite the use of the term `grow` here, we're growing it a negative
     amount, which is shrinking it. Conveniently, we can specify a negative
     value here, so we don't need to do more math.

         mdadm --grow /dev/md126 --size -30G

  1. Shut down the volume groups on the above array, so we can stop it.

         vgchange -a n drives

  1. Stop the array so we can resize the underlying partition.

         mdadm --stop /dev/md126

  1. For each drive, run parted to shrink the partitions, then do the following:

         parted resizepart 2 -1500M

     This shrinks the partition by exactly how much we want.

  1. Start the md device again:

         mdadm -A --scan

  1. Then grow it to the full size:

         mdadm --grow /dev/md126 --size=max

  1. Open the crypto volume again:

         cryptsetup open /dev/md126 drives

  1. Resize the crypto volume to max size (that's what no arguments does):

         cryptsetup resize drives --verbose

  1. Resize the physical volume (again, no arguments means max size)

         pvresize /dev/mapper/drives

  1. Resize the logical volume we shrank previously to use all of the available
     PVs

         lvresize -l 100%PVS /dev/mapper/drives-home

  1. Resize the underlying filesystem to fill the volume:

         resize2fs /dev/mapper/drives-home

  1. Reboot and boot the main OS again.
  
     All our disk resizing is now done - we're just adding things.

  1. For each drive, run `gdisk` and add our new partitions (BIOS and EFI boot)
     as follows:

     1. Create a new partition, starting wherever, size 1MB, and FS code ef02.
     1. Create a new partition, starting wherever, using the rest of the space,
        and FS code ef00.

  1. Reread the new partition table:

         sudo partprobe

  1. Create the filesystems on the each EFI partition with `mkfs.vfat`

  1. Update fstab by adding an info line for the first drive's EFI partition,
     like this:

         /dev/nvme0n1p4        /boot/efi         vfat   defaults         0       2

  1. And make sure to make the mountpoint:

         sudo mkdir /boot/efi

  1. Install the EFI version of grub.

         sudo apt install grub-efi

  1. Install all the needed EFI files:

         sudo grub-install --target=x86_64-efi /boot/efi

  1. Install the grub stuff to the boot sectors of all bootable drives by doing:

         sudo grub-install <drive>

     for each drive.

  1. Reboot the system, and enable EFI boot in the BIOS.

  For RAID systems, make sure to set up the sync script.


## Addendum - unencrypting an encrypted volume

Let's presume, for a minute, that you ran your default setup is to encrypt
everything, and, while this is totally valid for machines that leave the house,
does it really make sense to have to unlock the filesystem for a system you
never turn off and never leaves the house? Likely not, and it just makes for
annoyance when rebooting. In that case, this would be how you would do such a
thing.

Note that the following procedure is necessary because of a (debatable) bug in
the direct method. (See [this bug
report](https://gitlab.com/cryptsetup/cryptsetup/-/issues/614) for more
information.) I have used the following procedure and it works, albeit with
extra steps, and was cribbed from [this stackexchange anser](https://unix.stackexchange.com/a/606231).

  1. Boot from an appropriate rescue image. I used
     [System Rescue](https://www.system-rescue.org/), burned to a USB drive.

  1. Convert all key-slots to use LUKS1 compatible parameters with

         cryptsetup luksChangeKey  --pbkdf pbkdf2 /dev/md126

  1. Convert the LUKS2 device to a LUKS1 device using

         cryptsetup convert --type luks1 /dev/md126

  1. Perform the decryption using

         cryptsetup-reencrypt --decrypt /dev/md126

     This step is time consuming. It took 3 hours to decrypt a 2TB NVMe
array. Go get coffee or play video games or something. I set it up at night and
then went to read and go to sleep.

  1. Once done, reboot into the main OS. It will likely take some time to find
     the encrypted volume, fail, then boot up normally. To correct this:

     1. Edit `/etc/crypttab` and remove the line for the crypto device which no
        longer exists.

     1. Rebuild the initramfs and other things used to bootstrap the system:

            sudo dpkg-reconfigure linux-image-`uname -r`
