# Instructions for installing Ubuntu Mate 20.04

** Note: This is reflective of an upgrade from 18.04 to 20.04, so may not be 100% correct. **

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
    1. Inside this, create a VG with all necessary lartitions.

These should represent MINIMUM sizes, and is sized for 500GB HDD's. More is often better.

    LVM Partition Size  Mountpoint
    swap		  [1]
    tmp		      10GB	/tmp
    var		      40GB	/var
    root		  40GB	/
    home		  Rest	/home

[1] This is mainly important for machines where you want to
hibernate. You need at least as much swap space as you have RAM, so do
that plus a bit. See [this article](https://help.ubuntu.com/community/SwapFaq) for suggestions, but 64GB RAM gets 72GB swap. If you don't care about hibernation, you can go as small as you like.

**Note 1:** `/var` has gotten larger due to the proliferation of containers (docker, snap, etc.). If you do not plan to use these, it can be smaller.

**Note 2:** For some machines, a common area of `/pub`, or `/shared`, might be
appropriate, and should be taken out of `/home`.

Once all that is done, you'll get the "Choose software to install"
screen, where you should choose "Ubuntu mate desktop" and let it install
(we'll install everything else later)

** IMPORTANT:** If your grub-install fails, chances are you came up with an
invalid partitioning scheme. Go back to the partitioning menu and
ensure that you set your /boot partition to a non-encrypted non-LVM
parition which doesn't use a RAID greater than 1 (if any). That is
likely the culprit (otherwise, you'll spend 3 hours trying to manually
install grub only to realize that the partition which is supposed to
contain boot info is empty).

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

        sudo apt install traceroute emacs emacs-goodies-el elpa-go-mode elpa-rust-mode elpa-f elpa-let-alist elpa-markdown-mode elpa-yaml-mode elpa-flycheck retext cpufrequtils tigervnc-viewer symlinks sysstat ifstat dstat apg whois powertop printer-driver-cups-pdf units tofrodos thunderbird enigmail xul-ext-lightning firefox ntp unrar mesa-utils mono-runtime aspell aspell-en geeqie input-utils p7zip latencytop apt-show-versions apt-file keepassx ipcalc iftop atop gkrellm gnote cheese tree gdisk lm-sensors ppa-purge mlocate pulseaudio-equalizer gddrescue lzip lziprecover

    1. Install desktop extras:

        

    1. **LAPTOP ONLY** Set CPU throttling so it doesn't overheat when it decides to turbo all the CPUs.
        1. Rant: Turbo boost is a stupid idea. "Oh, let's run our CPU hot and let the thermal throttling stop it from actually melting". Are you really serious with this foolishness? This results in die temps upwards of 90C, a pile of thermal throttling messages in the logs, and heat
buildup elsewhere in the system.

        1. Methodology for arriving at the numbers:

            a. Rough: Set it to the value that the CPU is rated for with no turbo boosting.

            b. Optimal: Run something computationally intensive for a long period of time (lzip a big file). The goal here is for it to be stable and ideally stay below 80C. What you really want is for it to never thermally throttle (which will show in the syslog). If it ever does, back the speed down.

        1. Create `/etc/default/cpufrequtils` and set the content as follows, with MAX_SPEED set as determined above. The following values are for my current Lenovo P51.

                ENABLE="true"
                GOVERNOR="powersave"
                MAX_SPEED="3200000"
                MIN_SPEED="0"

  1. Set up static IPs and DNS for machines that want to be like that:

    1. edit `/etc/network/interfaces`, and add lines like:

              auto iface eth0 inet static
              address 192.168.9.1
              netmask 255.255.255.0
              gateway 192.168.9.254

    1. then do

              ifdown eth0
              ifup eth0

    1. and set the DNS server in `/etc/resolvconf/resolv.conf.d/base` as follows:

              nameserver 192.168.9.254
              search home

    1. then restart it:

              sudo service resolvconf restart

    1. and remove network-manager, because it's annoying:

              sudo apt remove network-manager

  1.  Make ssh (server) work:
    1. Install it, if not already installed:

            sudo apt install openssh-server

    1. For an old machine, use the old keys - you did save /etc, didn't you?
    1. For a new machine, use the new keys generated by the distro.
    1. make sure to add to the firewall:

            ufw allow ssh

    1. In `/etc/ssh/sshd_config`, set:

            PermitRootLogin no

    1. once you've set up public key auth, turn off password access. Edit `/etc/ssh/sshd_config` and set

            PasswordAuthentication no

    1. Then kick it:

            sudo service ssh restart

  1. Turn on the firewall.

            sudo ufw enable

  1. Make sure to let printers through the firewall. All printers are modern enough that they'll just appear and we can print to them - no lengthy configuration required anymore.

            sudo ufw allow cups
            sudo ufw allow mdns

  1. ntpd (for fixed machines only, for mobile, the default is fine)
    1. for server, make sure to add to ufw:

            ufw allow ntp

    1. for client
       1. edit `/etc/ntp.conf` and comment out the line:

            server ntp.ubuntu.com

       1. and add the line:

            server router

  1. Make java pretty
    1. Edit `/etc/java-8-openjdk/swing.properties` and uncomment:

            swing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel

    1. ** Note: ** This is untested because test setup didn't install any java things.

  1. Install real chrome.
    * The ubuntu packaged chromium is broken in a couple of ways - NaCL support, etc. NaCL support is required for Hangouts to work. Solution: Install Chrome from a PPA.
    * Instructions from: [https://www.ubuntuupdates.org/ppa/google_chrome](https://www.ubuntuupdates.org/ppa/google_chrome)
    * See the following for more info on chromium fail: [https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942](https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/882942)
    * Do:

            wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
            sudo chmod a+r /etc/apt/sources.list.d/google-chrome.list
            sudo apt update
            sudo apt install google-chrome-stable

  1. Stop the stupid GNOME SSH agent thing from working.
    1. **NOTE:** This is a stupid hack to get around the fact that, apparently, the gnome keyring is started unconditionally with all components if any gnome services are run (and we would like to run them, just not this specific one).
    1. To fix, do:

            cd /usr/bin
            sudo mv gnome-keyring-daemon gnome-keyring-daemon-wrapped

    1. Then create a new `gnome-keyring-daemon` and set its contents to:

            #!/bin/sh
            exec /usr/bin/gnome-keyring-daemon-wrapped --components=pkcs11,secrets,gpg "$@"

    1. and make it executable:

            sudo chmod a+rx /usr/bin/gnome-keyring-daemon

    1. Also, you need to go into `~/.config/autostart/gnome-keyring-ssh.desktop` and add:

            [Desktop Entry]
            X-GNOME-Autostart-enabled=false

    1. so that it doesn't get started by the ancillary (and likely redundant) separate invoker.

## Things for monitored machines (servers, etc.), not standalone "islands"

  1. Fix cron - add the following to the top of personal crontab:

            MAILTO="matt@mattcaron.net"

  1. Install and set up ssmtp

            sudo apt install ssmtp heirloom-mailx
            cd /etc/ssmtp
            mv ssmtp.conf ssmtp.conf.old
            cp ~/system_stuff/ssmtp/ssmtp.conf .
            chmod a+r ssmtp.conf

   1. Install and set up logcheck
     1. Install

            sudo apt install logcheck

     1. Edit `/etc/cron.d/logcheck` and set it to @daily and not every 2 hours

  1. Set up logmonitor

            cd /etc/logrotate.d && \
            sudo cp ~/workspace/code/scripts/logfile_monitoring/logmonitor . && \
            sudo chmod a+r logmonitor

            cd /etc/rsyslog.d && \
            sudo cp ~/workspace/code/scripts/logfile_monitoring/80-logmonitor.conf . && \
            sudo chmod a+r 80-logmonitor.conf

  1. Add Tomboy-ng from PPA:

        sudo add-apt-repository ppa:d-bannon/ppa-tomboy-ng
        sudo apt update
        sudo apt install tomboy-ng

  1. If pulseaudio gives you problems, do:

        sudo apt purge pulseaudio pulseaudio-equalizer
        sudo rm -r ~/.pulse ~/.config/pulse /etc/pulse /usr/share/pulseaudio usr/share/pulseaudio-equalizer
        sudo apt install pulseaudio pulseaudio-equalizer

   1. Reboot.

## Things for some machines

### Development machines

(This is all the development tools, libraries, utilities, etc. that I commonly use. There may be redundancy with the base list)

  1. Install development tools.

          sudo apt install nmap gcc make g++ gdb autoconf libtool automake libc6-dev meld xmlstarlet libtk-gbarr-perl subversion monodevelop monodoc-manual glade kcachegrind kcachegrind-converters graphviz mysql-client nant sqlite3 dia gsfonts-x11 python-pycurl python3-paramiko python-setuptools regexxer git gitk git-svn libmath-round-perl picocom manpages-posix manpages-posix-dev manpages-dev manpages dh-make devscripts wireshark mercurial libboost-all-dev libboost-all-dev libhunspell-dev libwxgtk3.0-gtk3-dev libwxbase3.0-dev  ccache npm gdc libgphobos-dev libsqlite3-dev

  1. (Maybe) install some extra filesystems (as needed)

          sudo apt install davfs2 sshfs jmtpfs ecryptfs-utils exfat-utils exfat-fuse hfsplus libguestfs-tools

  1. Install qbrew build dependencies:

          sudo apt install qt4-qmake libqt4-dev qt4-designer

        1. **IMPORTANT - this no longer works. Might be time for a snap or docker container for it.. or a port to qt5 or something.**

  1. Virtualbox
    1. Install:

            sudo apt install virtualbox

    1. Give users permission to use it, eg.

            sudo usermod -a -G vboxusers matt

  1. Add firewall exception for iperf

            sudo ufw allow 5001

  1. Add to wireshark group

        sudo usermod -a -G wireshark matt

  1. FreeCAD

        sudo apt install freecad

  1. Set up logic analyzer stuff (sigrok/pulseview)
    1. Install:

        sudo apt install pulseview

    1. But, it needs udev rules installed. Get the two rules files from here:
        1. [https://sigrok.org/gitweb/?p=libsigrok.git;a=blob;f=contrib/60-libsigrok.rules;h=5936f7327dc4336947b9592d176b9cc1823718d0;hb=HEAD](https://sigrok.org/gitweb/?p=libsigrok.git;a=blob;f=contrib/60-libsigrok.rules;h=5936f7327dc4336947b9592d176b9cc1823718d0;hb=HEAD
)
        1. [https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/61-libsigrok-plugdev.rules;hb=HEAD](https://sigrok.org/gitweb/?p=libsigrok.git;a=blob_plain;f=contrib/61-libsigrok-plugdev.rules;hb=HEAD)
    1. And install them in to `/etc/udev/rules.d`. Note that this allows all plugdev users to use the logic analyzer (which is fine, because I am in that group).

### Publishing/media/etc. machines

(This includes all kinds of desktop publishing, media manipluation and transcoding, video editing, etc.)

  1. LaTeX
    1. install the "full boat" options:

            sudo apt install --install-suggests texlive-full

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

          sudo apt install xsane scribus scribus-template gnuplot gnuplot-mode digikam kipi-plugins okular okular-extra-backends k3b libk3b7-extracodecs gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly kaffeine xine-ui libvdpau-va-gl1 mpg123 sox rhythmbox graphviz audacity libsox-fmt-all dvdbackup dia gsfonts-x11 ubuntustudio-fonts vorbisgain clementine krita sound-juicer djvulibre-bin djvulibre-plugin pdf2djvu ubuntu-restricted-extras cheese arandr blender kdenlive kino tesseract-ocr ffmpeg2theora mp3info libreoffice meshlab pithos mp3gain

  1. Install dvdstyler:
    1. Refs: http://ubuntuhandbook.org/index.php/2019/05/dvdstyler-3-1-released-with-hd-videos-support-how-to-install/

            sudo add-apt-repository ppa:ubuntuhandbook1/dvdstyler
            sudo apt update
            sudo apt install dvdstyler

  1. Set up video editing:
    1. Add user to video group so I can capture video

            sudo usermod -a -G video matt

  1. Install epson scanner and printer driver (Epson XP-610):
    1. Download it from [Epson](http://support.epson.net/linux/en/iscan_c.html), then uncompress it, cd into the dir, then install the packages with:

            sudo dpkg -i core/iscan_2.30.2-2_amd64.deb data/iscan-data_1.37.0-3_all.deb plugins/iscan-network-nt_1.1.1-1_amd64.deb

    1. Edit the `/etc/sane.d/epkowa.conf` file and add:

            net EPSON632112

    1. because that's the printer.
    1. Make compatibility symlinks:

            cd /usr/lib/x86_64-linux-gnu/sane
            sudo ln -s /usr/lib/sane/* .

    1. Edit `/etc/sane.d/dll.conf` and comment out the 'epson2' driver to prevent a false positive.
    1. This adds an `iscan` app which will find the printer on the network and try to use it, or you can just use xsane....
    1. IMPORTANT - it takes close to 5 minutes to find everything and start up, and it's not always reliable, but, once up, it does work. Not sure how to make it faster. Tried commenting out extra dlls,
  etc. Needs further investigation. I do see this log entry:

            Oct  6 22:48:00 hiro kernel: [48176.543355] TCP: request_sock_TCP: Possible SYN flooding on port 40796. Dropping request.  Check SNMP counters.

    1. This can be fixed, and speedy startup restored, by making sure syn flood protection is enabled by setting:

            net.ipv4.tcp_syncookies=1

    1. in `/etc/sysctl.conf` and then doing `sysctl -p` to reread it.
    1. Based on /etc/sysctl.d/10-network-security.conf, this SHOULD be set, yet it isn't, because of the firewall. Edit `/etc/ufw/sysctl.conf` and set:

            net/ipv4/tcp_syncookies=1

    1. Basically, by default, the system turns syn cookies on, but, if you turn the firewall on, it turns them off. Not sure why. But, having it on breaks my scanner because it drops packets, which is annoying. There seems to be some serious discussion as to whether or not it's better to have it on or off. See: [https://bugs.launchpad.net/ubuntu/+source/ufw/+bug/189565](https://bugs.launchpad.net/ubuntu/+source/ufw/+bug/189565) and [https://bugs.launchpad.net/ubuntu/+source/procps/+bug/57091](https://bugs.launchpad.net/ubuntu/+source/procps/+bug/57091).

    1. Also, in `/etc/default/ufw`, add `nf_conntrack_sane` to the end of the IPT_MODULES line, then do:

            sudo ufw reload

  1. Install updated handbrake from ppa
    1. The default one can't create M4V or MP4. See [http://ubuntuforums.org/showthread.php?t=2221790](http://ubuntuforums.org/showthread.php?t=2221790) for discussion.

            sudo apt-add-repository ppa:stebbins/handbrake-releases
            sudo apt install handbrake-gtk

    1. Also, [this guy](http://www.rokoding.com/) has some handy info on how to encode for broad compatibility. (Look at the guides)

 1. Change wodim to be suid root to limit having to sudo.

        sudo chmod u+s `which wodim`

 1. Make DVDs work

    From: http://www.videolan.org/developers/libdvdcss.html

        sudo apt install libdvd-pkg
        sudo dpkg-reconfigure libdvd-pkg

 1. Install shutter

        sudo snap install shutter

### Video game machines

**Note:** Most of my video game stuff has moved to MiSTer or a Dosbian install, off of the laptop / desktop. This is what remains, generally because it needs enormous processor resources. Dosbox remains for the same reason Wine does - it's pretty handy.

  1. Install video game things from apt:

          sudo apt install dosbox wine-stable playonlinux steam jstest-gtk

  1. Add gcdemu

          sudo apt-add-repository ppa:cdemu/ppa
          sudo apt install gcdemu

  1. Work around Wasteland 2 Director's cut hang because someone forgot a close somewhere.
    1. From: [https://forums.inxile-entertainment.com/viewtopic.php?f=34&t=14060#p159807](https://forums.inxile-entertainment.com/viewtopic.php?f=34&t=14060#p159807)
    1. edit `/etc/security/limits.conf`
    1. add the following (limits fix to me):

            matt soft nofile 65536
            matt hard nofile 65536

    1. Reboot.

  1. Allow steam in-home streaming ports.
    1. Ref: https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711

            sudo ufw allow from 192.168.9.0/24 to any port 27031 proto udp comment 'steam'
            sudo ufw allow from 192.168.9.0/24 to any port 27036 proto udp comment 'steam'
            sudo ufw allow from 192.168.9.0/24 to any port 27036 proto tcp comment 'steam'
            sudo ufw allow from 192.168.9.0/24 to any port 27037 proto tcp comment 'steam'

  1. **RADEON ONLY** Fix the video card on machines with modern radeon cards and install Vulkan.
    1. These should use the AMDGPU driver, not RADEON.
    1. Refs:
        1. [https://wiki.archlinux.org/index.php/AMDGPU#Enable_Southern_Islands_(SI)_and_Sea_Islands_(CIK)_support](https://wiki.archlinux.org/index.php/AMDGPU#Enable_Southern_Islands_(SI)_and_Sea_Islands_(CIK)_support)
        1. [https://forum.level1techs.com/t/r9-390x-has-garbage-performance-on-linux-please-help/140577](https://forum.level1techs.com/t/r9-390x-has-garbage-performance-on-linux-please-help/140577)
     1. Basically:
         1. Create `/etc/modprobe.d/blacklist-radeon.conf` as follows:

                sudo bash -c "echo blacklist radeon > /etc/modprobe.d/blacklist-radeon.conf"
                sudo bash -c "echo options amdgpu si_support=0 > /etc/modprobe.d/amdgpu.conf"
                sudo bash -c "echo options amdgpu cik_support=1 >> /etc/modprobe.d/amdgpu.conf"
                sudo chmod a+r /etc/modprobe.d/blacklist-radeon.conf /etc/modprobe.d/amdgpu.conf
                sudo update-initramfs -u


         1. Reboot. Just rebooting with radeon blacklisted ensures it isn't loaded and everything uses `amdgpu`.

  1. **NVIDIA Optimus ONLY**

    1. **Note** This works, kind of. It seems to completely break external monitor hookups, so I removed it. I tried to leave the module blacklist, however, to try and ensure that the card wouldn't be powered on accidentally, and therefore preserve battery life, but doing so *also* breaks external monitor hookups. So, basically, primus doesn't work with the card I have (because I get the DKMS error), but without it powered on, I don't get external monitors. Yay.

    1. Refs:
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

    1. Edit /etc/bumblebee/bumblebee.conf and:
        1. Under [bumblebeed], set Driver=nvidia.
        1. Under [driver-nvidia]:
            1. Set `LibraryPath=/usr/lib/x86_64-linux-gnu/nvidia/xorg:/usr/lib/x86_64-linux-gnu/primus`
            2. Set `XorgModulePath=/usr/lib/x86_64-linux-gnu/nvidia/xorg,/usr/lib/xorg/modules`

    1. Reboot and then:
        1. Run stuff with `primusrun`
        2. You can determine if the card is on or off by doing:

                cat /proc/acpi/bbswitch
                0000:01:00.0 OFF


   1. Set up additional video card libraries and tools:
      1. Refs:
          1. [https://github.com/ValveSoftware/Proton/wiki/Requirements](https://github.com/ValveSoftware/Proton/wiki/Requirements)

      1. Install the Vulkan tools, libraries, and so forth:

              sudo apt install vulkan-tools mesa-vulkan-drivers mesa-vulkan-drivers:i386

     1. One can then check things with `vulkaninfo`.

  1. Install the Steam controller
    1. Refs:
        1. https://steamcommunity.com/app/353370/discussions/2/1735465524711324558/

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

  1. Install Feral's Game Mode
    1. Refs: [https://www.reddit.com/r/linux_gaming/comments/dpn786/ubuntu_1910_and_ferals_gamemode/](https://www.reddit.com/r/linux_gaming/comments/dpn786/ubuntu_1910_and_ferals_gamemode/)
    1. Simply done:

            sudo apt install gamemode

    1. It can then be used to run things with:

            gamemoderun <command>

    1. It is common to set Steam programs to run this way.

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

      1. make sure to add ufw rules for them

            sudo ufw allow from 192.168.9.0/24 to any port netbios-ns
            sudo ufw allow from 192.168.9.0/24 to any port netbios-dgm
            sudo ufw allow from 192.168.9.0/24 to any port netbios-ssn
            sudo ufw allow from 192.168.9.0/24 to any port microsoft-ds

  1. Set up apache (if necessary)
    1. see [Apache Installation Instructions](./install.apache)


  1. Set up sensors (if not set up automagically) for case
    1. For bluebox / Gigabyte X48-DQ6 board
      1. add the following to `/etc/modules`:

            it87
            coretemp

    1. For hiro / Thinkpad P51:
      1. add the following to `/etc/modules`:

            coretemp

    1. For new machines, you figure out what you need by running `sensors-detect` and following the prompts - the defaults are typically fine.

    1. ** FIXME - edit the conf file to fix scaling, etc. **

  1. Add temperature monitoring script to crontab (servers only):

            @hourly              /home/matt/bin/tempChecker

  1. Install and set  up ktorrent:
    1. Install:

            sudo apt install ktorrent

    1. Allow firewall exception for ktorrent:

            sudo ufw allow 6881
            sudo ufw allow 8881

  1. Install and configure hibernation
    1. Install:

            sudo apt install hibernate

    1. Add a file, `/etc/sudoers.d/matt-hibernate-disk`, which contains the following:

            matt ALL=(ALL) NOPASSWD: /usr/sbin/hibernate-disk

    1. And make sure that it is mode 0440.
    1. When you can call `hibernate-disk` or have it on an icon, or whatever.

  1.  Install offical skype:

        sudo add-apt-repository "deb https://repo.skype.com/deb stable main"
        sudo apt install skypeforlinux
