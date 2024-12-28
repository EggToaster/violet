# Violet
In-development package manager on Lua, meant to work accross every OSes

# FAQ
Q: How to make repositories?
A: TODO

Q: Is dependencies supported?
A: Should be, but it is not tested yet(On old CC-only violet), and does not support tree/nested deps 

Q: Is it possible to make a package that just downloads pastebin data?(CC related)
A: Yes, because install script is supported. But, this is a bad approach, you should instead make a script that pulls files from pastebin on server. The code will NEVER be provided, do not ask.

Q: Where is the Violet config/data stored at?
A: /var/violet. Can be changed with --cfgdir flag.

Q: How to modify install directory?
A: --installdir. Can be specified in config to avoid mistakes.
