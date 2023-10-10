#!/bin/bash

source $(dirname $0)/load-recent-git.sh

source $(dirname $0)/set-ccache.sh


compile_namd_target() {

    local source_dir=""
    local dirname_prefix="Linux-x86_64-g++"

    local label="multicore"

    while [ $# -ge 1 ]; do
        if [ -f "${1}/src/NamdTypes.h" ] ; then
            source_dir="${1}"
            pushd "${source_dir}"
            shift
        elif [ "${1}" = "debug" ] ; then
            dirname_prefix="Linux-x86_64-g++-debug"
            shift
        else
            label="${1}"
            shift
        fi
    done

    local dirname="${dirname_prefix}.${label}"

    local ret_code

    if [ -d /opt/charm ] ; then
        rm -f charm
        ln -s /opt/charm charm
    else
        echo "Error: Missing charm folder." >& 2
        return 1
    fi

    local -a cmd=(./config ${dirname})

    if [ "${label}" = "multicore" ] ; then
        cmd+=(--charm-arch multicore-linux-x86_64)
    fi

    if [ "${dirname_prefix}" = "Linux-x86_64-g++-debug" ] ; then
        cat > arch/Linux-x86_64-g++-debug.arch <<EOF
NAMD_ARCH = Linux-x86_64
CHARMARCH = multicore-linux-x86_64

CXX = g++ -m64 -std=c++0x
CXXOPTS = -O0 -g -DCOLVARS_DEBUG -DDEBUGM -DMIN_DEBUG_LEVEL=4
CC = gcc -m64
COPTS = \$(CXXOPTS)
EOF
    fi

    if [ "${label}" = "mpi" ] ; then
        cmd+=(--charm-arch mpi-linux-x86_64-mpicxx)
    fi

    if [ "${label}" = "netlrts" ] ; then
        cmd+=(--charm-arch netlrts-linux-x86_64)
    fi

    if ! grep -q -- -ltcl8.6 arch/Linux-x86_64.tcl ; then
        # Amend NAMD 2.x arch file for recent Tcl versions under RH and Debian paths
        if [ -f /usr/lib64/libtcl8.6.so ] || \
               [ -f /usr/lib/x86_64-linux-gnu/libtcl8.6.so ] ; then
            sed -i 's/-ltcl8.5/-ltcl8.6/' arch/Linux-x86_64.tcl
        fi
    fi

    if [ -f /usr/local/include/tcl.h ] ; then
        cmd+=(--tcl-prefix /usr/local)
    else
        cmd+=(--tcl-prefix ${TCL_HOME:-/usr})
    fi

    cmd+=(--with-fftw3 --fftw-prefix ${FFTW_HOME:-/usr})

    local python_version=$(python3 --version 2> /dev/null | cut -d' ' -f 2)
    python_version=${python_version%.*}
    if [ "x${python_version}" == "x3.6" ] || [ "x${python_version}" == "x3.7" ] || \
        [ "x${python_version}" == "x3.8" ] ; then
        # Currently does not build with >= 3.9 API
        cmd+=(--with-python)
    fi

    eval ${cmd[@]}

    if pushd ${dirname} ; then
        make -j$(nproc --all)
        ret_code=$?
        popd
    else
        ret_code=1
    fi

    if [ -n "${source_dir}" ] ; then
        popd
    fi

    return ${ret_code}
}


compile_namd_target "${@}"
