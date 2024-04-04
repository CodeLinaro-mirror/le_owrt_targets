#Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
#SPDX-License-Identifier: BSD-3-Clause-Clear

#!/bin/bash

TOPDIR=$(pwd)
BUILD_DIR="$TOPDIR/../../../../build_dir/target-aarch64_cortex-a53_musl/"
directory="$BUILD_DIR/root-sdx75/usr/lib/opkg/info"
whitelist=("lftp")  # Add the package names you want to whitelist

if [ ! -d "$directory" ]; then
    echo "Directory $directory does not exist."
    exit 1
fi

echo -e "\n\t\tPackages with GPL-3.0 License"
echo -e "\t\t-------------------------------"
echo -e "\t Package Name\t\t\t\t\tLicense"

for file in "$directory"/*; do
    if [[ $file == *".control"* ]]; then
        filename=$(basename "$file")
        filename_no_control="${filename%.control}"

        # Check if the file is in the whitelist
        if printf '%s\n' "${whitelist[@]}" | grep -qx "$filename_no_control"; then
            continue
        fi

        while read -r LINE; do
            if [[ $LINE == *License:*GPL-3.0* ]]; then
               # printf "%-20s\t\t\t\t%s\n" "$filename_no_control" "$LINE"
                echo -e "Warning: $filename_no_control \t\t\t\t\t$LINE"

            break
            fi
        done < "$file"
    fi
done
