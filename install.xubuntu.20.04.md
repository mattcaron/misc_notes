# Instructions for installing XUbuntu 20.04

## Base Install

Boot the minimal CD and perform a standard-spec install. Partitioning
should be roughly as follows, adjusted for available disk size as
appropriate (including for RAID). Disk labels should be representative
of the mount point. Manual partitioning is required.

Physical Partitions (on both drives):

  1. 1GB  Physical volume for RAID (boot)
  1. Rest Physical volume for RAID (everything else)

You want the above physical partition scheme across alldrives, with each one set up for "Physical volume for RAID". Then you create MD devices for each pairing (same partition on each drive) and then:

  1. For boot, define it to be whatever filesystem you want.
  1. For the rest, it should be physical volume for encryption.
    1. Inside this, it should be LVM PV
    1. Inside this, create a VG with all necessary partitions.

These should represent MINIMUM sizes, and is sized for 500GB HDD's. More is often better.

    LVM Partition Size  Mountpoint
    swap          [1]
    tmp           10GB  /tmp
    var           40GB  /var
    root          40GB  /
    home          Rest  /home

[1] This is mainly important for machines where you want to
hibernate. You need at least as much swap space as you have RAM, so do
that plus a bit. See [this article](https://help.ubuntu.com/community/SwapFaq) for suggestions, but 64GB RAM gets 72GB swap. If you don't care about hibernation, you can go as small as you like.

**Note 1:** `/var` has gotten larger due to the proliferation of containers (docker, snap, etc.). If you do not plan to use these, it can be smaller.

**Note 2:** For some machines, a common area of `/pub`, or `/shared`, might be
appropriate, and should be taken out of `/home`.

Once all that is done, you'll get the "Choose software to install"
screen, where you should choose "OpenSSH server" and "Xubuntu desktop" and let it install (we'll install everything else later)

**IMPORTANT:** If your grub-install fails, chances are you came up with an invalid partitioning scheme. Go back to the partitioning menu and ensure that you set your /boot partition to a non-encrypted non-LVM partition which doesn't use a RAID greater than 1 (if any). That is likely the culprit (otherwise, you'll spend 3 hours trying to manually install grub only to realize that the partition which is supposed to contain boot info is empty.. ask me how I know).

## Things common to most machines

  1. Install useful base things

        sudo apt install synaptic

  1. After machine is up, run synaptic and:
      1. go to settings->repositories make sure the following are enabled:
          * main
          * universe
          * restricted
          * multiverse
          * And then have it select a close mirror (select "Other" from the drop down and have it select the best mirror).
      1. Select the other software tab and enable/add:
          * partner
      1. (or just grab sources.list from some reasonable machine)

  1. Do:

         sudo apt update && sudo apt dist-upgrade

  1. Install generally useful things:

       sudo apt install traceroute emacs emacs-goodies-el elpa-go-mode elpa-rust-mode elpa-f elpa-let-alist elpa-markdown-mode elpa-yaml-mode elpa-flycheck cpufrequtils tigervnc-viewer symlinks sysstat ifstat dstat apg whois powertop printer-driver-cups-pdf units tofrodos thunderbird enigmail xul-ext-lightning firefox ntp unrar mesa-utils mono-runtime aspell aspell-en geeqie input-utils p7zip latencytop apt-show-versions apt-file keepassx ipcalc iftop atop gkrellm gnote cheese tree gdisk lm-sensors ppa-purge mlocate gddrescue lzip lziprecover net-tools clusterssh smartmontools fdupes internetarchive

  1. **LAPTOP ONLY** Set CPU throttling so it doesn't overheat when it decides to turbo all the CPUs.
  
     1. Rant: Turbo boost is a stupid idea. "Oh, let's run our CPU hot and let the thermal throttling stop it from actually melting". Are you really serious with this foolishness? This results in die temps upwards of 90C, a pile of thermal throttling messages in the logs, and heat buildup elsewhere in the system.

     1. Methodology for arriving at the numbers:

        a. Rough: Set it to the value that the CPU is rated for with no turbo boosting.

        b. Optimal: Run something computationally intensive for a long period of time (lzip a big file). The goal here is for it to be stable and ideally stay below 80C. What you really want is for it to never thermally throttle (which will show in the syslog). If it ever does, back the speed down.

        1. Create `/etc/default/cpufrequtils` and set the content as follows, with MAX_SPEED set as determined above. The following values are for my current Lenovo P51.

                ENABLE="true"
                GOVERNOR="powersave"
                MAX_SPEED="3200000"
                MIN_SPEED="0"

  1. Make ssh (server) work:

      1. Install it, if not already installed:

             sudo apt install openssh-server

      1. For an old machine, use the old keys - you did save /etc, didn't you?
      1. For a new machine, use the new keys generated by the distro.
      1. make sure to add to the firewall:

             sudo ufw allow ssh

      1. In `/etc/ssh/sshd_config`, set:

             PermitRootLogin no

      1. once you've set up public key auth, turn off password access. Edit `/etc/ssh/sshd_config` and set

             PasswordAuthentication no

      1. Then kick it:

              sudo service ssh restart

  1. Disable firewall logging (it can be quite verbose on a busy network), then turn on the firewall.

            sudo ufw logging off
            sudo ufw enable

  1. Make sure to let printers through the firewall. All printers are modern enough that they'll just appear and we can print to them - no lengthy configuration required anymore.

            sudo ufw allow cups
            sudo ufw allow mdns

  1. ntpd (for fixed machines only, for mobile, the default is fine)

     1. for server, make sure to add to ufw:

            sudo ufw allow ntp

     1. for client
        1. edit `/etc/ntp.conf` and comment out the line:

               server ntp.ubuntu.com

        1. and add the line:

               server router

  1. Add the fstab line for ramfs so I can easily mount a ramdisk whenever I have need of one:

         none    /mnt/ramfs    ramfs  noauto,user,mode=0770    0    0

     make sure to make the mountpoint too:

         sudo mkdir /mnt/ramfs


## Things common to most desktop machines

  1. More applications

        sudo apt install xfce4-goodies xfce4-mount-plugin usb-creator-gtk cifs-utils gnome-calculator

  1. Install real chrome.
    - The ubuntu packaged chromium is broken in a couple of ways - NaCL support, etc. NaCL support is required for Hangouts to work. Solution: Install Chrome from a PPA.
    - Instructions from: [https://www.ubuntuupdates.org/ppa/google_chrome](https://www.ubuntuupdates.org/ppa/google_chrome)
    - See the following for more info on chromium fail: [https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942](https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942)
    - Do:

            wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
            sudo chmod a+r /etc/apt/sources.list.d/google-chrome.list
            sudo apt update
            sudo apt install google-chrome-stable

  1. Stop the stupid GNOME SSH agent thing from working.
      - **NOTE:** This is a stupid hack to get around the fact that, apparently, the gnome keyring is started unconditionally with all components if any gnome services are run (and we would like to run them, just not this specific one).

      1. To fix, do:

             cd /usr/bin
             sudo mv gnome-keyring-daemon gnome-keyring-daemon-wrapped

      1. Then create a new `gnome-keyring-daemon` and set its contents to:

             #!/bin/sh
             exec /usr/bin/gnome-keyring-daemon-wrapped --components=pkcs11,secrets,gpg "$@"

      1. and make it executable:

             sudo chmod a+rx /usr/bin/gnome-keyring-daemon

  1. Install slack

         sudo snap install slack --classic

  1. Install element (matrix client)

         sudo apt install -y wget apt-transport-https

         sudo wget -O /usr/share/keyrings/riot-im-archive-keyring.gpg https://packages.riot.im/debian/riot-im-archive-keyring.gpg

         echo "deb [signed-by=/usr/share/keyrings/riot-im-archive-keyring.gpg] https://packages.riot.im/debian/ default main" | sudo tee /etc/apt/sources.list.d/riot-im.list

         sudo apt update

         sudo apt install element-desktop

  1. Install shutter

         sudo snap install shutter

  1. Install Joplin

         sudo snap install joplin-desktop

      1. Make sure to set it up for NextCloud sync. The sync URL is https://owncloud.mattcaron.net/remote.php/webdav/Joplin-sync

  1. Install and set  up ktorrent:

         sudo apt install ktorrent
         sudo ufw allow 6881
         sudo ufw allow 8881

  1. Make java pretty

      1. Edit `/etc/java-11-openjdk/swing.properties` and uncomment:

             swing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel

  1. Install an equalizer (among other effects)

       sudo apt install pulseffects lsp-plugins

  1. Install bleeding edge Amarok QT5 port

       sudo add-apt-repository ppa:pgomes/amarok
       sudo apt install amarok

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

          sudo apt install nmap gcc make g++ gdb autoconf libtool automake libc6-dev meld xmlstarlet libtk-gbarr-perl subversion monodoc-manual glade kcachegrind kcachegrind-converters graphviz mysql-client nant sqlite3 dia gsfonts-x11 python-pycurl python3-paramiko python3-pip python3-virtualenv python-is-python3 python-setuptools regexxer git gitk git-svn libmath-round-perl picocom manpages-posix manpages-posix-dev manpages-dev manpages dh-make devscripts mercurial libboost-all-dev libboost-all-dev libhunspell-dev libwxgtk3.0-gtk3-dev libwxbase3.0-dev ccache npm gdc libgphobos-dev libsqlite3-dev freecad openscad slic3r arduino adb cmake libncurses-dev flex bison gperf astyle okteta
  
  1. Install snapcraft

         sudo snap install --classic snapcraft

  1. Install VSCode and some plugins

         sudo snap install code --classic

         code --install-extension DavidAnson.vscode-markdownlint
         code --install-extension rust-lang.rust
         code --install-extension tamasfe.even-better-toml
         code --install-extension James-Yu.latex-workshop
         code --install-extension streetsidesoftware.code-spell-checker
         code --install-extension ms-azuretools.vscode-docker
         code --install-extension ms-vscode.cpptools
         code --install-extension ms-vscode.cmake-tools
         code --install-extension chiehyu.vscode-astyle

  1. (Maybe) install some extra filesystems (as needed)

          sudo apt install davfs2 sshfs jmtpfs ecryptfs-utils exfat-utils exfat-fuse hfsplus libguestfs-tools

  1. Install qbrew build dependencies:

          sudo apt install qt5-qmake qtbase5-dev qttools5-dev-tools

  1. Install Virtualbox and give users permission to use it:

          sudo apt install virtualbox
          sudo usermod -a -G vboxusers matt

  1. Install docker and give users permission to use it:

          sudo apt install docker
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

     I find myself using various old versions of Arduino, so some hackery is required because they link against old versions of things....

         cd /usr/lib/x86_64-linux-gnu/
         sudo ln -s libreadline.so.8 libreadline.so.6
         sudo apt install libncurses5 libtinfo5

  1. Install RPi SD card imager

         sudo snap install rpi-imager

  1. Headtracking build stuff

     1. Opentrack dependencies

            sudo apt install cmake git qttools5-dev qtbase5-private-dev libprocps-dev libopencv-dev

     1. AITrack dependencies

            sudo apt install qtbase5-dev qtbase5-dev-tools libqt5x11extras5-dev libopencv-dev libspdlog-dev libfmt-dev libomp-12-dev qt5-default libqt5x11extras5 libspdlog1 libomp5-12 libxsettings-dev libxsettings-client-dev
       
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

         sudo apt install xsane scribus scribus-template gnuplot gnuplot-mode digikam kipi-plugins okular okular-extra-backends k3b libk3b7-extracodecs gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly kaffeine xine-ui libvdpau-va-gl1 mpg123 sox rhythmbox graphviz audacity libsox-fmt-all dvdbackup dia gsfonts-x11 ubuntustudio-fonts vorbisgain clementine krita sound-juicer djvulibre-bin djvulibre-plugin pdf2djvu ubuntu-restricted-extras cheese arandr blender kdenlive kino tesseract-ocr ffmpeg2theora mp3info libreoffice meshlab pithos handbrake

  1. And some of them are snaps now

         sudo snap install mp3gain

  1. Install dvdstyler:
      1. Refs: http://ubuntuhandbook.org/index.php/2019/05/dvdstyler-3-1-released-with-hd-videos-support-how-to-install/

             sudo add-apt-repository ppa:ubuntuhandbook1/dvdstyler
             sudo apt update
             sudo apt install dvdstyler

  1. Set up video editing:
      1. Add user to video group so I can capture video

             sudo usermod -a -G video matt

  1. Change wodim to be suid root to limit having to sudo.

         sudo chmod u+s `which wodim`

  1. Make DVDs work
      - From: http://www.videolan.org/developers/libdvdcss.html

            sudo apt install libdvd-pkg
            sudo dpkg-reconfigure libdvd-pkg

  1. Add the better airscan (eSCL) driver
     * Ref:
       https://software.opensuse.org//download.html?project=home%3Apzz&package=sane-airscan
       
           echo 'deb http://download.opensuse.org/repositories/home:/pzz/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:pzz.list
           curl -fsSL https://download.opensuse.org/repositories/home:pzz/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_pzz.gpg > /dev/null
           sudo apt update
           sudo apt install sane-airscan

      * Note that this is shipped as part of 20.10 so the extra repo is only temporary.

### Crazy desktop machine with too many drives.

This machine has 2 NVMe drives set up in a RAID setup, as described above, and then a bunch of single drives for working, etc. - basically, stuff that doesn't need to be redundant because if I lose it, it's not a big deal, because I can download it again.

  1. STEAM drive
      1. Partition it and make a filesystem for it. Note the UUID it generated.
      1. Edit `/etc/fstab` and add the following lines:

            UUID=0049f26d-af97-4cf9-b962-c6dc5c30cdbc /home/matt/storage    ext4    defaults        0       2
            /home/matt/storage1/steam	/home/matt/.steam   none bind	       0       0 
            UUID=6ea7f9c1-3204-483f-afa8-5b859a185661 /home/matt/storage2    ext4    defaults        0       2

         (Fill out the UUID appropriately.)

      1. Make the mount points

             mkdir ~/.steam ~/storage ~/storage2

      1. Mount the first things

             sudo mount /home/matt/storage
             sudo mount /home/matt/storage2

      1. Fix perms

             sudo chown -R matt:matt /home/matt/storage /home/matt/storage2

      1. Make the other source point (may exist if the drive is old):

             mkdir /mnt/storage1/steam

      1. Mount it all:

             sudo mount -a

### Video game machines

**Note:** A lot of the old video game stuff has moved to MiSTer (because FPGA). This is what remains, generally because was originally a PC game and therefore I'm using software to emulate software (which makes more sense than software emulating hardware. FPGAs are for emulating hardware).

  1. Install video game things from apt:

          sudo apt install wine-stable playonlinux steam jstest-gtk

  1. Allow steam in-home streaming ports.
    1. Ref: https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711

         sudo ufw allow from 192.168.9.0/24 to any port 27031 proto udp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27036 proto udp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27036 proto tcp comment 'steam'
         sudo ufw allow from 192.168.9.0/24 to any port 27037 proto tcp comment 'steam'

  1. Add gcdemu

         sudo apt-add-repository ppa:cdemu/ppa
         sudo apt install gcdemu

  1. Install modern DOSBox (dosbox-staging)

     20.04 ships with 0.74 and there have been a lot of improvements since then, especially for modern joysticks and gamepad support. But, that's not official, even though it's widely used. See https://github.com/dosbox-staging/dosbox-staging and https://launchpad.net/~feignint/+archive/ubuntu/dosbox-staging/ for more details.

         sudo add-apt-repository ppa:feignint/dosbox-staging
         sudo apt update
         sudo apt install dosbox-staging

     And make sure fluidsynth is installed for the good tunes.

         sudo apt install fluidsynth fluid-soundfont-gm fluid-soundfont-gs

  1. Install Lutris

     Instructions: https://lutris.net/downloads/

         sudo add-apt-repository ppa:lutris-team/lutris
         sudo apt update
         sudo apt install lutris

  1. Work around Wasteland 2 Director's cut hang because someone forgot a close somewhere.

     - **TODO:** It has been years since this was released so this may not be an issue anymore. Move to a deprecated notes file or something.

     - From: [https://forums.inxile-entertainment.com/viewtopic.php?f=34&t=14060#p159807](https://forums.inxile-entertainment.com/viewtopic.php?f=34&t=14060#p159807)
     1. edit `/etc/security/limits.conf`
         1. add the following (limits fix to me):

                matt soft nofile 65536
                matt hard nofile 65536

         1. Reboot.

  1. **RADEON ONLY** Fix the video card on machines with modern radeon cards and install Vulkan.
      1. This was originally for a Radeon R9 390 and seems to work for RX 6600 too.
      1. These should use the AMDGPU driver, not RADEON.
      1. Refs:
          * [https://wiki.archlinux.org/index.php/AMDGPU#Enable_Southern_Islands_(SI)_and_Sea_Islands_(CIK)_support](https://wiki.archlinux.org/index.php/AMDGPU#Enable_Southern_Islands_(SI)_and_Sea_Islands_(CIK)_support)
          * [https://forum.level1techs.com/t/r9-390x-has-garbage-performance-on-linux-please-help/140577](https://forum.level1techs.com/t/r9-390x-has-garbage-performance-on-linux-please-help/140577)
      1. Basically:
          1. Create `/etc/modprobe.d/blacklist-radeon.conf` as follows:

                 sudo bash -c "echo blacklist radeon > /etc/modprobe.d/blacklist-radeon.conf"
                 sudo bash -c "echo options amdgpu si_support=0 > /etc/modprobe.d/amdgpu.conf"
                 sudo bash -c "echo options amdgpu cik_support=1 >> /etc/modprobe.d/amdgpu.conf"
                 sudo chmod a+r /etc/modprobe.d/blacklist-radeon.conf /etc/modprobe.d/amdgpu.conf
                 sudo update-initramfs -u

          1. Reboot. Just rebooting with radeon blacklisted ensures it isn't loaded and everything uses `amdgpu`.

  1. **NVIDIA Optimus ONLY**
      * **Note** This works, kind of. It seems to completely break external monitor hookups, so I removed it. I tried to leave the module blacklist, however, to try and ensure that the card wouldn't be powered on accidentally, and therefore preserve battery life, but doing so *also* breaks external monitor hookups. So, basically, primus doesn't work with the card I have (because I get the DKMS error), but without it powered on, I don't get external monitors. Yay.
      * Refs:
        * https://www.bumblebee-project.org/
        * https://wiki.ubuntu.com/Bumblebee#Installation
        * https://github.com/Bumblebee-Project/Bumblebee/wiki/
        * https://github.com/Bumblebee-Project/Bumblebee/issues/951
        * https://github.com/Bumblebee-Project/Bumblebee/issues/526

        Note: At the time of writing, the nouveau driver does not work with this card. I get the dreaded:

            "NOUVEAU(0): [drm] failed to set drm interface version."

        So, we're using the official nvidia driver.

      1. Install it:

             sudo apt install primus-nvidia bumblebee-nvidia xserver-xorg-input-mouse nvidia-driver-440

      1. This involves a group permission add (bumblebee group), so you may need to log out and log back in. If that does not alone does not do it, add yourself to the group with the following, then log back out nad back in.

             sudo usermod -a -G bumblebee matt

      1. The nouveau driver can fight with stuff; blacklist it:

             sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
             sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
             sudo update-initramfs -u

      1. Edit `/etc/bumblebee/bumblebee.conf` and:
          1. Under `[bumblebeed]`, set `Driver=nvidia`.
          1. Under `[driver-nvidia]`:
              1. Set `LibraryPath=/usr/lib/x86_64-linux-gnu/nvidia/xorg:/usr/lib/x86_64-linux-gnu/primus`
              2. Set `XorgModulePath=/usr/lib/x86_64-linux-gnu/nvidia/xorg,/usr/lib/xorg/modules`
      1. Reboot and then:
          1. Run stuff with `primusrun`
          2. You can determine if the card is on or off by doing:

                 cat /proc/acpi/bbswitch
                 0000:01:00.0 OFF
      1. Set up additional video card libraries and tools:
          - Refs:
          - [https://github.com/ValveSoftware/Proton/wiki/Requirements](https://github.com/ValveSoftware/Proton/wiki/Requirements)
          1. Install the Vulkan tools, libraries, and so forth:

                 sudo apt install vulkan-tools mesa-vulkan-drivers mesa-vulkan-drivers:i386
          1. One can then check things with `vulkaninfo`.

  1. Install the Steam controller
      - Refs: https://steamcommunity.com/app/353370/discussions/2/1735465524711324558/
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

  1. Install doomsday (modernized Doom/Doom2/Heretic/Hexen native engine)

         sudo apt install doomsday

     (this is configured from inside its own menus)

  1. Install Descent 1 and 2 rebirth, and symlink things to the correct places

         sudo apt install d1x-rebirth d2x-rebirth
         cd /usr/share/games/
         sudo mkdir -p d1x-rebirth/Data d2x-rebirth/Data
         cd d1x-rebirth/Data
         sudo ln -s ~/storage/dosbox/drive_c/games/descent/descenta/* .
         cd d2x-rebirth/Data
         sudo ln -s ~/storage/dosbox/drive_c/games/descent/descent2/* .

  1. Install protontricks (for Proton tweaking)

         sudo apt install python3-pip python3-setuptools python3-venv pipx
         pipx install protontricks

  1. Install prerequisites to compile bstone
       (https://github.com/bibendovsky/bstone)

         sudo apt install libsdl2-dev

  1. Add repo and install ECWolf (Wolfenstein 3D and Spear of Destiny source port)

         wget -O- http://debian.drdteam.org/drdteam.gpg | sudo apt-key add -
         sudo apt-add-repository 'deb http://debian.drdteam.org/ stable multiverse'
         sudo apt-get update
         sudo apt-get install ecwolf

  1. Install and set up devilutionX (for Diablo/Hellfire

         sudo add-apt-repository ppa:devilutionx/stable
         sudo apt update
         sudo apt install devilutionx

     and then copy `*.mpq` from the respective CDs to
     `~/.local/share/diasurgical/devilution/`

  1. Install Return to Castle Wolfenstein and symlink things to the correct places:

         sudo apt install rtcw
         sudo ln -s ~/storage1/video_games/installed/rtcw /usr/share/games/.

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
          1. Remember to turn it off on places you don't want the server, just the client.

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

          1. For hiro / Thinkpad P51:
            1. add the following to `/etc/modules`:

                 coretemp

          1. For new machines, you figure out what you need by running `sensors-detect` and following the prompts - the defaults are typically fine.

          1. **FIXME - edit the conf file to fix scaling, etc.**

      1. Add temperature monitoring script to crontab (servers only):

             @hourly              /home/matt/bin/tempChecker

  1. If pulseaudio gives you problems, do:

         sudo apt purge pulseaudio
         sudo rm -r ~/.pulse ~/.config/pulse /etc/pulse /usr/share/pulseaudio
         sudo apt install pulseaudio

      1. Reboot.
      1. If you don't get a volume icon, it's likely that the indicator plugin was uninstalled as a dependency; reinstall it:

             sudo apt install xfce4-pulseaudio-plugin

  1. Fix Wake On Lan
      1. Install ethtool

             sudo apt install ethtool

      1. Create `/etc/network/if-up.d/wol_fix` with the following content, replacing `[card]` with the card:

             #!/bin/sh
             /sbin/ethtool -s [card] wol g

      1. And set the perms on it:

             sudo chmod +x /etc/network/if-up.d/wol_fix

# Compatibility stuff for the new B550 / RX 6600 rig that I want to keep on 20.04 for now.

  1. Install Realtek 8125 driver

    1. Download / untar / etc it from Realtek

    1. cd to the dir and run `sudo ./autorun.sh`

  1. Install AMD proprietary driver (better support on 20.04)

    1. Download / untar / etc it from AMD

    1. cd to the dir and run `sudo ./amdgpu-install