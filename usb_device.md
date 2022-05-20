# USB device on Linux

- [Linux allocated devices](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/devices.rst)
- [Device major number](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/devices.txt)

## Useful commands

- `$ lsusb`
- `$ dmesg`

- `$ udevadm` -- e.g. `$ udevadm info -q property --export -n /dev/bus/usb/001/001`

## related paths

- ``/dev/bus/usb``
- ``/sys/bus/usb/devices``


