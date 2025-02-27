#!/usr/bin/env python3
import hashlib
import os
import struct
import sys

class ChecksumUpdater:
    def __init__(self):
        # Development paths (source files)
        self.src_path = 'src'
        # Installation paths (target files)
        self.efi_boot_path = os.environ.get('EFI_BOOT_PATH', os.path.join('EFI', 'BOOT'))
        self.checksum_file = os.path.join(self.efi_boot_path, 'checksums.dat')

    def calculate_file_hash(self, filepath):
        """Calculate SHA-256 hash of a file."""
        try:
            sha256_hash = hashlib.sha256()
            with open(filepath, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            return sha256_hash.digest()
        except FileNotFoundError:
            print(f"Error: File not found - {filepath}")
            return None
        except Exception as e:
            print(f"Error calculating hash for {filepath}: {e}")
            return None

    def get_file_path(self, filename):
        """Try src directory first, then installation path."""
        # Try src directory first
        src_file = os.path.join(self.src_path, filename)
        if os.path.exists(src_file):
            return src_file

        # Finally try installation path
        return os.path.join(self.efi_boot_path, filename)

    def update_checksums(self):
        """Update checksums for all boot files."""
        print("Updating checksums for boot files...")

        # Files to check (in order of storage in checksums.dat)
        files = [
            ('boot1.png', "Kernel boot logo"),
            ('boot2.png', "Setup mode logo"),
            ('config.cfg', "Configuration file")
        ]

        checksums = []
        for filename, description in files:
            filepath = self.get_file_path(filename)
            file_hash = self.calculate_file_hash(filepath)

            if file_hash is None:
                print(f"Failed to update checksums: {description} ({filename}) not found or inaccessible")
                return False

            checksums.append(file_hash)
            print(f"✓ Generated checksum for {description}")

        # Ensure EFI/BOOT directory exists
        os.makedirs(self.efi_boot_path, exist_ok=True)

        # Write checksums to binary file
        try:
            with open(self.checksum_file, 'wb') as f:
                for checksum in checksums:
                    f.write(checksum)
            print(f"\nChecksums successfully written to {self.checksum_file}")
            return True
        except Exception as e:
            print(f"Error writing checksums file: {e}")
            return False

    def verify_checksums(self):
        """Verify all files against stored checksums."""
        try:
            with open(self.checksum_file, 'rb') as f:
                stored_checksums = f.read()
        except FileNotFoundError:
            print("No existing checksums file found")
            return False

        files = ['boot1.png', 'boot2.png', 'config.cfg']
        all_valid = True

        for i, filename in enumerate(files):
            filepath = self.get_file_path(filename)
            current_hash = self.calculate_file_hash(filepath)
            if current_hash is None:
                print(f"❌ Cannot verify {filename} - file not found")
                all_valid = False
                continue

            stored_hash = stored_checksums[i*32:(i+1)*32]
            if current_hash != stored_hash:
                print(f"❌ Checksum mismatch for {filename}")
                all_valid = False
            else:
                print(f"✓ Valid checksum for {filename}")

        return all_valid

def main():
    updater = ChecksumUpdater()

    if len(sys.argv) > 1 and sys.argv[1] == '--verify':
        print("Verifying existing checksums...")
        if updater.verify_checksums():
            print("\nAll checksums are valid!")
            sys.exit(0)
        else:
            print("\nChecksum verification failed!")
            sys.exit(1)
    else:
        print("Updating checksums...")
        if updater.update_checksums():
            print("\nChecksum update completed successfully!")
            sys.exit(0)
        else:
            print("\nChecksum update failed!")
            sys.exit(1)

if __name__ == "__main__":
    main()