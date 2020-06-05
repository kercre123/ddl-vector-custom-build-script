## ddl-vector-custom-build-script
"Simple" all root bash script that turns a regular dev Vector OTA into an unsigned one with a new update engine, ssh key, and new version number so he can work with chipper.

## **DISCLAIMER**

This can only work with Dev Vectors, and not with regular production Vectors.

## What *exactly* does it do?

This takes an OTA, decrypts it, mounts it, copies some new files (update-engine, authorized_keys, os-version, os-version-code, os-version-base, version, and build.prop), unmounts it, encrypts it, finds the SHA256 sum of the img to put into the manifest, compiles it all into an OTA, then deletes some temporary files.

## Usage

Gunzip the tar.gz and put the "resources" folder next to the script. (`gunzip resources.tar.gz`)

Make a directory and put an OTA in it. Name it `latest.ota` then feed the directory to it to the script:

`./dvcbs -n 1.5.0.2953/`

`-h` will bring up the help menu

`-n {dir}` will do what the script is supposed to do

`-o {dir}` is an experimetal feature that I was too lazy to add for now. Basically the same thing as -n but works for firmwares under 1.0.

## Correct output

If the OTA built successfully, you should be met with this:

Converting OTA in 1.5.0.2953/!

*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better.

Decompressing. This may take a minute.

Rename img.dec to mountable img

Mounting IMG

Copying files over

Compressing. This may take a minute.

*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better.

Figuring out SHA256 sum and putting it into manifest.

Putting into tar.
manifest.ini

Removing some temp files.

Renaming original OTA back to OTA

Done! Output should be in 1.5.0.2953/final/latest.ota!


