#!/usr/bin/env bash

function setupVars() {
    local nixStateDir="${NIX_STATE_DIR:-/nix/var/nix}"
    local profilesPath="$nixStateDir/profiles/per-user/$USER"
    local gcPath="$nixStateDir/gcroots/per-user/$USER"

    declare -gr genProfilePath="$profilesPath/home-manager"
    declare -gr newGenPath="@GENERATION_DIR@";
    declare -gr newGenGcPath="$gcPath/current-home"

    local greatestGenNum
    greatestGenNum=$( \
        find "$profilesPath" -name '@GEN_LINK_PREFIX@-*-link' \
            | sed 's/^.*-\([0-9]*\)-link$/\1/' \
            | sort -rn \
            | head -1)

    if [[ -n $greatestGenNum ]] ; then
        declare -gr oldGenNum=$greatestGenNum
        declare -gr newGenNum=$((oldGenNum + 1))
    else
        declare -gr newGenNum=1
    fi

    if [[ -e $gcPath/@GC_LINK_NAME@ ]] ; then
        oldGenPath="$(readlink -e "$gcPath/@GC_LINK_NAME@")"
    fi

    $VERBOSE_RUN _i "Sanity checking oldGenNum and oldGenPath"
    if [[ -v oldGenNum && ! -v oldGenPath
            || ! -v oldGenNum && -v oldGenPath ]]; then
        errorEcho "Invalid profile number and GC root values! These must be"
        errorEcho "either both empty or both set but are now set to"
        errorEcho "    '${oldGenNum:-}' and '${oldGenPath:-}'"
        errorEcho "If you don't mind losing previous profile generations then"
        errorEcho "the easiest solution is probably to run"
        errorEcho "   rm $profilesPath/@GEN_LINK_PREFIX@*"
        errorEcho "   rm $gcPath/@GC_LINK_NAME@"
        errorEcho "and trying home-manager switch again. Good luck!"
        exit 1
    fi


    genProfilePath="$profilesPath/@GEN_LINK_PREFIX@"
    newGenPath="@GENERATION_DIR@";
    newGenProfilePath="$profilesPath/@GEN_LINK_PREFIX@-$newGenNum-link"
    newGenGcPath="$gcPath/@GC_LINK_NAME@"
}

if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
    export VERBOSE_RUN=""
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
    export VERBOSE_RUN=true
fi

_i "Starting Home Manager activation"

# Verify that we can connect to the Nix store and/or daemon. This will
# also create the necessary directories in profiles and gcroots.
$VERBOSE_RUN _i "Sanity checking Nix"
nix-build --expr '{}' --no-out-link

setupVars

if [[ -v DRY_RUN ]] ; then
    _i "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_RUN _i "This is a live run"
    export DRY_RUN_CMD=""
fi

if [[ -v VERBOSE ]]; then
    _i 'Using Nix version: %s' "$(nix-env --version)"
fi

$VERBOSE_RUN _i "Activation variables:"
if [[ -v oldGenNum ]] ; then
    $VERBOSE_ECHO "  oldGenNum=$oldGenNum"
    $VERBOSE_ECHO "  oldGenPath=$oldGenPath"
else
    $VERBOSE_ECHO "  oldGenNum undefined (first run?)"
    $VERBOSE_ECHO "  oldGenPath undefined (first run?)"
fi
$VERBOSE_ECHO "  newGenPath=$newGenPath"
$VERBOSE_ECHO "  newGenNum=$newGenNum"
$VERBOSE_ECHO "  newGenGcPath=$newGenGcPath"
$VERBOSE_ECHO "  genProfilePath=$genProfilePath"
