#Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
#SPDX-License-Identifier: BSD-3-Clause-Clear

#!/bin/bash
echo $1 $2 $3

PROFILE=$1
BOARD=$2
TOPDIR=$3
BUILD_DIR="$TOPDIR/build_dir/target-aarch64_cortex-a53_musl/"

check_packages_license() {
    local directory="$1"
    local whitelist=("lftp" "libelf1" "pbr-iptables" "pbr")  # Add the package names you want to whitelist for using GPLV3 license
    # exception_list: List of packages without licenses. Ensure each package's Makefile includes the PACKAGE_LICENSE variable with the correct license information.
    local exception_list=( "postboot" "rproc-tracing" "kmod-sat_module" "security-tests")
    if [ ! -d "$directory" ]; then
        echo "Directory $directory does not exist."
        exit 1
    fi

    echo -e "\n Packages with GPL-3.0 License and No License Info"
    echo -e " ---------------------------------------------------"
    echo -e " Status    \t\t\tPackage Name\t\t\tLicense Info\t\t\tPath"

    for file in "$directory"/*; do
        if [[ $file == *".control"* ]]; then
            filename=$(basename "$file")
            filename_no_control="${filename%.control}"
            local package_name=""
            local source_name=""

            # Check if the file is in the whitelist
            if printf '%s\n' "${whitelist[@]}" | grep -qx "$filename_no_control"; then
                continue
            fi

            license_found=false  # Flag to check if License: line is found

            while read -r LINE; do
                if [[ $LINE == Package:* ]]; then
                    package_name="${LINE#Package: }"
                elif [[ $LINE == Source:* ]]; then
                    source_name="${LINE#Source: }"
                elif [[ $LINE == *License:* ]]; then
                    license_found=true  # License line found
                    if [[ $LINE == *GPL-3.0* ]]; then
                        if [[ $LINE == *exception* ]]; then
                            echo -e " Exception: \t\t\t$filename_no_control\t\t\t$LINE\t\t\t$source_name"
                        else
                            echo -e " Error: \t\t\t$filename_no_control\t\t\t$LINE\t\t\t$source_name"
                        fi
                    fi
                    break  # Stop reading further lines as we found a license
                fi
            done < "$file"

            # Determine the status based on the source and exception list
            local status="Warning:"  # Default status
            if [[ $source_name == *"owrt-qti-"* ]] ; then
                status="Error"
            fi
            if [[ "${exception_list[*]}" =~ "${package_name}" ]]; then
                status="ToBeFixed     "
            fi

            # If no License line was found, print the package name
            if [ "$license_found" = false ]; then
                # echo -e " error: No License Info \t\t\t$filename_no_control \t\t\t\t\tNot found"
                echo -e " $status\t\t\t$package_name\t\t\tLicense: Not Found\t\t\t$source_name"
            fi
        fi
    done
}


# Check for specific profile
if [[ $PROFILE == "recovery" ]]; then
    echo -e "\nRecovery Profile."
    directory="$BUILD_DIR/recovery/root-$BOARD/usr/lib/opkg/info"
    check_packages_license "$directory"
else
    echo -e "\n${PROFILE^} Profile."
    directory="$BUILD_DIR/root-$BOARD/usr/lib/opkg/info"
    check_packages_license "$directory"
    if [[ $PROFILE == "cpe" || $PROFILE == "mbb" ]]; then
    echo -e "\n${PROFILE^} AB Profile."
    directory_ab="$BUILD_DIR/root-$BOARD-ab/usr/lib/opkg/info"
    check_packages_license "$directory_ab"
    fi
fi
