#!/bin/bash

# If IGNITION_VALIDATE is not set to a specific binary
# check to see if we have it locally
if [[ -z ${IGNITION_VALIDATE} ]]; then
    # Check local directory
    ls ignition-validate 2>&1 /dev/null
    if [[ $? == 0 ]]; then
        IGNITION_VALIDATE="$(pwd)/ignition-validate"
    else
        echo "- ignition-validate not found. Skipping validation."
    fi
fi

if [[ ${IGNITION_VALIDATE} != "" ]]; then
    echo "+ Found ignition-validate at ${IGNITION_VALIDATE}"
    echo "+ $(${IGNITION_VALIDATE} --version)"
fi

NEWFILES='"/etc/hostname"
"/etc/resolve.conf"
"/etc/sysconfig/network-scripts/ifcfg-fake"
"/etc/sysconfig/network-scripts/ifcfg-blah"'
KEYS='"contents"
"filesystem"
"mode"
"path"'
FAILURES=0

# Ensure we have require commands
for required_command in jq file; do
    command -v "$required_command" > /dev/null
    if [ $? != 0 ]; then
        echo "$required_command is required for testing"
        exit 1
    fi
done

# validate the output (if ignition-validate is available)
validate_ignition() {
    tmpfile=$1
    testname=$2
    if [[ ${IGNITION_VALIDATE} != "" ]]; then
        ${IGNITION_VALIDATE} $tmpfile
        if [[ $? == 0 ]]; then
            echo "PASS: Validate config for ${testname}"
        else
            echo "FAIL: Validation failed for ${testname}"
        fi
    else
        echo "SKIP: Can not validate file for ${testname}"
    fi
}

# Ensure the new files from the fakeroot are present
test_expected_files() {
    tmpfile=$1
    testname="$2: File Check"
    result=$(jq '.storage.files[].path' ${tmpfile})
    success=1
    for fcheck in $NEWFILES; do
        if [[ $result != *"$fcheck"* ]]; then
            success=0
        fi
    done
    if [ $success == 0 ]; then
        echo "FAIL: ${testname} Files did not match"
        echo "- Expected: ${NEWFILES}"
        echo "- Got: ${result}"
        FAILURES=$(echo "$FAILURES + 1" | bc)
    else
        echo "PASS: ${testname}"
    fi
}

# Ensure that the minimum expected keys are set
test_expected_keys() {
    tmpfile=$1
    testname="$2: Key Check"
    success=1
    failures=""
    array_size=$(jq '.storage.files | length' ${tmpfile})
    array_size=$(echo ${array_size} - 1 | bc)
    for i in $(seq 0 ${array_size}); do
        result=$(jq ".storage.files[${i}]" ${tmpfile} | jq "keys[]")
        for check in $KEYS; do
            if [[ $result != *"$check"* ]]; then
                success=0
                failures="$failures $i"
            fi
        done
    done
    if [ $success == 0 ]; then
        echo "FAIL: ${testname} Keys did not match"
        for f in "$failures"; do
            echo "- Expected: ${KEYS}"
            echo "- Got: " $(jq ".storage.files[${f}]" ${tmpfile} | jq "keys[]")
        done
        FAILURES=$(echo "$FAILURES + 1" | bc)
    else
        echo "PASS: ${testname}"
    fi
}

# Ensure the content of a file is what is expected
test_expected_contents() {
    tmpfile=$1
    checkfile="$2"
    frcheckfile="test/fakeroot$checkfile"
    content="$3"
    testname="$4: Content Check for $checkfile"
    sourcecontent=$(jq -r ".storage.files[] | select(.path==\"${checkfile}\") | .contents.source" ${tmpfile})

    # Replace mimetype/encoding
    if [[ "$content" == *"{{mimetype}}"* ]]; then
        localmimetype=$(file -b --mime-encoding --mime-type $frcheckfile | sed -e "s| ||g")
        content=$(echo "$content" | sed -e "s|{{mimetype}}|$localmimetype|")
    fi

    if [ "$content" = "$sourcecontent" ]; then
            echo "PASS: ${testname}"
    else
        echo "FAIL: $testname Content does not match"
        echo "- Expected: ${content}"
        echo "- Got: ${sourcecontent}"
    fi
}


test_name="Ignition With No Storage"
tmpfile=$(mktemp)
./filetranspile -i test/ignition-no-storage.json -f test/fakeroot > ${tmpfile}
validate_ignition "${tmpfile}" "${test_name}"
test_expected_files "${tmpfile}" "${test_name}"
test_expected_keys "${tmpfile}" "${test_name}"

test_name="Ignition With No Files"
tmpfile=$(mktemp)
./filetranspile -i test/ignition-no-files.json -f test/fakeroot > ${tmpfile}
validate_ignition "${tmpfile}" "${test_name}"
test_expected_files "${tmpfile}" "${test_name}"
test_expected_keys "${tmpfile}" "${test_name}"

test_name="Ignition With Existing Files"
tmpfile=$(mktemp)
./filetranspile -i test/ignition.json -f test/fakeroot > ${tmpfile}
validate_ignition "${tmpfile}" "${test_name}"
test_expected_files "${tmpfile}" "${test_name}"
test_expected_keys "${tmpfile}" "${test_name}"

# See https://github.com/ashcrow/filetranspiler/pull/29
test_name="Ignition Overwrite With Fakeroot File"
tmpfile=$(mktemp)
./filetranspile -i test/ignition-overwrite-with-fakeroot-file.json -f test/fakeroot > ${tmpfile}
validate_ignition "${tmpfile}" "${test_name}"
test_expected_files "${tmpfile}" "${test_name}"
test_expected_keys "${tmpfile}" "${test_name}"
# We should still have the fakeroot one and not the one in our original ignition
test_expected_contents "${tmpfile}" "/etc/resolve.conf" "data:{{mimetype}};base64,c2VhcmNoIDEyNy4wLjAuMQpuYW1lc2VydmVyIDEyNy4wLjAuMQo=" "${test_name}"


if [[ $FAILURES -ge 1 ]]; then
    echo "${FAILURES} failures detected"
    exit 1
fi
