set -o pipefail
shopt -s expand_aliases
declare -ig __oo__insideTryCatch=0

alias try="[[ \$__oo__insideTryCatch -gt 0 ]] && set +e;
           __oo__insideTryCatch+=1; ( set -e;
           trap \"Exception.Capture \${LINENO}; \" ERR;"
alias catch=" ); Exception.Extract \$? || "

Exception.Capture() {
    local script="${BASH_SOURCE[1]#./}"

    if [[ ! -f $TMPDIR/stored_exception_source ]]; then
        echo "$script" > $TMPDIR/stored_exception_source
    fi
    if [[ ! -f $TMPDIR/stored_exception_line ]]; then
        echo "$1" > $TMPDIR/stored_exception_line
    fi
    return 0
}

Exception.Extract() {
    if [[ $__oo__insideTryCatch -gt 1 ]]
    then
        set -e
    fi

    __oo__insideTryCatch+=-1

    __EXCEPTION_CATCH__=( $(Exception.GetLastException) )

    local retVal=$1
    if [[ $retVal -gt 0 ]]
    then
        # BACKWARDS COMPATIBILE WAY:
        # export __EXCEPTION_SOURCE__="${__EXCEPTION_CATCH__[(${#__EXCEPTION_CATCH__[@]}-1)]}"
        # export __EXCEPTION_LINE__="${__EXCEPTION_CATCH__[(${#__EXCEPTION_CATCH__[@]}-2)]}"
        export __EXCEPTION_SOURCE__="${__EXCEPTION_CATCH__[-1]}"
        export __EXCEPTION_LINE__="${__EXCEPTION_CATCH__[-2]}"
        export __EXCEPTION__="${__EXCEPTION_CATCH__[@]:0:(${#__EXCEPTION_CATCH__[@]} - 2)}"
        return 1 # so that we may continue with a "catch"
    fi
}

Exception.GetLastException() {
    if [[ -f $TMPDIR/stored_exception ]] && [[ -f $TMPDIR/stored_exception_line ]] && [[ -f $TMPDIR/stored_exception_source ]]
    then
        cat $TMPDIR/stored_exception
        cat $TMPDIR/stored_exception_line
        cat $TMPDIR/stored_exception_source
    else
        echo -e " \n${BASH_LINENO[1]}\n${BASH_SOURCE[2]#./}"
    fi

    rm -f $TMPDIR/stored_exception $TMPDIR/stored_exception_line $TMPDIR/stored_exception_source
    return 0
}
