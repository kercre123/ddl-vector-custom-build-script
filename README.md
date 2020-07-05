## ddl-vector-custom-build-script
"Simple" all root bash script that turns a regular dev Vector OTA into an unsigned one. It can also copy over certain files for custom builds.

## **DISCLAIMER**

This can only work with Dev Vectors, and not with regular production Vectors.

## What *exactly* does it do?

This takes an OTA, decrypts it, mounts it, copies some new files (if specified), builds, and SCPs them to a server (if specified).

## Usage

Gunzip the tar.gz and put the "resources" folder next to the script. (`tar -xf resources.tar.gz`)

Make a directory and put an OTA in it. Name it `latest.ota` then feed the directory to it to the script:

To use SCP, you will need to put in your SSH root key at the top of the script where specified, the IP where specified, and the folder to put it at (at /var/www/<folder>).

Testing older OTAs:
`./dvcbs -t 1.5.0.2953/`

Custom Builds:
`./dvcbs -m 20/`
`./dvcbs -bf 20/ 1.8.0 20 stable`

`-f {dir} {versionbase} {versioncode} {scp}`  this mounts OTA, copys over versionbase, versioncode, new update-engine, and prod server config, then builds

`-m {dir}`   mount latest.ota

`-b {dir} {versionbase} {versioncode} {scp}`   build apq8009-robot-sysfs.img

`-bf {dir} {versionbase} {versioncode} {scp}`  copy over versionbase, versioncode, new update-engine, and prod server config then build

`-t {dir}`   mount, copy over prod server config, build. used for testing older firmware and new ones from ddl

`-mb {dir} {versionbase} {versioncode}`   only mounts then builds. used for testing super old firmware


