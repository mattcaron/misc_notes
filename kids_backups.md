# Setting up backups for the kids' computers

## Abstract

This config is to back up the kids' Edubuntu machines in a simple, secure and noninvasive way.

Two-way sync is not required, it's just a one way push from their machine to the server.

**This is not self service restore**, at least not using these keys. I mean, you could probably do it, but it's not very ergonomic, especially since the accounts are locked. If they need a file back, they ask me, I'll put it on a USB stick for them, and we're on our way again.

## Instructions

1. Make accounts on the server for them. They should likely be locked because they don't need password logins - just rsync over ssh via keys.

1. **Make sure to make the backups subdirs in the home directories** Otherwise, `rrsync` will complain about the directory not existing.

1. Install `grsync`

       sudo apt install grsync

1. Generate a backup keypair

   When prompted, do not set a passphrase. This is less secure, but easier for automated operation. Also, what it can do is very restricted.

       ssh-keygen -t rsa -f ~/.ssh/id_rsa_backup

1. Sneakernet the `id_rsa_backup.pub` key into that individual account's `authorized keys`, with the following command limiter in front of it:

       command="/bin/rrsync /home/matt/backups/"

    Note that this limits the use of that key to rsync in that directory, and all commands must be rooted accordingly.

1. Create a `grsync` profile like this (called, say `matt.grsync`)

        [backup]
        is_set=false
        text_source=/home/matt
        text_dest=jarvis:matt-laptop
        text_notes=
        text_com_before=
        text_com_after=
        text_addit=--rsh="ssh -o ControlMaster=no -i /home/matt/.ssh/id_rsa_backup -l matt"
        check_time=true
        check_perm=true
        check_owner=true
        check_group=true
        check_onefs=false
        check_verbose=true
        check_progr=true
        check_delete=true
        check_exist=false
        check_size=false
        check_skipnew=false
        check_windows=false
        check_sum=false
        check_symlink=true
        check_hardlink=false
        check_dev=false
        check_update=false
        check_keepart=false
        check_mapuser=false
        check_compr=true
        check_backup=false
        check_itemized=false
        check_norecur=false
        check_protectargs=false
        check_com_before=false
        check_com_halt=false
        check_com_after=false
        check_com_onerror=false
        check_browse_files=false
        check_superuser=false

1. Open `grsync` and import the above profile. It will go in as "backup" and, from then on, the kids can just run it by starting the app and pressing the green arrow to "go". They'll get a progress indicator and an overall indicator of success or failure.
