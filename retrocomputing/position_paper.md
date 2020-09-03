# Disposition of games by system

**Note**: This just applies to classic games. Modern games (Steam, etc.) are run on the laptop or, if it isn't powerful enough, my desktop.

## MiSTer

### Contents

Anything that is supported including, but not limited to:

- Apple II
- 486
    - This is experimental, we'll see how well it works. If it works well, Dosbian might be redundant.
- NES
- SNES
- Genesis
- NeoGeo
- ScummVM
- Various Arcade cores

### Rationale

1. Faithful reproduction of the above on original.
    1. This nominally applies to 486's as well, because the OS would (generally)
       let the program basically completely take over, unless it had installed
       itself to do stuff on an interrupt (like the mouse driver).
1. ScummVM could do either on MiSTer or Dosbian, but the theory is that Dosbian
   will eventually be rendered obsolete.

## RetroPi

### Contents

Emulation of any of the consoles / arcade systems not supported by the above:

- N64
- Playstations
- MAME stuff

### Rationale

I want a faithful reproduction, but MiSTer doesn't (can't?) do those things yet. This is the stopgap.

### Notes

I will put all the ROMs I have on this system, so we can do a Pepsi challenge with the emulators, or to test functionality in case someone else needs help building such box.

## Dosbian

### Contents

Pretty much all the DOS stuff until MiSTer's AO486 core is good enough to run
it all.

### Rationale

Dedicated box emulation is better than not working at all...

## Laptop

### Contents

Everything else.

### Rationale

Anything not covered above is run on Linux under emulation, as they are designed to be run under a real OS and whatnot, so the latency won't be a huge issue, as everything now is better than what they had back in the day..