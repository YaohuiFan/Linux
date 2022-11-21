# USB device on Linux

- [Linux allocated devices](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/devices.rst)
- [Device major number](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/devices.txt)

## Useful commands

- `$ lsusb`
- `$ dmesg`

- `$ udevadm` -- e.g. `$ udevadm info -q property --export -n /dev/bus/usb/001/001`

- `$ lspic` -- to list all PCI devices, including the "USB controller" e.g. "00:14.0 USB controller: Inter Corporation 200 Series/Z370 Chipset Family USB 3.0 xHCI Controller" which should be listed under ``/sys/devices/pci0000:00/`` directory 

## related paths

- ``/dev/bus/usb``
- ``/sys/bus/usb/devices/``

##  ["ttyACM" and "ttyUSB"?](https://rfc1149.net/blog/2013/03/05/what-is-the-difference-between-devttyusbx-and-devttyacmx/)

"ttyACM", abstract control model.

"ttyUSB0" means "USB serial port adapter" and the "0" is the device number. "ttyUSB0" is the first adapter attached, so the next one will be allocated as "ttyUSB1". 

## Writing udev rule for USB devices
URLs:
- [1](https://linuxconfig.org/tutorial-on-how-to-write-basic-udev-rules-in-linux)
- [2](https://weinimo.github.io/how-to-write-udev-rules-for-usb-devices.html)
