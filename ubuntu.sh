#!/bin/bash

. "util/logging.sh"
. "util/try-catch.sh"

info "We're inside of Ubuntu! Starting the patching process..."
sleep 1

info "Installing Java..."
try {
  apt update
  apt upgrade
  apt install openjdk-8-jre-headless
} catch {
  error "installing OpenJDK 8 JRE"
  exit 17
}

info "Downloading smali/baksmali and Magisk's update-binary"
try {
  curl -Lo smali.jar "https://bitbucket.org/JesusFreke/smali/downloads/smali-2.5.2.jar"
  curl -Lo baksmali.jar "https://bitbucket.org/JesusFreke/smali/downloads/baksmali-2.5.2.jar"
  curl -Lo update-binary "https://raw.githubusercontent.com/topjohnwu/Magisk/master/scripts/module_installer.sh"
} catch {
  error "downloading required tools"
  exit 18
}

info "Fetching services.jar..."
try {
  cp "/system/framework/services.jar" "."
} catch {
  error "copying /system/framework/services.jar"
  exit 19
}

info "Unzipping services.jar..."
try {
  unzip "services.jar" 
} catch {
  error "unzipping services.jar"
  exit 20
}

info "Baksmaling classes*.dex..."
try {
  for dex in $(ls classes*.dex); do
    java -Xmx500M -jar baksmali.jar d -j 12 $dex -o ${dex%.dex}
  done
} catch {
  error "baksmaling classes*.dex"
  exit 21
}

req_file=""
req_bool="setIsFromMockProvider"

info "Finding the required file..."
try {
  req_file="$(find classes* -name 'MockProvider.smali')"
  if [[ -z "${req_file}" ]]; then
    exit ${RANDOM}
  fi
} catch {
  error "finding the required file"
  exit 22
}

lines=()

info "Preparing for patch..."
try {
  mapfile -t lines < "${req_file}"
} catch {
  error "preparing for patching"
  exit 23
}

info "Checking if ${req_bool} is already patched..."
try {
  for idx in "${!lines[@]}"; do
    if [[ "${lines[idx]}" == *"${req_bool}"* ]]; then
      line=$(printf '%s\n' "${lines[@]:0:idx}" | grep "0x0")
      [[ "${line}" == *"0x0"* ]] && exit ${RANDOM}
    fi
    break
  done
} catch {
  info "${req_bool} is already patched! Exitting..."
  exit 0
}

info "Patching the required file..."
try {
  for idx in "${!lines[@]}"; do
    if [[ "${lines[idx]}" == *"${req_bool}"* ]]; then
      req_line=$(printf '%s\n' "${lines[@]:0:idx}" | grep -q "0x1")
      req_idx=$idx
      break
    fi
  done

  mod_line="$(echo "${req_line}" | sed 's/0x1/0x0/g')"
  lines[$req_idx]="${mod_line}"
  printf "%s\n" "${lines[@]}" > "${req_file}"
} catch {
  error "patching ${req_bool} defined at ${req_file}"
  exit 24
}

info "Re-smaling to classes*.dex..."
try {
  rm -f classes*.dex
  for smalidir in "classes*"; do
    java -Xmx500M -jar smali.jar a -j 12 $smalidir -o "${smalidir}.dex"
  done
} catch {
  error "smaling classes folder back to classes.dex"
  exit 25
}

info "Zipping everything back to services.jar..."
try { 
  zip services.jar classes*.dex
} catch {
  error "zipping the files to services.jar"
  exit 26
}

info "Creating a Magisk module..."
try {
  mkdir -p module/META-INF/com/google/android
  cd module
  mv ../update-binary META-INF/com/google/android
  echo "#MAGISK" > META-INF/com/google/android/updater-script
  cat <<EOF >> module.prop
name=Hide Mock Locations
id=hidemocklocations
version=v1
versionCode=1
description=Hide mock location updates from apps that detect them like Pokemon GO.
author=Me!
EOF
  mkdir -p system/framework
  mv ../services.jar system/framework
  zip -r HML.zip META-INF system module.prop
  mv HML.zip ../
  cd ../
} catch {
  error "creating the Magisk module"
  exit 27
}

success "All done! Exiting Ubuntu..."
exit 0
