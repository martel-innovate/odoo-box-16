#!/bin/bash
# ^ The Nix derivation replaces the shebang with a suitable one.

#
# Generate `odbox.vault` secrets.
# This script typically creates a `generated` directory with the files
# listed below.
#
# generated
# ├── age.key                   # generated Age identity
# ├── certs
# │  ├── localhost-cert.pem     # generated localhost pub cert
# │  └── localhost-cert.pem.age # Age-encrypted localhost pub cert
# │  ├── localhost-key.pem      # generated localhost cert key
# │  └── localhost-key.pem.age  # Age-encrypted localhost cert key
# │  └── prod-cert.pem          # imported prod pub cert
# │  └── prod-cert.pem.age      # Age-encrypted prod pub cert
# │  └── prod-key.pem           # imported prod cert key
# │  └── prod-key.pem.age       # Age-encrypted prod cert key
# ├── passwords
# │  ├── admin                  # clear-text admin pwd (generated or entered)
# │  ├── admin.age              #   Age-encrypted clear-text pwd
# │  ├── admin.sha512           #   SHA512-hashed pwd `chpasswd` can handle
# │  ├── admin.sha512.age       #   corresponding Age-encrypted hashed pwd
# │  ├── admin.yesc             #   Yescrypt-hashed pwd `chpasswd` can handle
# │  ├── admin.yesc.age         #   corresponding Age-encrypted hashed pwd
# │  ├── odoo-admin             # clear-text Odoo admin pwd (generated or entered)
# │  ├── odoo-admin.age         #   Age-encrypted clear-text pwd
# │  ├── odoo-admin.sha512      #   SHA512-hashed pwd `chpasswd` can handle
# │  ├── odoo-admin.sha512.age  #   corresponding Age-encrypted hashed pwd
# │  ├── odoo-admin.yesc        #   Yescrypt-hashed pwd `chpasswd` can handle
# │  ├── odoo-admin.yesc.age    #   corresponding Age-encrypted hashed pwd
# │  ├── root                   # clear-text root pwd (generated or entered)
# │  ├── root.age               #   Age-encrypted clear-text pwd
# │  ├── root.sha512            #   hashed pwd that `chpasswd` can handle
# │  └── root.sha512.age        #   Age-encrypted hashed pwd
# │  ├── root.yesc              #   Yescrypt-hashed pwd `chpasswd` can handle
# │  └── root.yesc.age          #   corresponding Age-encrypted hashed pwd
# └── ssh
#   ├── id_ed25519              # generated ED25519 identity
#   └── id_ed25519.pub          # corresponding public key
#
# Notice `generated/age.key` contains the pub/private key pair to encrypt
# and decrypt all the Age files.
#
# There's a set of four password files for each built-in user: The NixOS
# root and admin users as well as the Odoo Web UI admin. Each set incudes
# the following files:
# - Clear text. A file containing the password in clear text. This is
#   either the password you specified or the (strong) one the script
#   automatically generated if you didn't specify one.
# - Age. A file containing the password encrypted using `age` and the
#   `age` key automatically generated by this script.
# - SHA512. A file containing a SHA512 hash of the password `chpasswd`
#   can handle.
# - SHA512 Age. A file containing the SHA512 hash encrypted using `age`
#   and the `age` key automatically generated by this script.
# - Yescrypt. A file containing a Yescrypt hash of the password
#   `chpasswd` can handle.
# - Yescrypt Age. A file containing the Yescrypt hash encrypted
#   using `age` and the `age` key automatically generated by
#   this script.
#
# As for certificates, there's a set of four files for each kind of
# certificate we need:
# - Pub cert file. Contains the public certificate.
# - Age pub cert file. Contains the Age-encrypted public certificate.
#   (Technically this one doesn't need to be encrypted, but we do it
#   anyway so you can easily use this file too with Agenix.)
# - Cert key file. Contains the certificate's private key.
# - Age key file. Contains the Age-encrypted certificate's private key.
#
# This script automatically generates a basic self-signed, 100-year
# valid, RSA SSL certificate in PEM format. This certificate is for
# the localhost CN by default, but you can change the CN to something
# else---see below. This script can also import the prod pub cert and
# private key into the `generated/certs` directory. On importing, it
# encrypts the private key and writes it to a corresponding `.age`
# file.
#
# You can run this script in either interactive or batch mode. In
# interactive mode, the script asks you to enter passwords for the
# root, admin and Odoo admin users. If you don't enter a password
# for one of them, a strong one gets automatically generated for
# you. The script then asks you to enter a CN for the self-signed
# cert. If you don't enter one, it defaults to localhost. Finally,
# the script asks you to import the prod pub cert and private key.
# If you don't have them, just skip this step.
#
# In batch mode, this script won't prompt you for the above params.
# Instead, you use env vars to specify those values:
# - `ROOT_PASSWORD`. Clear-text password for the root user. Don't
#   set this var to have the script generate one for you.
# - `ADMIN_PASSWORD`. Clear-text password for the admin user. Don't
#   set this var to have the script generate one for you.
# - `ODOO_ADMIN_PASSWORD`. Clear-text password for the Odoo admin
#   user. Don't set this var to have the script generate one for you.
# - `DOMAIN`. CN for the self-signed cert. Defaults to localhost if
#   not set.
# - `PROD_CERT`. Path to a prod public certificate file to copy over
#   to `generated/certs`. Don't set, if you don't have a cert.
# - `PROD_CERT_KEY`. Path to the corresponding key file to copy over
#   to `generated/certs`. Don't set, if you don't have a cert.
#
# Notice the script will start in interactive mode unless you set
# the `BATCH_MODE` env var to `1`. Here's an example batch mode
# invocation with all the parameters set
#
# $ BATCH_MODE=1 \
#   ROOT_PASSWORD=abc123 ADMIN_PASSWORD=xy ODOO_ADMIN_PASSWORD=123 \
#   PROD_CERT=c.pem PROD_CERT_KEY=k.pem \
#   ./gen.sh

set -ueo pipefail

source $(dirname "$0")/genlib.sh


# Input vars for batch mode.
: "${BATCH_MODE:=}"
: "${ROOT_PASSWORD:=}"
: "${ADMIN_PASSWORD:=}"
: "${ODOO_ADMIN_PASSWORD:=}"
: "${DOMAIN:=localhost}"
: "${PROD_CERT:=}"
: "${PROD_CERT_KEY:=}"

# Password file names and corresponding password values for batch mode.
pwd_files=("root" "admin" "odoo-admin")
batch_pwds=("${ROOT_PASSWORD}" "${ADMIN_PASSWORD}" "${ODOO_ADMIN_PASSWORD}")

# Run the script in batch mode.
run_batch_mode() {
    make_dirs
    make_age_key
    make_ssh_id

    for k in "${!pwd_files[@]}"; do
        make_password_files "${pwd_files[k]}" "${batch_pwds[k]}"
    done
    make_cert_files "${DOMAIN}"
    if [ "${PROD_CERT}" != "" ] && [ "${PROD_CERT_KEY}" != "" ]; then
        import_cert_files "${PROD_CERT}" "${PROD_CERT_KEY}"
    fi
}

# Run the script in interactive mode.
run_interactive_mode() {
    make_dirs
    make_age_key
    make_ssh_id

    for f in "${pwd_files[@]}"; do
        read -s -p "${f}'s password [leave empty to generate one]: " password
        printf "\n"
        make_password_files "${f}" "${password}"
    done

    read -p "self-signed certificate's domain [localhost]: " domain
    make_cert_files "${domain:-localhost}"

    read -p "prod pub certificate [press enter to skip]: " cert
    if [ "${cert}" != "" ]; then
        read -p "prod certificate key: " key
        if [ -z "${key}" ]; then
            printf "no prod certificate key entered, skipping prod certs\n"
            exit 0
        fi
        import_cert_files "${cert}" "${key}"
    fi
}


if [ -z "${BATCH_MODE}" ]
then
    run_interactive_mode
else
    run_batch_mode
fi
