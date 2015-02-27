# Docker Image Signer

These are tools to save and load signed Docker images, using GPG
detatched signatures and SHA512.

## Usage

Currently these are Bash scripts that require `docker` and `gpg` to be available
in the PATH.

The signing step uses a locally-available GPG private key to sign the exported
image. You may sign the image multiple times, or transfer it to additional
parties for them to sign. The collection of the `.tar` and its `.tar.XXXXX.sig`
signatures is a signature package, to be checked with `docker-image-loader`.

The loader verifies that all signers in the signature package are trusted, per
the GPG trust database, and that the signatures are valid, and that the number
of signatures mandated through an environment variable `MIN_SIGNATURES` are met.
If all of this is true, it imports the Docker image.

### Signing

```sh
./docker-image-signer.sh debian 6FD2ECE3
# [[ repeat for different keys ]]
```

```
○ → ./docker-image-signer.sh debian 6FD2ECE3
Copying from Docker...
Signing image debian to debian.tar.6FD2ECE3.sig ...
gpg: detected reader `Yubico Yubikey NEO OTP+CCID'
gpg: signatures created so far: 42

Please enter the PIN
[sigs done: 42]
```

### Loading

```sh
MIN_SIGNATURES=2 ./docker-image-loader.sh debian.tar
```

```
○ → MIN_SIGNATURES=2 ./docker-image-loader.sh debian.tar
Verifying debian.tar.5FD1E0E3.sig...
Good signature from 5FD1E0E3 in file debian.tar.5FD1E0E3.sig
[Fatal] Too few sigatures! 2 required, 1 provided.
```


## Compression

It's recommended to compress the image `.tar` as it is both large and
uncompressed. This script doesn't, as it may be convenient to compress the
`.tar` and the `.sig` files together for transport.

## Limitations

Docker's `docker save` command is not stable, producing slightly different
`.tar` files each time. Unfortunately, the inner `layer.tar` files have a habit
of changing between invocations of `docker save` even if the image is not
running. Because of this, we are forced to `save` a Docker image, sign it, and
move the whole (potentially large) thing around as a indivisible unit, lest we
break the signatures.

It would be more optimal to permit `docker pull` to obtain files from a
Registry, possibly cached locally, and then verify all layers' signatures.
However, it's unclear to the author how to ensure stability of those layers
if `docker save` itself cannot.

## Future Work

The loader is going to be implemented in Golang, so that it is self-encapsulated
to avoid a runtime dependency on GnuPG.

