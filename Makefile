CC = nasm
LD = ld

CFLAGS = -f elf64
LDFLAGS = -T src/linker.ld -z noexecstack

SOURCES = src/boot.asm src/main.asm src/logo.asm src/config.asm src/checksums.asm
OBJECTS = $(SOURCES:.asm=.o)

TARGET = bootloader.efi
CHECKSUM_TOOL = src/tools/update_checksums.py

.PHONY: all clean install install-usb install-home update-checksums verify-checksums

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.asm
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

# Update checksums after file changes
update-checksums:
	@echo "Updating checksums using Python utility..."
	python3 $(CHECKSUM_TOOL)

# Verify checksums
verify-checksums:
	@echo "Verifying checksums..."
	python3 $(CHECKSUM_TOOL) --verify

# Install to user's home directory
install-home: $(TARGET) update-checksums
	@echo "Installing bootloader to home directory..."
	mkdir -p $(HOME)/EFI/BOOT
	cp $(TARGET) $(HOME)/EFI/BOOT/BOOTX64.EFI
	cp src/boot1.png $(HOME)/EFI/BOOT/boot1.png
	cp src/boot2.png $(HOME)/EFI/BOOT/boot2.png
	cp src/config.cfg $(HOME)/EFI/BOOT/config.cfg
	EFI_BOOT_PATH=$(HOME)/EFI/BOOT python3 $(CHECKSUM_TOOL)
	@echo "Bootloader installed successfully to $(HOME)/EFI/BOOT"
	@echo "Installation complete!"

# Install to local EFI directory
install: $(TARGET) update-checksums
	mkdir -p /boot/efi/EFI/BOOT
	cp $(TARGET) /boot/efi/EFI/BOOT/BOOTX64.EFI
	cp src/boot1.png /boot/efi/EFI/BOOT/boot1.png
	cp src/boot2.png /boot/efi/EFI/BOOT/boot2.png
	cp src/config.cfg /boot/efi/EFI/BOOT/config.cfg
	python3 $(CHECKSUM_TOOL)

# Install to USB drive (run as root, USB must be mounted at /mnt/usb)
install-usb: $(TARGET) update-checksums
	@echo "Installing bootloader to USB drive mounted at /mnt/usb..."
	mkdir -p /mnt/usb/boot/efi/EFI/BOOT
	cp $(TARGET) /mnt/usb/boot/efi/EFI/BOOT/BOOTX64.EFI
	cp src/boot1.png /mnt/usb/boot/efi/EFI/BOOT/boot1.png
	cp src/boot2.png /mnt/usb/boot/efi/EFI/BOOT/boot2.png
	cp src/config.cfg /mnt/usb/boot/efi/EFI/BOOT/config.cfg
	python3 $(CHECKSUM_TOOL)
	@echo "Bootloader installed successfully."
	@echo "Note: Your kernel should be placed at /mnt/usb/boot/vmlinuz"
	@echo "USB installation instructions:"
	@echo "1. Format your USB drive with FAT32 filesystem"
	@echo "2. Mount the USB drive: mount /dev/sdX1 /mnt/usb"
	@echo "3. Run: make install-usb"
	@echo "4. Copy your kernel: cp /path/to/kernel /mnt/usb/boot/vmlinuz"
	@echo "5. Unmount: umount /mnt/usb"