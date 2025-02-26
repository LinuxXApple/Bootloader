CC = nasm
LD = ld

CFLAGS = -f elf64
LDFLAGS = -T src/linker.ld -z noexecstack

SOURCES = src/boot.asm src/main.asm src/logo.asm src/config.asm
OBJECTS = $(SOURCES:.asm=.o)

TARGET = bootloader.efi

.PHONY: all clean install install-usb

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.asm
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

# Install to local EFI directory
install: $(TARGET)
	mkdir -p /boot/efi/EFI/BOOT
	cp $(TARGET) /boot/efi/EFI/BOOT/BOOTX64.EFI
	cp attached_assets/boot1.png /boot/efi/EFI/BOOT/boot1.png
	cp attached_assets/boot2.png /boot/efi/EFI/BOOT/boot2.png

# Install to USB drive (run as root, USB must be mounted at /mnt/usb)
install-usb: $(TARGET)
	@echo "Installing bootloader to USB drive mounted at /mnt/usb..."
	mkdir -p /mnt/usb/boot/efi/EFI/BOOT
	cp $(TARGET) /mnt/usb/boot/efi/EFI/BOOT/BOOTX64.EFI
	cp attached_assets/boot1.png /mnt/usb/boot/efi/EFI/BOOT/boot1.png
	cp attached_assets/boot2.png /mnt/usb/boot/efi/EFI/BOOT/boot2.png
	@echo "Bootloader installed successfully."
	@echo "Note: Your kernel should be placed at /mnt/usb/boot/vmlinuz"
	@echo "USB installation instructions:"
	@echo "1. Format your USB drive with FAT32 filesystem"
	@echo "2. Mount the USB drive: mount /dev/sdX1 /mnt/usb"
	@echo "3. Run: make install-usb"
	@echo "4. Copy your kernel: cp /path/to/kernel /mnt/usb/boot/vmlinuz"
	@echo "5. Unmount: umount /mnt/usb"