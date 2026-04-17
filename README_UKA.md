# UKA for Codespaces

Unpacker Kitchen for Android - Linux Version for GitHub Codespaces

This is a port of the UKA Magisk module for use in Linux environments like GitHub Codespaces.

## Features

- Extract .img files (system.img, vendor.img, etc.)
- Build .img files from directories
- Unpack boot.img and recovery.img
- Convert between sparse and raw image formats
- Unpack .dat files
- Unpack payload.bin from OTA updates

## Usage

Simply type `menu` in the terminal to start the UKA interface:

```bash
menu
```

The script will display an interactive menu where you can choose various operations.

## Requirements

- Linux environment (Ubuntu/Debian)
- Basic tools: mount, umount, mkfs.ext4
- Downloaded tools: simg2img, img2simg, sdat2img, unpackbootimg, payload-dumper-go

## Directory Structure

- `output/` - Default output directory for processed files
- `temp/` - Temporary working directory

## Available Tools

The script uses tools copied from the original UKA module:
- simg2img / img2simg - Convert between sparse and raw images
- sdat2img - Unpack .dat files
- unpackbootimg - Unpack boot images
- payload-dumper-go - Unpack payload.bin

## Notes

- Some advanced features may require additional tools
- Always backup your files before processing
- For boot.img repacking, you may need mkbootimg (not included)

## Original UKA

This is based on the UKA Magisk module by kory-vadim.