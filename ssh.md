# SSH Authentication

## Generate an SSH key

BY using command `ssh-keygen`

## Copy the key to a server

Once an SSH key has been created, the `ssh-copy-id` command can be used to install it as an authorized key on the server. O
nce the key has been authorized for SSH, it grants access to the server without a password.

Use a command like the following to copy SSH key:
_Run in Git-Bash on Windows_
```
# e.g. ssh-copy-id -i ~/.ssh/mykey user@host
$ ssh-copy-id -i H:/.ssh/id_rsa fank@ednpas6909

```

This logs into the server host, and copies keys to the server, and configures them to grant access by adding them to the authorized_keys file. 
The copying may ask for a password or other authentication for the server.

Only the public key is copied to the server. The private key should never be copied to another machine.
