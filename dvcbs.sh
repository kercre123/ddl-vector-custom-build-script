#!/bin/bash

#resources folder
refo=resources

#scpip
scpip=

#scpkey
scpkey=

#otafolderatscp
otafolder=

function help()
{
   echo "-h         This message"
   echo "-f {dir} {versionbase} {versioncode} {scp}  this mounts OTA, copys over versionbase, versioncode, new update-engine, and prod server config, then builds"
   echo "-m {dir}   mount latest.ota"
   echo "-b {dir} {versionbase} {versioncode} {scp}   build apq8009-robot-sysfs.img"
   echo "-bf {dir} {versionbase} {versioncode} {scp}  copy over versionbase, versioncode, new update-engine, and prod server config then build"
   echo "-t {dir}   mount, copy over prod server config, build. used for testing older firmware and new ones from ddl"
   echo "-mb {dir} {versionbase} {versioncode}   only mounts then builds. used for testing super old firmware"
   exit 0
}

trap ctrl_c INT                                                                 
                                                                                
function ctrl_c() {
    echo -e "\n\nStopping"
    exit 1 
}

function copyfull()
{
  echo "Copying files over"
  sudo cp ${refo}/update-engine ${dir}edits/anki/bin/
  sudo cp ${refo}/server_config.json ${dir}edits/anki/data/assets/cozmo_resources/config/
  sudo rm ${dir}edits/anki/etc/version
  sudo rm ${dir}edits/etc/os-version
  sudo rm ${dir}edits/etc/os-version-base
  sudo rm ${dir}edits/etc/os-version-code
  sudo rm ${dir}edits/build.prop
  sudo cp ${refo}/build.prop ${dir}edits/
  sudo sed -i -e 's/ro.anki.version=/ro.anki.version='${base}'.'${code}'d/g' ${dir}edits/build.prop
  sudo sed -i -e 's/ro.anki.victor.version=/ro.anki.victor.version='${base}'.'${code}'/g' ${dir}edits/build.prop
  sudo sed -i -e 's/ro.build.fingerprint=/ro.build.fingerprint='${base}'.'${code}'d/g' ${dir}edits/build.prop
  sudo sed -i -e 's/ro.build.id=/ro.build.id='${base}'.'${code}'d/g' ${dir}edits/build.prop
  sudo sed -i -e 's/ro.build.display.id=/ro.build.display.id=Wire_build'${code}'/g' ${dir}edits/build.prop
  sudo sed -i -e 's/ro.build.version.incremental=/ro.build.version.incremental='${code}'/g' ${dir}edits/build.prop
  sudo printf '%s\n' ${base}'.'${code} >${dir}edits/anki/etc/version
  sudo printf '%s\n' ${base}'.'${code}'d' >${dir}edits/etc/os-version
  sudo printf '%s\n' ${base} >${dir}edits/etc/os-version-base
  sudo printf '%s\n' ${code} >${dir}edits/etc/os-version-code
}

function copytest()
{
#some versions have a different server config, so i am doing sed
  echo "Switching env from dev to prod"
  sudo sed -i -e 's/xiepae8Ach2eequiphee4U/oDoa0quieSeir6goowai7f/g' ${dir}edits/anki/data/assets/cozmo_resources/config/server_config.json
  sudo sed -i -e 's/chipper-dev.api.anki.com:443/chipper.api.anki.com:443/g' ${dir}edits/anki/data/assets/cozmo_resources/config/server_config.json
  sudo sed -i -e 's/token-dev.api.anki.com:443/token.api.anki.com:443/g' ${dir}edits/anki/data/assets/cozmo_resources/config/server_config.json
  sudo sed -i -e 's/jdocs-dev.api.anki.com:443/jdocs.api.anki.com:443/g' ${dir}edits/anki/data/assets/cozmo_resources/config/server_config.json
#maybe TODO : some versions also have different das events in update-engine so ill also do sed here (itll take so lonnnngggnn a)
 
}

function mount()
{
  echo "Mounting OTA in $dir!"
  sudo mv ${dir}latest.ota ${dir}latest.tar
  sudo tar -xf ${dir}latest.tar --directory ${dir}
  sudo mkdir ${dir}edits
  sudo mkdir ${dir}originalimg
  echo "Decrypting"
  sudo openssl enc -d -aes-256-ctr -pass file:${refo}/ota.pas -md md5 -in ${dir}apq8009-robot-sysfs.img.gz -out ${dir}apq8009-robot-sysfs.img.dec.gz
  echo "Decompressing. This may take a minute."
  sudo gzip -d ${dir}apq8009-robot-sysfs.img.dec.gz
  echo "Rename img.dec to mountable img"
  sudo mv ${dir}apq8009-robot-sysfs.img.dec ${dir}apq8009-robot-sysfs.img
  echo "Copying original sysfs img to temp for manifest stuff"
  sudo cp ${dir}apq8009-robot-sysfs.img ${dir}originalimg/apq8009-robot-sysfs.img
  echo "Mounting IMG"
  sudo mount -o loop,rw,sync ${dir}apq8009-robot-sysfs.img ${dir}edits
  echo "Deleting GZ file for build function to work"
  sudo rm ${dir}apq8009-robot-sysfs.img.gz
}

function buildtest()
{
  echo "Compressing. This may take a minute."
  sudo gzip -k ${dir}apq8009-robot-sysfs.img
  sudo mkdir ${dir}final
  echo "Encrypting sysfs"
  sudo openssl enc -e -aes-256-ctr -pass file:${refo}/ota.pas -md md5 -in ${dir}apq8009-robot-sysfs.img.gz -out ${dir}final/apq8009-robot-sysfs.img.dec.gz
  sudo mv ${dir}final/apq8009-robot-sysfs.img.dec.gz ${dir}final/apq8009-robot-sysfs.img.gz
  sudo mv ${dir}apq8009-robot-boot.img.gz ${dir}final/apq8009-robot-boot.img.gz
  sudo mv ${dir}manifest.ini ${dir}final/manifest.ini
  echo "Unmounting"
  sudo umount ${dir}edits
  echo "Finding SHA256 sum and putting it into manifest."
  editedsysfssum=$(sha256sum ${dir}apq8009-robot-sysfs.img | head -c 64)
  origsysfssum=$(sha256sum ${dir}originalimg/apq8009-robot-sysfs.img | head -c 64)
  sudo sed -i -e 's/'${origsysfssum}'/'${editedsysfssum}'/g' ${dir}final/manifest.ini
  echo "Putting into tar."
  sudo tar -C ${dir}final -cvf ${dir}final/temp.tar manifest.ini
  sudo tar -C ${dir}final -rf ${dir}final/temp.tar apq8009-robot-boot.img.gz
  sudo tar -C ${dir}final -rf ${dir}final/temp.tar apq8009-robot-sysfs.img.gz
  sudo mv ${dir}final/temp.tar ${dir}final/latest.ota
  echo "Removing some temp files."
  sudo rmdir ${dir}edits
  sudo rm ${dir}apq8009-robot-sysfs.img.gz
  sudo rm ${dir}final/apq8009-robot-sysfs.img.gz
  sudo rm ${dir}final/apq8009-robot-boot.img.gz
  sudo rm ${dir}originalimg/apq8009-robot-sysfs.img
  sudo rmdir ${dir}originalimg
  echo "Renaming original OTA back to OTA"
  sudo mv ${dir}latest.tar ${dir}latest.ota
  echo "Done! Output should be in ${dir}final/latest.ota!"
  sudo rm ${dir}manifest.sha256
}


function buildcustom()
{
  echo "Compressing. This may take a minute."
  sudo gzip -k ${dir}apq8009-robot-sysfs.img
  sudo mkdir ${dir}final
  sudo openssl enc -e -aes-256-ctr -pass file:${refo}/ota.pas -md md5 -in ${dir}apq8009-robot-sysfs.img.gz -out ${dir}final/apq8009-robot-sysfs.img.dec.gz
  sudo mv ${dir}final/apq8009-robot-sysfs.img.dec.gz ${dir}/final/apq8009-robot-sysfs.img.gz
  sudo umount ${dir}edits
  echo "Figuring out SHA256 sum and putting it into manifest."
  sysfssum=$(sha256sum ${dir}apq8009-robot-sysfs.img | head -c 64)
  sudo printf '%s\n' '[META]' 'manifest_version=1.0.0' 'update_version='${base}'.'${code}'d' 'ankidev=1' 'num_images=2' '[BOOT]' 'encryption=1' 'delta=0' 'compression=gz' 'wbits=31' 'bytes=13795328' 'sha256='${bootsum} '[SYSTEM]' 'encryption=1' 'delta=0' 'compression=gz' 'wbits=31' 'bytes=608743424' 'sha256='${sysfssum} >${refo}/manifest.ini
  echo "Putting into tar."
  sudo tar -C ${refo} -cvf ${refo}/temp.tar manifest.ini
  sudo tar -C ${refo} -rf ${refo}/temp.tar apq8009-robot-boot.img.gz
  sudo cp ${refo}/temp.tar ${dir}final/
  sudo tar -C ${dir}final -rf ${dir}final/temp.tar apq8009-robot-sysfs.img.gz
  sudo mv ${dir}final/temp.tar ${dir}final/${base}.${code}.ota
  echo "Removing some temp files."
  sudo rmdir ${dir}edits
  sudo rm ${dir}apq8009-robot-sysfs.img.gz
  sudo rm ${dir}apq8009-robot-boot.img.gz
  sudo rm ${dir}manifest.ini
  sudo rm ${dir}final/apq8009-robot-sysfs.img.gz
  sudo rm ${refo}/manifest.ini
  sudo rm ${refo}/temp.tar
  echo "Renaming original OTA back to OTA"
  sudo mv ${dir}latest.tar ${dir}${base}.${code}.ota
  echo "Done! Output should be in ${dir}final/latest.ota!"
}

function scptoserver()
{
  case $scpyn in
       stable)
   sudo scp -i ${scpkey} ${dir}final/${base}.${code}.ota root@${scpip}:/var/www/${otafolder}/stable/
   sudo ssh -i ${scpkey} root@${scpip} "rm /var/www/${otafolder}/stable/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "ln -s /var/www/${otafolder}/stable/${base}.${code}.ota /var/www/${otafolder}/stable/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "rm /var/www/${otafolder}/stable/full/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "ln -s /var/www/html/stable/${base}.${code}.ota /var/www/${otafolder}/stable/full/latest.ota"
   ;;
       unstable)
   sudo scp -i ${scpkey} ${dir}final/${base}.${code}.ota root@${scpip}:/var/www/${otafolder}/unstable/
   sudo ssh -i ${scpkey} root@${scpip} "rm /var/www/${otafolder}/stable/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "ln -s /var/www/${otafolder}/unstable/${base}.${code}.ota /var/www/${otafolder}/unstable/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "rm /var/www/${otafolder}/unstable/full/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "ln -s /var/www/html/unstable/${base}.${code}.ota /var/www/${otafolder}/unstable/full/latest.ota"
   ;;
       sign)
   sudo scp -i ${scpkey} ${dir}final/${base}.${code}.ota root@${scpip}:/var/www/${otafolder}/sts/
   sudo ssh -i ${scpkey} root@${scpip} "rm /var/www/${otafolder}/sts/latest.ota"
   sudo ssh -i ${scpkey} root@${scpip} "ln -s /var/www/html/sts/${base}.${code}.ota /var/www/${otafolder}/sts/latest.ota"
   ;;
       *)
   echo "Invalid input..."
   ;;
       no)
   echo "ok"
   ;;
   esac
}

if [ $# -gt 0 ]; then
    case "$1" in
	-h)
	    help
            ;;
        -t)
            dir=$2
	    mount
            copytest
	    buildtest
            ;;
	-f) 
	    dir=$2
	    base=$3
	    code=$4
	    scpyn=$5
	    mount
	    copyfull
            buildcustom
	    scptoserver
	    ;;
	-m) 
	    dir=$2
	    mount
	    ;;
	-b) 
	    dir=$2
	    buildcustom
	    ;;
	-bf) 
	    dir=$2
	    base=$3
	    code=$4
	    scpyn=$5
	    copyfull
	    buildcustom
	    scptoserver
	    ;;
	-mb) 
	    dir=$2
	    base=$3
	    code=$4
	    scpyn=sign
	    mount
            buildtest
	    scptoserver
	    ;;
	-sts) 
	    dir=$2
	    base=$3
	    code=$4
	    scpyn=$5
	    scptoserver
	    ;;
    esac
    else
        echo "Read the GitHub page before using this script!"
fi
