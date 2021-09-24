#!/data/data/com.termux/files/usr/bin/bash

script_dir="$( dirname $(realpath $0) )"
ubuntu_bashrc="${PREFIX}/var/lib/proot-distro/installed-rootfs/ubuntu/root/.bashrc"

. "${script_dir}/util/logging.sh"
. "${script_dir}/util/try-catch.sh"

info "HideMockLocations - A simple script that patches services.jar so that the mock locations updates can be treated as genuine location updates, thereby preventing the apps in question to detect them, like Pokèmon GO."
try {
  conf "Ready?"
} catch {
  error "Denied execution - Aborted" "n"
  exit 1
}
success "Starting now!"
echo

info "#1 Installing Ubuntu inside of Termux..."
try {
  pkg install proot-distro
  proot-distro install "ubuntu"
} catch {
  error "installing Ubuntu 20.04"
  exit 1
}

info "#2 Writing a script to run inside Ubuntu..."
try {
  cat "${script_dir}/ubuntu.sh" > "${ubuntu_bashrc}"
  echo "logout" >> "${ubuntu_bashrc}"
  cp -rf "${script_dir}/util" "$(dirname "${ubuntu_bashrc}")"
} catch {
  error "writing the script"
  exit 2
}

info "#3 Logging into Ubuntu for the REAL stuff..."
{
  proot-distro login 'ubuntu'
} || {
  error "logging in to Ubuntu for the patching process"
  exit 3
}

try {
  conf "You need to grant Termux storage permissions so that the generated Magisk module can be moved to your Internal Storage. Please allow it. Additionally, if a message about overwriting ~/storage appears, please enter 'y'. Ready?"
} catch {
  error "Did not permit asking for storage permissions. Aborted" "n"
  exit 4
}

try {
  termux-setup-storage
} catch {
  error "Did not permit storage permissions. Aborted" "n"
  exit 5
}

try {
  conf "Ready?"
} catch {
  error "Did not confirm permitting storage. Aborted." "n"
  exit 6
}

info "#4 Moving the module to your internal storage..."
try {
  mv -f "$(dirname "${ubuntu_bashrc}")/HML.zip" "/sdcard/"
} catch {
  error "moving the generated Magisk module to Internal Storage"
  exit 7
}

success "Completed!"
success "The generated Magisk module is moved into the root of the Internal storage. Please open Magisk app and install it, reboot, and voila! You've successfully patched the services.jar! Enjoy!"

try {
  conf "Do you want to optionally clean up the files generated during the process (so that the storage is not filled up)?"
} catch {
  info "Okay. So, it's all done."
  exit 0
}

info "[Optional] #5 Cleaning up Termux..."
try {
  proot-distro remove ubuntu
  pkg uninstall proot-distro -y
  apt autoremove
} catch {
  info "Failed to clean up. Guess we've to exit..."
  info "It is recommended to create an issue in the GitHub project, with some of the logs from above."
  exit 0
}

success "Completed cleaning up system. The last step for the cleanup is to uninstall Termux if you do not require it."
success "Regards!"
exit 0
