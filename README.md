# HideMockLocations

## What?
This is a collection of scripts that allows your **rooted Android device** to get its services.jar patched so that you can get rid of annoying errors while spoofing your locations, on apps like Pokémon GO.

## Why?
A long story, really. First, I discovered a thing called [Smali Patcher](https://forum.xda-developers.com/t/module-smali-patcher-7-3.3680053), which allows you to do what this does, and much more. I have even used it many times to patch a few devices, but when the turn for another device came, my computer didn't boot up and went for repairs, and so, I couldn't patch my device.

Then, I discovered the [Smali Patcher Port by J. Fronny on GitLab](https://gitlab.com/JFronny/smalipatcher), which supported running on native Android. I tried it, and it didn't work, and I had no idea why. Thankfully, it was open-source, so I read deep into that and I found that it is quite possible to patch it manually.

And that's how this emerged. I made a script to run on native Android using [Termux](https://f-droid.org/packages/com.termux), with some nice goodies, too!

## How?
### Strategy
1. In Termux, first, the package [proot-distro](https://github.com/termux/proot-distro) is installed, which allows to install Ubuntu (and many other Linux Distros).
2. A script is written to the .bashrc file inside of the rootfs of Ubuntu.
3. Ubuntu is started up, and since the .bashrc file runs in Bash first, ultimately, we start the patching process.
4. Inside of Ubuntu, OpenJDK 8 JRE (Headless) is installled.
5. The required tools, [smali/baksmali](https://github.com/JesusFreke/smali) and [update-binary](https://github.com/topjohnwu/Magisk/blob/master/scripts/module_installer.sh) for [Magisk](https://github.com/topjohnwu/Magisk), are downloaded.
6. The baksmali.jar tool is run on all classes\*.dex files to get us the raw smali files for the required patching.
7. There exists a file named MockProvider.smali inside <baksmali_output_folder>/com/android/server/location. Inside of it, a boolean is defined named "setIsFromMockProvider", which is set to true by default so that the apps can detect if the location is being faked. If it will be set to false, apps would think that the mock location updates are, in fact, real location updates.
8. The name "setIsFromMockProvider" is searched for in the file. Then, a line which contains "0x1" _directly before_ the line where the boolean is defined, is searched for. Before this, it it also checked whether the file is already patched.
9. If the file is already patched, exit with no errors. If not, the required line is changed so that it contains "0x0" (false) instead of "0x1" (true).
10. The baksmali output folder is recompiled using smali.jar. Since we have modified the file, the recompilation will occur on the patched files.
11. The unzipped files are zipped back to services.jar, **with the modified dex files**.
12. Finally, a Magisk module is created conforming to [this format](https://topjohnwu.github.io/Magisk/guides.html).
13. The user is asked for granting storage permissions so that the Magisk module can be moved to the Internal Storage.
14. The Magisk module is moved to Internal Storage. Additionally, if the user wishes to, the Termux app is cleaned up so that it does not consume storage space.
15. That's it! Install the module, reboot, and voila!

### Usage
Install [Termux](https://f-droid.org/packages/com.termux), open it, and paste the following commands, and press enter:

```sh
mkdir hml && cd hml
curl -Lo start "https://raw.githubusercontent.com/shrihanDev/hml/master/start.sh"
chmod +x start
./start
```
Let it do its work. It will ask for confirmations on some things, please do it!

~~NOTE: Only works on Android 10 and below!! Android 11 causes bootloops!~~ Fixed now.

## Help! My device doesn't turn on!
To rescue a bootlooped device, first hard shut down the device. If the device has a removable battery, remove it and put it on again. If it doesn't, you need to hold the power button for 20 to 25 seconds. If that doesn't work, your best bet will be to make it bootloop until the battery is completely discharged, and plug it in. After it is done, do either of the following:
1. The best way to do it is to boot into TWRP or any custom recovery and delete the folder **/data/adb/modules/hidemocklocations**, either from `adb shell` or built-in terminal or built-in file manager.
2. If you do not have TWRP, you can try to boot into safe mode by using a special key combo, which greatly varies from device-to-device. Google: (device model) safe mode key combo. This disables Magisk, and then you can uninstall Magisk app from Settings. Then, reboot and re-install Magisk and remove the module.
3. Finally, if none of the above is possible, you need to flash the stock ROM or whatever custom ROM you are using, using `fastboot` (ODIN for Samsung) or custom recovery. Note that this option has to be treated as the last resort.
