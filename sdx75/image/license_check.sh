#Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
#SPDX-License-Identifier: BSD-3-Clause-Clear

#!/bin/bash

TOPDIR=$(pwd)
BUILD_DIR="$TOPDIR/../../../../build_dir/target-aarch64_cortex-a53_musl/"

directory="$BUILD_DIR/root-sdx75/usr/lib/opkg/info"

if [ ! -d "$directory" ]; then
    echo "Directory $directory does not exist."
    exit 1
fi

echo -e "\nPackages with GPL-3.0 License"
echo -e "-------------------------------"
echo -e "Package Name\t\t\t\t\tLicense"

for file in "$directory"/*; do
    if [[ $file == *".control"* ]]; then
        filename=$(basename "$file")  # Extract the file name without the path
        filename_no_control="${filename%.control}"  # Remove the '.control' extension
        while read -r LINE; do
            if [[ $LINE == *License:*GPL-3.0* ]]; then
                printf "%-20s\t\t\t\t%s\n" "$filename_no_control" "$LINE"
                break
            fi
        done < "$file"
    fi
done
