# Stair controller instructions

## Background

This is a Raspberry Pi 3 model B Rev 1.2 hooked to a relay board which turns on
/ off a contactor which then turns on / off the heating coil. The GPIO drives
the relay which switches 110V which controls the contactor which switches 220V.
There is a second, lower-powered coil which is directly driven, as it runs off
110V.

The whole thing is controlled via NodeRED.

## Instructions

### Base install and upgrades

**Note:** Use a good quality MicroSD card, ideally something industrial grade.

Initialize the MicroSD card with RPi-imager and install the latest **Ubuntu
Server 24.04 LTS (64-bit)**. This is minimal and has no desktop OS, which is
what we need.

When prompted, apply OS customization settings.

1. Set the hostname to `stairs`
    - I mean, unless it's some sort of replacement for the existing one. Avoid
      DNS conflicts, then flip it, and all that.
1. Set a username and password for the default user
1. Skip wireless, we plug this one in.
1. Set the locale and keyboard layout.
1. Enable SSH, pub-key auth only, and preload my SSH pubkey.
1. Under options, untick the "Enable Telemetry" box.

Then proceed with the installation.

Once installed, ssh in with the correct key and apply updates.

    sudo apt update
    sudo apt dist-upgrade
    sudo shutdown -r now

### System setup

1. Edit `/etc/ssh/sshd_config` and:

   1. Set `PermitRootLogin` to `no`.
   1. Set `PasswordAuthentication` to `no`.
   1. Then restart ssh:

          sudo service ssh restart

1. Install and config basic things

    1. Deps

           sudo apt install wiringpi rpi.gpio-common

    1. Config

        1. Create `/etc/udev/rules.d/99-gpiomem.rules` as follows, to set the
           permissions properly. Note that this follows the Ubuntu standard of
           using the `dialout` group rather than the RPi OS standard `gpio`
           group.

               KERNEL=="gpiomem", GROUP="dialout", MODE="0660"

    1. Reboot so the udev rule takes effect.

1. Install NodeRed:

    Ref: <https://nodered.org/docs/getting-started/raspberrypi>

    Basically, there is a script which you download and will autodetect things and do all the magic, as well as handling updates. Since this is effectively a single-use machine, we'll install NodeRed using our user, which is also the user at which it will run.

    1. Install script dependencies:

           sudo apt install build-essential git curl

    1. Run the script (this works for updates too)

        **Important:** If you don't just want to blindly run it, download it, read it, then run it (I did).

           curl -sL https://github.com/node-red/linux-installers/releases/latest/download/update-nodejs-and-nodered-deb > update-nodejs-and-nodered-deb
           chmod u+x update-nodejs-and-nodered-deb
           ./update-nodejs-and-nodered-deb --nodered-user=$USER --confirm-pi

        This will do some work, and ask some questions. Answer as follows:

        - **Settings file:** Accept default (just hit enter)
        - **Telemetry:** Yes
        - **User security:** No. (We'll do this later via apache)
        - **Projects feature:** No.
            - This looks pretty slick though. Needs research
        - **Flows file:** Accept defaults.
        - **Passphrase for credentials file:** Use the one in keepass.
        - **Theme:** Default
        - **Text editor component:** Default
        - **functionExternalModules:** Yes

    1. Edit the NodeRed config file (`/home/alice/.node-red/settings.js`), and
       make the following changes:

        1. Uncomment the `uiHost: "127.0.0.1",` so it only listens on localhost
           (the rest is handled by the Apache proxy, above).

        1. Set `httpRoot: '/nodered',`. This can go right at the top of the `module.exports` section.

    1. Add some necessary components:

           cd ~/.node-red
           npm install node-red-dashboard node-red-node-email node-red-node-openweathermap node-red-contrib-config node-red-contrib-msg-resend @flowfuse/node-red-dashboard

    1. Start it, including on boot

           sudo systemctl enable nodered.service
           sudo systemctl start nodered.service

1. Set up Apache / etc.

    1. Install necessary dependencies:

           sudo apt install apache2 libapache2-mod-authnz-external

    1. Generate a PEM cert/key pair via your favorite method and put them in a
      useful place. The config below assumes they will be in `/etc/ssl/private`
      and be called `apache.pem` and `apache.key`. If you're doing something
      selfsigned, do it at a long interval, like, say, 5 years. Or use
      letsencrypt. Ownership should be root:ssl-cert with mode 640.

    1. Create `/etc/apache2/sites-available/stairs.conf` as follows:

           <VirtualHost _default_:80>
               ServerName stairs
               ServerAdmin matt@mattcaron.net

               # Redirect common paths to https.
               Redirect permanent /nodered  https://newstairs/nodered
               Redirect permanent / https://newstairs/nodered/dashboard
           </VirtualHost>

           <VirtualHost _default_:443>
               ServerName stairs
               ServerAdmin matt@mattcaron.net

               SSLEngine on
               SSLCertificateFile    /etc/ssl/private/crt
               SSLCertificateKeyFile /etc/ssl/private/key

               # Standard SSL protocol adustments for IE

               BrowserMatch "MSIE [2-6]" \
                            nokeepalive ssl-unclean-shutdown \
                            downgrade-1.0 force-response-1.0
               BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

               AddExternalAuth pwauth /usr/sbin/pwauth
               SetExternalAuthMethod pwauth pipe

               # Allow unauthenticated access to the dashboard for convenience.
               <Location "/nodered/dashboard">
                   Order deny,allow
                   Allow from all
                   Satisfy any
               </Location>
 
               # Require authentication to the editor.
               # This uses local account credentials.
               <Location "/nodered">
                   AuthType Basic
                   AuthName "Login"
                   AuthBasicProvider external
                   AuthExternal pwauth
                   Require valid-user
               </Location>

               SSLProxyEngine On
               ProxyPreserveHost On
               ProxyRequests Off

               # Redirect / to the UI
               Redirect permanent / <https://newstairs/nodered/dashboard>

               # Core NodeRed proxy config.
               ProxyPass /nodered/comms  ws://localhost:1880/nodered/comms
               ProxyPass /nodered/comms <http://localhost:1880/nodered/comms>
               ProxyPassReverse /nodered/comms <http://localhost:1880/nodered/comms>
               ProxyPass /nodered <http://localhost:1880/nodered>
               ProxyPassReverse /nodered <http://localhost:1880/nodered>

               # NodeRed UI proxy config.
               ProxyPass /nodered/dashboard <http://localhost:1880/nodered/dashboard>
               ProxyPassReverse /nodered/dashboard <http://localhost:1880/nodered/dashboard>

               # Hack - for some reason, it tries to get the favicon from /dashboard,
               # not /nodered/dashboard. This fixes that issue.
               ProxyPass /dashboard <http://localhost:1880/nodered/dashboard>
               ProxyPassReverse /dashboard <http://localhost:1880/nodered/dashboard>

           </VirtualHost>

    1. Spin everything up:

           sudo a2ensite stairs
           sudo a2dissite 000-default
           sudo a2enmod ssl authnz_external proxy proxy_http proxy_wstunnel
           sudo systemctl restart apache2
