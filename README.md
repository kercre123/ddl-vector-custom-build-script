## ddl-vector-custom-build-script
"Simple" all root bash script that turns a regular dev Vector OTA into an unsigned one with a new update engine, ssh key, and new version number so he can work with chipper.
## **DISCLAIMER**
This can only work with Dev Vectors, and not with regular production Vectors.
## What *exactly* does it do?
This takes an OTA, decrypts it, mounts it, copies some new files (update-engine, authorized_keys, os-version, os-version-code, os-version-base, version, and build.prop), unmounts it, encrypts it, finds the SHA256 sum of the img to put into the manifest, compiles it all into an OTA, then deletes some temporary files.
## Usage
Make a directory and put an OTA in it. Name it `latest.ota` then feed the directory to it to the script:

`./dvcbs -n 1.5.0.2953/`

`-h` will bring up the help menu

`-n {dir}` will do what the script is supposed to do

`-o {dir}` is an experimetal feature that I was too lazy to add for now. Basically the same thing as -n but works for firmwares under 1.0.
