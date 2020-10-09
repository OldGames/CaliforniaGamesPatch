# "California Games" TSR Patch
TSR to fix a bug in Epyx's California Games

"California Games" sometimes has the following bug: 
> When choosing to compete in one, more or all events, a screen to enter the players' names appears. However, the games is locked up and it isn't possible to enter any name.

This is a TSR patch to resolve the issue.

The patch hooks INT21/25 and waits for game to try and hook INT16. It then saves the game's INT16 location and doesn't really allow the hook.
In parallel, patch hooks INT16, and if 0x10<=AH<=0x12, turns AH to 0x0/0x1/0x2 respectively, and calls the game's intended INT16.

See [here](http://www.vogons.org/viewtopic.php?t=12251) for more information and other solutions.
