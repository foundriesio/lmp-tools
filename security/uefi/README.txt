UEFI authentication
===================

To create a custom set of UEFI Secure Boot keys and certificates use this
gen_uefi_certs.sh script as follows.

- Create the directory for storing the keys and certificates:
 $ mkdir custom_uefi_keys_and_certs

- Install the prerequisite packages to use the gen_uefi_certs.sh script:
 $ sudo apt install openssl, efitools, uuid-runtime

- Run the gen_uefi_certs.sh script:
 $ cd custom_uefi_keys_and_certs
 $ ../lmp-tools/security/uefi/gen_uefi_certs.sh

At this point you should store the generated keys and certificates securely.

Then take the following steps:

1) Provision keys:
------------------
The generated certificates must be enrolled in your target UEFI implementation
so that secure boot can be enabled; once done only signed images will be able to
boot.

If images were not signed (or were incorrectly signed) the UEFI will trigger
an access denied error

Provisioning the keys can be done:
  1.1 At run-time:
      Using the UEFI graphical interface followed by a system reset.
      This is the usual way of working with QEMU images during development.

  1.2 At boot-time:
      Using a custom EFI program with the certificates embedded on it.
      This should be the common way of deploying to devices.

2) Removing the provisioned keys using your own efi application:
----------------------------------------------------------------
Deactivating Secure Boot can be done by removing the enrolled certificates using setvar().
To that end, we also generate the corresponding noPK.auth and noKEK.auth used to clear PK, KEK, db and dbx.

3) Sign images:
---------------
The DB private key must be made available to LmP during build time so that
the bootloader and kernel image can be signed.

When using the Factory this is a matter of adding the keys to the lmp-manifest
repository directory factory-keys/uefi and then triggering a build.

The generated images will be signed and are now ready to boot using the
provisioned UEFI.

Reference:
https://docs.foundries.io/latest/reference-manual/security/secure-boot-uefi.html?highlight=uefi
