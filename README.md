<p align="center"> <b>CURRENT RELEASE:</b> 1.1.2  <b>Read the <a href="LEGACY.md">changelog</a> here!</b> </p>

<h3> <!-- im jsut doing bulls hit help me -->
	<p align="center">
		Download in 
		<a href="https://gamejolt.com/games/vsimpostor/643430">
			<img src="https://s.gjcdn.net/img/favicon.png" width="16"/>
			GameJolt
		</a>
		 or 
		<a href='https://gamebanana.com/mods/55652'>
			<img src="https://images.gamebanana.com/static/img/favicon/32x32.png" width="16"/>
			GameBanana!
		</a>
	</p>
</h3>

<br>

[![VS IMPOSTOR](https://files.gamebanana.com/img/ss/mods/69ecfeb268eec.jpg)](https://vsimpostor.com)

<br> <br>

A from-the-ground-up remaster of the 2023 mod, **VS IMPOSTOR V4**!<br>
**VS IMPOSTOR: LEGACY** intends to be faithful to the original experience, while introducing new tweaks and features to make it the definitive version of the mod you know and love!

A total-conversion mod for **Friday Night Funkin'**, in which you face off against colorful Among Us characters, in over 10 weeks and 57 songs!<br>
This mod has plenty of content for you to explore, especially with brand-new awards and cosmetics for you to find and collect! And who knows? maybe there are more secrets to discover...

<br> <br>

<p align="center">
	<a href="https://github.com/NMVTeam/NightmareVision">
		<img src="assets/legacy/images/branding/UpdogBlack.png" alt="Made with NightmareVision Engine" width="325"/>
	</a>
</p>

<br> <br>

## Compiling

### Prerequisites

(You can skip this if you already have compiled any fnf or flixel project)

- [Git](https://git-scm.com/downloads)
- [Haxe](https://haxe.org/download/)
	- 4.3.6 or newer is expected!

### Additional platform setup
(excerpts from [Funkin compiling documentation](https://github.com/FunkinCrew/Funkin/blob/main/docs/COMPILING.md))
- If you're compiling for Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe).
	- When prompted, select "Individual Components" and make sure to download the following:
        - MSVC v143 VS 2022 C++ x64/x86 build tools
        - Windows 10/11 SDK
- For Mac, read the [macOS setup Lime documentation](https://lime.openfl.org/docs/advanced-setup/macos/).
- For Linux, read the [Linux setup Lime documentation](https://lime.openfl.org/docs/advanced-setup/linux/) first.
	- Hxvlc uses libVLC, which requires you to install some development packages to be able to compile.<br>
	For Ubuntu/Debian based systems, you can execute `sudo apt install libvlc-dev libvlccore-dev libvlccore9`.<br>For other distros, please refer to [Hxvlc's documentation](https://github.com/MAJigsaw77/hxvlc?tab=readme-ov-file#dependencies).

### Installing libraries

> [!TIP]  
> Actually, you can run [this file](projFiles/SETUP.bat) to handle library setup automatically!

> [!NOTE]
> This engine **enforces** the use of local libraries with hxpkg to prevent issues in relation to Hxvlc.<br>
> The expected library versions are listed within the .hxpkg file.
>
> If any compilation errors arise, ensure your Haxe version is correct and your libraries match those expected versions.

Open a Command Prompt within the project directory and run the following commands...

```cmd
haxelib install hxpkg
haxelib run hxpkg setup
haxelib run hxpkg install
```

You should be able to run `lime test cpp` to start compiling the game now!

- You can include `-D ASSET_REDIRECT` in the command for ingame assets to update as they're changed in the `assets` folder.<br>
	(Do **not** include this command if you're making a release build)

	Otherwise, to compile with the Security DLC in the export assets folder, include the command `-D DLC` when building!!

<br>

## Special Thanks

- ShadowMario and Co. for [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine)
- Nebula_Zorua for the Modchart backend and the [Psych Engine fork](https://github.com/nebulazorua/exe-psych-fork) NMV is built off
- Rozebud for the chart editor little buddies ([Check out FPS Plus too](https://github.com/ThatRozebudDude/FPS-Plus-Public))
- MaybeMaru for [MoonChart](https://github.com/MaybeMaru/moonchart) and [Flixel-animate](https://github.com/MaybeMaru/flixel-animate)
