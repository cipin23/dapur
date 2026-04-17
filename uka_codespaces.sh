#!/bin/bash

# UKA for Codespaces - Unpacker Kitchen for Android
# Ported version for Linux environment

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default directories
WORK_DIR="/workspaces/dapur"
OUTPUT_DIR="$WORK_DIR/output"
TEMP_DIR="$WORK_DIR/temp"

# Create directories if not exist
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# Check if tools are available
check_tools() {
    local tools=("simg2img" "img2simg" "mkfs.ext4" "mount" "umount" "python3")
    local missing=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null && [ ! -f "/workspaces/dapur/$tool" ]; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}Warning: Missing tools: ${missing[*]}${NC}"
        echo "Some features may not work. Tools available locally in /workspaces/dapur/"
    fi
}

# Function to select output directory
select_output_dir() {
    echo
    echo "     Selecting an Image Save Folder"
    echo "     -----------------------------"
    echo
    echo ".....Enter 0 for default: $OUTPUT_DIR"
    echo ".....Or enter your custom path..."
    echo
    read -r choice

    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        outdir="$OUTPUT_DIR"
    elif [ -d "$choice" ]; then
        outdir="$choice"
    else
        echo -e "${RED}Directory does not exist. Using default.${NC}"
        outdir="$OUTPUT_DIR"
        mkdir -p "$outdir"
    fi

    echo
    echo "Output directory set to: $outdir"
    echo "Free space: $(df -h "$outdir" | tail -1 | awk '{print $(NF-2)}')"
}

# Function to unpack system.img
unpack_system_img() {
    echo
    echo "     Menu: Extract .img"
    echo
    echo "Put system.img in the current directory or specify path:"
    read -r img_path

    if [ ! -f "$img_path" ]; then
        echo -e "${RED}File not found: $img_path${NC}"
        return
    fi

    select_output_dir

    echo "Unpacking $img_path to $outdir..."

    # Check if sparse image
    if file "$img_path" | grep -q "sparse"; then
        /workspaces/dapur/simg2img "$img_path" "$outdir/system_raw.img" 2>/dev/null || simg2img "$img_path" "$outdir/system_raw.img"
        img_path="$outdir/system_raw.img"
    fi

    # Mount the image
    mount_point="$TEMP_DIR/mount_$(basename "$img_path" .img)"
    mkdir -p "$mount_point"

    if mount -t ext4 -o loop "$img_path" "$mount_point" 2>/dev/null; then
        echo "Mounted successfully. Copying files..."
        cp -r "$mount_point"/* "$outdir/"
        umount "$mount_point"
        rmdir "$mount_point"
        echo -e "${GREEN}Unpacked to $outdir${NC}"
    else
        echo -e "${RED}Failed to mount. This might not be an ext4 image.${NC}"
    fi
}

# Function to repack system.img
repack_system_img() {
    echo
    echo "     Menu: Build .img"
    echo
    echo "Specify directory to pack into system.img:"
    read -r dir_path

    if [ ! -d "$dir_path" ]; then
        echo -e "${RED}Directory not found: $dir_path${NC}"
        return
    fi

    select_output_dir

    echo "Enter image size in MB (or press Enter for auto):"
    read -r size_mb

    if [ -z "$size_mb" ]; then
        # Calculate size
        size_kb=$(du -sk "$dir_path" | awk '{print $1}')
        size_mb=$(( (size_kb + 102400) / 1024 ))  # Add 100MB buffer
    fi

    size_bytes=$((size_mb * 1024 * 1024))

    output_img="$outdir/system.img"

    echo "Creating $output_img with size ${size_mb}MB..."

    # Create ext4 image
    if mkfs.ext4 -d "$dir_path" "$output_img" $size_bytes 2>/dev/null; then
        echo -e "${GREEN}Created $output_img${NC}"
    else
        echo -e "${RED}Failed to create image${NC}"
    fi
}

# Function to unpack boot.img
unpack_boot_img() {
    echo
    echo "     Menu: Unpack boot.img"
    echo
    echo "Put boot.img in current directory or specify path:"
    read -r boot_path

    if [ ! -f "$boot_path" ]; then
        echo -e "${RED}File not found: $boot_path${NC}"
        return
    fi

    select_output_dir

    echo "Unpacking $boot_path..."

    # Use python script or tool to unpack boot.img
    # For now, basic extraction
    if [ -f "/workspaces/dapur/unpackbootimg" ] || command -v unpackbootimg &> /dev/null; then
        cd "$outdir"
        /workspaces/dapur/unpackbootimg -i "$boot_path" 2>/dev/null || unpackbootimg -i "$boot_path"
        echo -e "${GREEN}Boot image unpacked to $outdir${NC}"
    else
        echo -e "${YELLOW}unpackbootimg not available. Install android-tools.${NC}"
    fi
}

# Function to repack boot.img
repack_boot_img() {
    echo
    echo "     Menu: Repack boot.img"
    echo
    echo "Specify directory with boot components (kernel, ramdisk, etc.):"
    read -r boot_dir

    if [ ! -d "$boot_dir" ]; then
        echo -e "${RED}Directory not found: $boot_dir${NC}"
        return
    fi

    select_output_dir

    echo "Repacking boot.img..."

    # This would require mkbootimg or similar
    echo -e "${YELLOW}Repacking boot.img requires mkbootimg tool.${NC}"
}

# Function to convert sparse/raw
convert_sparse_raw() {
    echo
    echo "     Menu: Convert sparse ↔ raw"
    echo
    echo "Specify .img file:"
    read -r img_path

    if [ ! -f "$img_path" ]; then
        echo -e "${RED}File not found: $img_path${NC}"
        return
    fi

    select_output_dir

    if file "$img_path" | grep -q "sparse"; then
        output="$outdir/$(basename "$img_path" .img)_raw.img"
        echo "Converting sparse to raw: $output"
        /workspaces/dapur/simg2img "$img_path" "$output" 2>/dev/null || simg2img "$img_path" "$output"
    else
        output="$outdir/$(basename "$img_path" .img)_sparse.img"
        echo "Converting raw to sparse: $output"
        /workspaces/dapur/img2simg "$img_path" "$output" 2>/dev/null || img2simg "$img_path" "$output"
    fi

    echo -e "${GREEN}Converted to $output${NC}"
}

# Function to unpack .dat files
unpack_dat() {
    echo
    echo "     Menu: Unpack .dat"
    echo
    echo "Specify .dat file:"
    read -r dat_path

    if [ ! -f "$dat_path" ]; then
        echo -e "${RED}File not found: $dat_path${NC}"
        return
    fi

    select_output_dir

    echo "Unpacking $dat_path..."

    # Need sdat2img or similar
    if [ -f "/workspaces/dapur/sdat2img" ] || command -v sdat2img &> /dev/null; then
        transfer_list="${dat_path%.dat}.transfer.list"
        if [ -f "$transfer_list" ]; then
            /workspaces/dapur/sdat2img "$transfer_list" "$dat_path" "$outdir/$(basename "$dat_path" .dat).img" 2>/dev/null || sdat2img "$transfer_list" "$dat_path" "$outdir/$(basename "$dat_path" .dat).img"
            echo -e "${GREEN}Unpacked to $outdir${NC}"
        else
            echo -e "${RED}Transfer list not found${NC}"
        fi
    else
        echo -e "${YELLOW}sdat2img not available${NC}"
    fi
}

# Function to unpack payload.bin
unpack_payload() {
    echo
    echo "     Menu: Unpack payload.bin"
    echo
    echo "Specify payload.bin file:"
    read -r payload_path

    if [ ! -f "$payload_path" ]; then
        echo -e "${RED}File not found: $payload_path${NC}"
        return
    fi

    select_output_dir

    echo "Unpacking $payload_path..."

    # Use payload-dumper-go or similar
    if command -v payload-dumper-go &> /dev/null; then
        payload-dumper-go -o "$outdir" "$payload_path"
        echo -e "${GREEN}Payload unpacked to $outdir${NC}"
    else
        echo -e "${YELLOW}payload-dumper-go not available. Install it.${NC}"
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "${GREEN}"
        echo "               Main Menu:"
        echo "              UKA for Codespaces"
        echo "       ------------------------------"
        echo -e "${NC}"
        echo "   Enter the number corresponding to the desired action:"
        echo
        echo "   1) Extract .img"
        echo "   2) Build .img"
        echo "   3) Unpack boot.img"
        echo "   4) Repack boot.img"
        echo "   5) Convert sparse ↔ raw"
        echo "   6) Unpack .dat"
        echo "   7) Unpack payload.bin"
        echo "   8) Clean up working folders"
        echo "   9) Exit"
        echo

        read -r choice

        case $choice in
            1) unpack_system_img ;;
            2) repack_system_img ;;
            3) unpack_boot_img ;;
            4) repack_boot_img ;;
            5) convert_sparse_raw ;;
            6) unpack_dat ;;
            7) unpack_payload ;;
            8) echo "Cleaning up..."; rm -rf "$TEMP_DIR"/* ;;
            9) echo "Exiting..."; exit 0 ;;
            *) echo -e "${RED}Invalid choice. Please enter 1-9.${NC}" ;;
        esac

        echo
        echo "Press Enter to continue..."
        read -r
        clear
    done
}

# Main script
clear
check_tools
main_menu