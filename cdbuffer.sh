#!/usr/bin/env bash 

# START FUNCTIONS ##############################
_cdb_internal() {
    usage() {
	cat << EOF
	Usage: $0 [OPTIONS] [NUM]

	"cd" command with macros of path to get quicker to often-used path.

	Options:
	-l, --list		List of all macros and their associated path
	-c, --listcolor		List all macros but with colors
	-a, --add		Add a path to a macro
	-e, --empty		Empty a macro
	-r, --reset		Empty all macros
	-p, --print		Print the path associated to the macro. Useful as a substitution for pwd.
	-h, --help		Print this message

	Examples:
	$0 1
	Go to the path associated to macro 1
	$0 -a 1:/path/to/remember
	Add /path/to/remember to the macro 1
	$0 -e 1
	Empty macro 1
	EOF
	return 0
    }

confirmation() {
    IS_OK=false
    #read -r -p "Are you sure ? (Y/N) : " answer
    #Better for zsh
    vared -p "Are you sure ? (Y/N) : " -c answer
    case $answer in
	[Yy]*)
	    IS_OK=true
	    ;;
	[Nn]*)
	    ;;
	*)
	    echo "Please answer Y or N."
	    ;;
    esac
}

list_func_color() {
    cat $cdbuffercolor
    return 0
}


list_func() {
    cat $cdbuffer
    return 0
}


add_func() {
    #Remplace le ~ par $HOME pour ne pas trigger le -d (il est sensible)
    #MPATH=${~MPATH}
    MPATH=${MPATH/#~/$HOME}
    if [ -d "$MPATH" ]; then
	sed -i "${LINE}c\\${green}${LINE}: ${MPATH} ${nc}" $cdbuffercolor
	sed -i "${LINE}c\\${LINE}: ${MPATH}" $cdbuffer
    else
	echo "The directory you try to assign (${MPATH}) doesn't exist."
	return 1
    fi
    return 1
}


empty_func() {
    confirmation
    if [ $IS_OK = true ]; then
	sed -i "${LINE}c\\${red}${LINE}: [None] ${nc}" $cdbuffercolor
	sed -i "${LINE}c\\${LINE}: [None]" $cdbuffer
    fi
    return 0
}


reset_func() {
    confirmation
    if [ $IS_OK = true ]; then
	for i in $(seq 1 9); do
	    sed -i "${i}c\\${red}${i}: [None] ${nc}" $cdbuffercolor
	    sed -i "${i}c\\${i}: [None]" $cdbuffer
	done
    fi
    return 0
}


print_func() {
    line_file=$(sed -n "${LINE}p" $cdbuffer)
    IFS=':' read -r LINE MPATH <<< "$line_file" || return 1
    echo $MPATH
    return 0
}

goto() {
    line_file=$(sed -n "${LINE}p" $cdbuffer)
    IFS=':' read -r LINE MPATH <<< "$line_file" || return 1
    #Enlève l'espace inutile
    MPATH="${MPATH# }"


    if [ -d $MPATH ]; then
	echo "cd $MPATH"
	cd $MPATH
	return 0
    else
	echo "There's no path associated to that macro"
	return 0
    fi
    # Au cas où ça dérape
    return 1
}

# END FUNCTIONS ################################

SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%x}}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"


cdbuffer="${SCRIPT_DIR}/cdbuffer"
cdbuffercolor="${SCRIPT_DIR}/cdbuffercolor"

# Création si ça n'est pas déjà fait des buffer
if [ ! -f $cdbuffer ] || [ ! -f $cdbuffercolor ]; then
    echo "Init..."
    echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9" > "$cdbuffer"
    echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9" > "$cdbuffercolor"
    reset_func
fi


OPTS=$(getopt -o lcra:e:p:h --long list,listcolor,reset,add:,empty:,print:,help -n 'main.sh' -- "$@") || return 1

# If can't get options
if [ $? -ne 0 ]; then
    echo "Failed to parse options" >&2
    usage
    return 1
fi

eval set -- "$OPTS"

# There shouldn't be more than 1 option used at the same time
count=0
for arg in "$@"; do
    [ "$arg" = "--" ] && break
    [[ "$arg" == -* ]] && count=$((count+1))
done
if [ $count -gt 1 ]; then
    echo "You can't parse more than 1 option."
    return 1
fi

# Color used
red=$'\033[0;31m'
green=$'\033[0;32m'
nc=$'\033[0m'



while true; do
    case "$1" in
	-a | --add)
	    IFS=':' read -r LINE MPATH <<< "$2" || return 1
	    MPATH="$MPATH"
	    add_func
	    shift 2
	    ;;
	-e | --empty)
	    LINE=$2
	    empty_func
	    shift 2
	    ;;
	-p | --print)
	    LINE=$2
	    print_func
	    shift 2
	    ;;
	-l | --list) 
	    list_func
	    shift
	    ;;
	-c | --listcolor)
	    list_func_color
	    shift
	    ;;
	-r | --reset)
	    reset_func
	    shift
	    ;;
	-h | --help) 
	    usage
	    shift
	    ;;
	--)
	    shift
	    break
	    ;;
	*)
	    echo "Internal error !"
	    return 1
	    ;;
    esac
done

if [ $# -eq 1 ]; then
    LINE=$1
    goto
fi
# If more than 1 number of line used
if [ $# -gt 1 ]; then
    echo "You should not use more than 1 line in any command."
    return 1
fi

if [ $# -eq 0 ]; then
    list_func_color
    return 0
fi
}
