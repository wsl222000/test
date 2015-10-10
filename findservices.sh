#!/bin/bash

. /etc/.profile
. $CCRUN/bin/shellfuns.sh

declare -a HOSTS=( $SYSLIST )

declare REQ_UID=$(perl -e "print scalar getpwuid ((stat '$CCSYSDIR/CHKDAEMONS.cf')[4])")

declare BLATHER=false

declare NOT_DEAD_YET=false

declare NCRONTAB


function usage()
{
    (( $# > 0 )) && return 1

    echo -e "\nusage: $(basename $0) [-s service] [-b by_key] [-v] [-2] [host ...]

    If hosts given, report only services on those hosts
       (otherwise all hosts in \$SYSLIST).

    -s only reports on the given service, which may be one of:\n"

    local S
    for S in "${SERVICES[@]}" ; do
        echo "$S"
    done | column -c 60 | expand | perl -p -e 'print " "x7'
    echo -e "
       Matching is case-insensitive.  Prefix matching is done, first
       match found is used (ex: given just 'hl', will match HL7inbound).
    
    -b sorts by given key: 'service' or 'host' (default is host).

    -v creates verbose output with more detailed, unobscured data values.

    -2 double-spaces the output lines, for easier reading.
    
    Requires user id '$REQ_UID' to run beyond printing this help.\n"

    return 0
}


function barf()
{
    echo "!!! ${FUNCNAME[1]}(${BASH_LINENO[0]}) $*" >&2

    exit 1
}


function blather()
{
    [[ $BLATHER == 'true' ]] && echo "+ ${FUNCNAME[1]}(${BASH_LINENO[0]}) $*" >&2

    return 0
}


function field()
{
    (( $# != 1 )) && return 1

    awk "{print \$$1}"

    return $?
}


function runOn()
{
    (( $# < 2 )) && return 1

    local H=$1 ; shift
    blather "$H, $*"

    $NOT_DEAD_YET && echo -n '. ' >&2

    if [[ $H == $HOST ]] ; then
        eval $* 
    else
        ssh $H ". /etc/.profile ; $*"
    fi

    return $?
}


function service()
{
    (( $# > 0 )) && return 1

    local -i I=1
    while [[ ${FUNCNAME[$I]} != 'main' &&
             ${FUNCNAME[$I]##*goFind_} == ${FUNCNAME[$I]} ]] ; do
        (( I += 1 ))
    done
    [[ ${FUNCNAME[$I]} != 'main' ]] && echo "${FUNCNAME[I]##*goFind_}"

    return 0
}


function found()
{
    (( $# < 1 )) && return 1

    local H="$1" ; shift
    echo -n "$H $(service)"
    local STUFF="$*"
    if (( $# > 0 )) ; then
        ! $VERBOSE && STUFF="$(perl -p -e 's/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.(\d{1,3})\b/x.x.x.$1/g' <<< "$STUFF")"
        echo -n ": $STUFF"
    fi
    echo

    return 0
}

function printNumItemsOnHosts()
{
    blather "item_hosts $*"  

    (( $# < 1 )) && return 0

    for H in "${HOSTS[@]}" ; do

        local -i NUM_ITEMS_ON_H=0
        for IH in "$@" ; do
            [[ $IH == $H ]] && (( NUM_ITEMS_ON_H += 1 ))
        done

        blather "$H num_items $NUM_ITEMS_ON_H"
        (( $NUM_ITEMS_ON_H > 0 )) && found "$H" "$NUM_ITEMS_ON_H"
    done

    return 0
}


function getNcrontab()
{
    (( $# > 0 )) && return 1

    if [[ -z $NCRONTAB ]] ; then

        [[ -r "$CCSYSDIR/ncrontab" ]] || return 2

        local PRIMARY_HOST

        while read LINE ; do

            case ${LINE%%[[:blank:]]*} in
            \* )
                for H in "${HOSTS[@]}" ; do
                    NCRONTAB+="${LINE/#\*/$H}"$'\n'
                done
                ;;
            \. )
                if [[ -z $PRIMARY_HOST ]] ; then
                    for H in "${HOSTS[@]}" ; do
                        netping $H >& /dev/null && PRIMARY_HOST="$H" && break
                    done
                fi
                [[ -n $PRIMARY_HOST ]] && NCRONTAB+="${LINE/#\./$PRIMARY_HOST}"$'\n'
                ;;
            *  )
                NCRONTAB+="$LINE"$'\n'
                ;;
            esac

        done < <(grep -v -P '^\s*(\#.*)?$' "$CCSYSDIR/ncrontab")

        blather 'ncrontab ' $(wc <<< "$NCRONTAB")
    fi

    return 0
}


function goFind_BHIE()
{
    (( $# > 0 )) && return 1

    getNcrontab
    local H
    for H in "${HOSTS[@]}" ; do

        local BH
        for BH in $(grep -F 'notesExpDisch' <<< "$NCRONTAB" |
                    field 1) ; do
            blather "bh '$BH', h '$H'"

            if [[ $BH == $H ]] && runOn "$H" "ps -C notesExpd -o command= |
                                              grep -F -w -q -- '$CAMPUS'" ; then
                found "$H"
                break
            fi

        done
    done

    return 0
}


function goFind_ConfigTool()
{
    (( $# > 0 )) && return 1

    if [[ -r $CCSYSDIR/ConfigTool.rcf ]] ; then

        local CFT_PRIM_HOST=$(gethostresource ConfigTool.PrimaryHost "$CCSYSDIR/ConfigTool.rcf")
        blather "cft_prim_host='$CFT_PRIM_HOST'"

        local H
        for H in "${HOSTS[@]}" ; do
            [[ $H == $CFT_PRIM_HOST ]] && found "$H" && break
        done

    else
        found "$HOST" "not configured"
    fi

    return 0
}


function goFind_DietReports()
{
    (( $# > 0 )) && return 1

    getNcrontab
    printNumItemsOnHosts $(grep -E -w 'diet.*\.scm' <<< "$NCRONTAB" |
                           field 1)
    return 0
}


function goFind_FMRDs()
{
    (( $# > 0 )) && return 1

    local -a STRINGS=( $(find "$CCRUN/ccexe" \
                              -name .xsession \
                              -exec grep -l fmDisplay \{\} \+ |
                         perl -lne 'm|^'"$CCRUN/ccexe"'/([^/]+)| && print $1' |
                         sort -u) )
    blather "${#STRINGS[*]} strings: ${STRINGS[*]}"

    local REGEX=$(IFS='|' ; echo "${STRINGS[*]}")
    blather "regex '$REGEX'"

    local -a FMRDS

    if [[ -n $REGEX ]] ; then

        local DEVICE
        for DEVICE in $(grep '^fetal' "$EERUN/conf/CCIconfig.bcf" 2> /dev/null |
                        field 1) ; do

            local LINE=$(grep -v '^#' "$EERUN/daemons/boottab" 2> /dev/null |
                         grep -P '^'"$DEVICE"'\s')
            blather "device '$DEVICE', line '$LINE'"

            grep -q -P '\s('"$REGEX"')\s' <<< "$LINE" && FMRDS+=( "$DEVICE" )
            blather "${#FMRDS[*]} fmrds: ${FMRDS[*]}"

        done
    fi
    
    if (( ${#FMRDS[*]} > 0 )) ; then

        REGEX=$(IFS='|' ; echo "${FMRDS[*]}")
        blather "regex '$REGEX'"

        printNumItemsOnHosts $(term_query |
                               grep -E '^('"$REGEX"')[[:space:]]' |
                               field 2)
    fi

    return 0
}


function goFind_GDRfeed()
{
    (( $# > 0 )) && return 1

    local -a FEEDS=( $(gethostresource transDumpOra.gdrhosts "$CCSYSDIR/ccResources") )
    blather "${#FEEDS[*]} feeds: ${FEEDS[*]}"

    local H
    for H in "${HOSTS[@]}" ; do
        local F
        for F in "${FEEDS[@]}" ; do
            [[ $H == $F ]] && found "$H" && break
        done
    done

    return 0
}


function goFind_GDRreports()
{
    (( $# > 0 )) && return 1

    getNcrontab
    printNumItemsOnHosts $(grep -E '\bcreateRep.*\b[Gg][Dd][Rr]' <<< "$NCRONTAB" |
                           field 1)
    return 0
}


function goFind_GDRsHosted()
{
    (( $# > 0 )) && return 1

    local -a GDR_HOSTS=( $(grep -i -E '^gdr[[:digit:]]*\.dbstring' "$CCSYSDIR/ccResources" |
                           cut -d\: -f2) )
    blather "${#GDR_HOSTS[*]} gdr_hosts: ${GDR_HOSTS[*]}"

    if (( ${#GDR_HOSTS[*]} > 0 )) ; then

        local REGEX=$(IFS='|' ; echo "${GDR_HOSTS[*]}")
        blather "regex '$REGEX'"

        local H
        for H in "${HOSTS[@]}" ; do

            local -a HOSTED=( $(runOn "$H" 'ifconfig -a' |
                                perl -n -e 'm/^\w+\:('"$REGEX"')\s/ and print "$1\n"') )
            blather "h '$H', ${#HOSTED[*]} hosted: ${HOSTED[*]}"

            (( ${#HOSTED[*]} > 0 )) && found "$H" "${HOSTED[*]}"
        done 
    fi

    return 0
}


function goFind_HL7inbound()
{
    (( $# > 0 )) && return 1

    local ALIAS_LINE=$(grep '\b'"${CAMPUS}"'-hl7\b' /etc/hosts 2> /dev/null |
                       grep -v '^\#')
    blather "alias_line '$ALIAS_LINE'"

    local ALIAS=$(field 2 <<< "$ALIAS_LINE")
    local ALIAS_IP=$(field 1 <<< "$ALIAS_LINE")
    blather "alias '$ALIAS', alias_ip '$ALIAS_IP'"

    if [[ -n $ALIAS && -n $ALIAS_IP ]] ; then 

        local H
        for H in "${HOSTS[@]}" ; do

            if runOn "$H" "ifconfig -a" |
               grep -E -q 'addr: ?'"$ALIAS_IP"' ' ; then
                found "$H" "Network alias $ALIAS ($ALIAS_IP) active"
            fi

        done
    fi

    local LOGS_FILTER="grep -E -v 'ordersin\$'"
    $VERBOSE && LOGS_FILTER='cat'

    local LOG
    for LOG in $(ps -fu cis |
                 perl -ne 'm|\bhl7server\s.*?(\S*hl7log\S*'"$CAMPUS"'\S*)| and print "$1\n"' |
                 eval $LOGS_FILTER |
                 sort -u) ; do
        blather "log '$LOG'"

        local -i HL7_LAST_UPDATE=0
        local HL7_LAST_UPDATE_HOST=''

        local H
        for H in "${HOSTS[@]}" ; do

            local -i UPDATE=$(runOn "$H" "stat \"$LOG\" 2>/dev/null" |
                              grep -F 'st_mtime' |
                              field 2)
            blather "h '$H', update '$UPDATE', hl7_last_update '$HL7_LAST_UPDATE'"

            if (( $UPDATE > $HL7_LAST_UPDATE )) ; then
                (( HL7_LAST_UPDATE = $UPDATE ))
                HL7_LAST_UPDATE_HOST=$H
                blather "h '$H', hl7_last_update_host '$HL7_LAST_UPDATE_HOST'"
            fi

        done

        [[ -z $HL7_LAST_UPDATE_HOST ]] && continue

        local -i HL7_SIZE=$(runOn "$HL7_LAST_UPDATE_HOST" "stat \"$LOG\" 2>/dev/null" |
                            grep -F 'st_size' |
                            field 2)
        blather "hl7_size '$HL7_SIZE'"
        (( $HL7_SIZE <= 0 )) && continue

        local RESULT
        local DELIM=$(runOn "$HL7_LAST_UPDATE_HOST" "grep 'HL7 data' \"$LOG\" 2> /dev/null |
                      tail -1" |
                      cut -c31)
        blather "delim '$DELIM'"

        if [[ -n $DELIM ]] ; then 

            local -a APPS=($(runOn "$HL7_LAST_UPDATE_HOST" "grep '\[MSH' \"$LOG\" 2> /dev/null" |
                             cut -d"$DELIM" -f3 |
                             sort -u) )
            blather "apps '$APPS'"

            if (( ${#APPS[@]} > 0 )) ; then
                $VERBOSE && RESULT="${APPS[*]} in "
            else
                RESULT='no source detected in '
            fi

        else
            RESULT='no msgs detected in '
        fi
        blather "result '$RESULT'"

        ! $VERBOSE && LOG="${LOG##*\.}"
        blather "log '$LOG'"

        found "$HL7_LAST_UPDATE_HOST" "$RESULT$LOG ($(ccitime $HL7_LAST_UPDATE))"

    done

    return 0
}


function goFind_HL7outbound()
{
    (( $# > 0 )) && return 1

    local H
    for H in "${HOSTS[@]}" ; do
        if runOn "$H" 'ps -fu cis |
                       grep -v "grep" | 
                       grep -F -- "'"$CAMPUS"'" | 
                       grep -F -q TransShell' ; then 

            local -a OUTERS=( $(runOn "$H" 'F="$CCSYSDIR/outbound/conf/outbound.'"$H"'.rcf" ;
                                            [[ -r $F ]] || F="$CCSYSDIR/outbound/conf/outbound.rcf" ;
                                            grep -i "^remoteserver[1-9].servername" "$F" 2> /dev/null |
                                            grep -v \^\#' |
                                cut -d\: -f2) )
            blather "${#OUTERS[*]} outers: ${OUTERS[*]}"

            if (( ${#OUTERS[*]} > 0 )) ; then

                if ! $VERBOSE ; then

                    local -i I
                    for (( I = 0 ;  $I < "${#OUTERS[@]}" ; I += 1 )) ; do
                        blather "i '$I', outer[$I] '${OUTERS[$I]}'"
                        [[ ${OUTERS[$I]} == $H ]] && unset OUTERS[$I]
                    done

                fi

                blather "num outers '${#OUTERS[*]}'"
                (( ${#OUTERS[*]} > 0 )) && found "$H" ${OUTERS[*]}

            fi
        fi
    done

    return 0
}


function goFind_HostInfo()
{
    (( $# > 0 )) && return 1

    local H
    for H in "${HOSTS[@]}" ; do
        found "$H" $(runOn "$H" "echo \$(version -v) \$(uname -sr) \$(sed -e 's/Red Hat Enterprise Linux Server release/RHEL/' '/etc/redhat-release' 2> /dev/null)")
    done 

    return 0
}


function goFind_Notification()
{
    (( $# > 0 )) && return 1

    [[ -r "$CCSYSDIR/notification.rcf" ]] || return 0

    local ENABLED=$(gethostresource notification.enable "$CCSYSDIR/notification.rcf")
    blather "enabled '$ENABLED'"

    if [[ $ENABLED == [TtYy1]* ]] ; then

        local WORK_HOST=$(gethostresource notification.workhost "$CCSYSDIR/notification.rcf")
        blather "work_host '$WORK_HOST'"

        local H
        for H in "${HOSTS[@]}" ; do
            [[ $H == $WORK_HOST ]] && found "$H" 'workhost'
        done
    fi

    return 0
}


function goFind_OnWatch()
{
    (( $# > 0 )) && return 1

    if [[ -r "$CCSYSDIR/OnWatch.rcf" ]] ; then

        local MAIN_HOST_ID=$(grep -E -i '^OnWatch.mainurl[[:space:]]*:' "$CCSYSDIR/OnWatch.rcf" 2> /dev/null |
                             tail -1 |
                             sed 's#.*//##')
        local MAIN_HOST_NAME=$(grep -F -w -- "$MAIN_HOST_ID" /etc/hosts 2> /dev/null |
                               grep -E -v '^[[:space:]]*\#' |
                               field 2)
        blather "main_host_id '$MAIN_HOST_ID', main_host_name '$MAIN_HOST_NAME'"

        local ENABLED=$(gethostresource OnWatch.useonwatch2 "$CCSYSDIR/OnWatch.rcf")
        blather "enabled '$ENABLED'"

        local WORK_HOST
        if [[ $ENABLED == [TtYy1]* ]] ; then
            WORK_HOST=$(gethostresource OnWatch.WorkHost "$CCSYSDIR/OnWatch.rcf")
        fi
        blather "work_host '$WORK_HOST'"

        local H
        for H in "${HOSTS[@]}" ; do
            [[ $H == $MAIN_HOST_NAME ]] && found "$H" 'main'
            [[ $H == $WORK_HOST ]] && found "$H" 'workhost'
        done
    fi

    return 0
}


function goFind_PatTaskList()
{
    (( $# > 0 )) && return 1

    [[ -r "$CCSYSDIR/PatTaskList.rcf" ]] || return 0
      
    local DISABLED=$(gethostresource PTL.disable "$CCSYSDIR/PatTaskList.rcf")
    blather "disabled '$DISABLED'"

    if [[ $DISABLED != [TtYy1]* ]] ; then

        local WORK_HOST=$(gethostresource PTL.workhost "$CCSYSDIR/PatTaskList.rcf")
        blather "work_host '$WORK_HOST'"

        local H
        for H in "${HOSTS[@]}" ; do
            [[ $H == $WORK_HOST ]] && found "$H" 'workhost'
        done
    fi

    return 0
}


function goFind_UserLoad()
{
    (( $# > 0 )) && return 1

    local H
    for H in "${HOSTS[@]}" ; do

        local ACT=$(runOn "$H" 'activeterminals 5')
        blather "h '$H', act '$ACT'"

        local -i USERS=0

        [[ $ACT != *No\ activity* ]] && (( USERS = $(wc -l <<< "$ACT") ))

        found "$H" "$USERS"
    done

    return 0
}

        
function goFind_Vhosts()
{
    (( $# > 0 )) && return 1

    local H
    for H in "${HOSTS[@]}" ; do

        local -a VHOSTS_ON_H=( $(runOn "$H" 'ps -C qemu-kvm >& /dev/null &&
                                             virsh -r -c qemu:///system list --all' |
                                 grep -w 'running$' |
                                 field 2) )
        blather "h '$H', ${#VHOSTS_ON_H[*]} vhosts_on_h: ${VHOSTS_ON_H[*]}"

        (( ${#VHOSTS_ON_H[*]} > 0 )) && found "$H" "KVM Guests: ${VHOSTS_ON_H[*]}"
    done

    return 0
}


function goFind_VistaImage()
{
    (( $# > 0 )) && return 1

    if [[ -r "$CCSYSDIR/OutboundReport.rcf" &&
          $(gethostresource VistA.SendToImaging "$CCSYSDIR/OutboundReport.rcf") == [TtYy1]* ]] ; then

        local H
        getNcrontab

        local PRIMARY_HOST=$(grep -F -w 'OutboundRep' <<< "$NCRONTAB" | 
                             grep -F -w -v 'PRINT_CHART' | 
                             head -1 |
                             field 1)
        blather "primary_host '$PRIMARY_HOST'"

        if [[ -n $PRIMARY_HOST ]] ; then

            for H in "${HOSTS[@]}" ; do
                [[ $H == $PRIMARY_HOST ]] && found "$H" 'primary host' && break
            done

        fi

        local HL7_IP=$(grep -F -w -- "${CAMPUS}-hl7" /etc/hosts 2> /dev/null |
                       grep -E -v '^[[:space:]]*\#' |
                       field 1)
        blather "hl7_ip '$HL7_IP'"

        for H in "${HOSTS[@]}" ; do

            runOn "$H" 'netstat -n --numeric-ports -l -p 2>/dev/null |
                        grep -F -- ":445"' |
            grep -q -- "$HL7_IP" && found "$H" 'SMB'

        done

        if $VERBOSE ; then

          for H in "${HOSTS[@]}" ; do

              local CONNS=$(runOn "$H" 'smbstatus -S 2>/dev/null' |
                                        perl -a -n -e 'push @a, "(service $F[0] machine $F[2])"
                                               if $a and $F[0] eq "'"$CAMPUS"'";
                                           m/------/ and $a=1;
                                           END {print join " ", @a}')
              blather "h '$H', conns '$CONNS'"

              [[ -n $CONNS ]] && found "$H" "SMB connections: $CONNS"

          done

        fi
        
    fi

    return 0
}


declare -a SERVICES=( $(typeset -F |
                        perl -a -n -e '$F[2] =~ m/^goFind_(.*)/ and print "$1\n"' |
                        sort) )
declare SERVICE
declare -a SORT_KEYS=( '--key=1,1' '--key=2,2' )
declare SPACER=cat
declare VERBOSE=false

while getopts "2b:ds:vh" OPTION
do
    case $OPTION in
    2)  SPACER='sed G'
        ;;
    b)  case $OPTARG in
        host)    SORT_KEYS=( '--key=1,1' '--key=2,2' ) ;;
        service) SORT_KEYS=( '--key=2,2' '--key=1,1' ) ;;
        *)  echo -e '\nsort key must be one of: host service' >&2
            usage >&2
            exit 1
            ;;
        esac
        ;;
    d)  BLATHER=true
        ;;
    s)  SERVICE="$OPTARG"
        ;;
    v)  VERBOSE=true
        ;;
    h)  usage
        exit 0
        ;;
    \?) usage >&2
        exit 1
        ;;
    esac
done

shift $(( $OPTIND-1 ));

(( $# )) && HOSTS=( "$@" )
blather "hosts: ${HOSTS[*]}"

! $BLATHER && [[ -z $SERVICE && -t 2 ]] && NOT_DEAD_YET=true

if [[ $(whoami) != $REQ_UID ]] ; then 
    echo "Must have user id '$REQ_UID'." >&2
    exit 1
fi

blather "service: '$SERVICE'"
if [[ -n $SERVICE ]] ; then

    declare LOW_SERVICE=$(tr '[:upper:]' '[:lower:]' <<< "$SERVICE")
    declare S
    for S in "${SERVICES[@]}" ; do

        declare LOW_S=$(tr '[:upper:]' '[:lower:]' <<< "$S")
        if [[ $LOW_S == $LOW_SERVICE* ]] ; then

            blather "doing goFind_$S on ${HOSTS[*]}"
            goFind_$S || barf "bad result $? from goFind_$S"

            unset SERVICE
            break
        fi

    done

    if [[ -n $SERVICE ]] ; then
        echo -e "\nNo such service as '$SERVICE'\n" >&2
        usage >&2
        exit 1
    fi

    echo -e "\n" >&2

else

    declare S
    for S in "${SERVICES[@]}" ; do

        $NOT_DEAD_YET && echo -n '. ' >&2

        blather "doing goFind_$S on ${HOSTS[*]}"
        goFind_$S || barf "bad result $? from goFind_$S"

    done

    echo -e "\n" >&2

fi | sort --ignore-leading-blanks --stable "${SORT_KEYS[@]}" | $SPACER

exit 0
