# UEFI USB Bootloader

A flexible and user-friendly UEFI bootloader implementation with USB boot support and custom logo capabilities.

![Boot Logo 1](attached_assets/boot1.png)
![Boot Logo 2](attached_assets/boot2.png)

## Features

- USB root filesystem loading
- Configurable kernel path (/boot/vmlinuz)
- Custom boot logo support (boot1.png and boot2.png)
- BIOS/QEMU setup integration
- Integrity verification for boot assets
- Configuration system for customizing boot options

## Prerequisites

- NASM assembler
- GNU ld (binutils)
- GNU Make
- FAT32-formatted USB drive (for installation)

## Building

```bash
# Clone the repository
git clone https://github.com/LinuxXApple/bootloader
cd bootloader

# Build the bootloader
make clean && make
```

## Installation

### Installing to USB Drive

1. Format your USB drive with FAT32:
```bash
sudo mkfs.fat -F32 /dev/sdX1  # Replace sdX with your USB drive
```

2. Mount the USB drive:
```bash
sudo mkdir -p /mnt/usb
sudo mount /dev/sdX1 /mnt/usb
```

3. Install the bootloader:
```bash
sudo make install-usb
```

4. Copy your kernel:
```bash
sudo cp /path/to/your/kernel /mnt/usb/boot/vmlinuz
```

5. Unmount:
```bash
sudo umount /mnt/usb
```

### Boot Menu Options

1. Boot kernel - Loads kernel from USB with custom logo
2. Memory info - Displays system memory information
3. System info - Shows hardware details
4. Configure boot options - Customize bootloader settings
5. Enter setup - Access BIOS or QEMU monitor
6. Reboot - Restart system

## Security Features

- SHA-256 hash verification for boot logos
- Configuration file integrity checking
- System halts on detected tampering

### Integrity Verification

The bootloader implements a robust security system:
1. SHA-256 hashes are calculated and stored for:
   - boot1.png (kernel boot logo)
   - boot2.png (setup mode logo)
   - Configuration file
2. Hashes are verified before loading any assets
3. System immediately halts if tampering is detected
4. Configuration changes require proper hash updates

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
