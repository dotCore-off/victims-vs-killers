# 🔪 Victims vs Killers
A fun asymetric gamemode for Garry's Mod where Victims must run away and survive from Killers!

# ☄️ Features
- **Highly configurable** *(~500 lines config file)*
- **Optimized** and **consistent** code quality
- **Customizable classes:** Killer & Victim
- **Modular gameplay:** control Taunts, Bhop, Sliding & more on the go!
- **Implement your own variations** to the gamemode through **special rounds**
- **Extra protections** that any server owner wants
- **Lightweight source code** *(~47Ko!)*

# 📦 How to install
1. [Download latest release here](https://github.com/dotCore-off/victims-vs-killers/releases)
2. **Unzip** and **put into your** `gamemodes` folder
3. **Subscribe** or **add** [gamemode base content](https://steamcommunity.com/sharedfiles/filedetails/?id=2889600027) to your server collection
4. **Configure** to your likings using ``sh_config.lua`` file
5. **Enjoy this long awaited gamemode!**

# ⚙️ Dependencies
### 🔊 For taunts
Since native `SoundDuration` doesn't return the proper length of an audio file, you must install the following module:
> https://github.com/yobson1/glua-soundduration

``Note: without it, gamemode is using a static value for taunt rewards.``

### ⭕️ For Halos
They eat hell a lot of performance, so to make it a bit smoother, we're using a custom outline library:
> https://github.com/Facepunch/garrysmod/pull/1590/files

``Note: without it, gamemode is using native Garry's Mod halo.``

# ✔️ Contributions
To contribute, you can:
- **Star this repository** or **follow me on GitHub** :)
- [Open an issue]() and **fill the report form** correctly
- [Fork the repository](https://github.com/dotCore-off/victims-vs-killers/fork), **improve code or add a feature** and then, [create a new pull request](https://github.com/dotCore-off/victims-vs-killers/compare)
> Please, **follow the code syntax** to keep it consistent

# ⚠️ Disclaimer
This is a rewrite of a gamemode originally created for [a private purpose](https://gmod.waurum.net/).
That being said, the code can:
- be yoinky sometimes as it has been written over time
- contain old parts related to private usage
- not be instinctive for newcomers

I'll do my best to correct that within the next months, but your contributions are welcomed.
