#!/usr/bin/env bash 

# START FUNCTIONS ##############################
_cdb_internal() {
    usage() {
	cat << EOF
Usage: $0 [OPTIONS] [NUM]

"cd" command with macros of path to get quicker to often-used path.

Options:
	-l, --list			List of all macros and their associated path
	-c, --listcolor		List all macros but with colors
	-a, --add			Add a path to a macro
	-e, --empty			Empty a macro
	-r, --reset			Empty all macros
	-p, --print			Print the path associated to the macro. Useful as a substitution for pwd.
	-h, --help			Print this message
	--uninstall			Uninstall cdb

Examples:
> cdb 1
Go to the path associated to macro 1

> cdb -a 1:/path/to/remember
Add /path/to/remember to the macro 1

> cdb -e 1
Empty macro 1
EOF
	return 0
    }

confirmation() {
    IS_OK=false
    case $ACT_SHELL in
        zsh)    vared -p "Are you sure ? (Y/N) : " -c answer ;;
        bash)   read -r -p "Are you sure ? (Y/N) : " answer ;;
    esac

    case $answer in
	[Yy]*)
	    IS_OK=true
	    ;;
	[Nn]*)
		is_param=1
	    ;;
	*)
	    echo "Please answer Y or N."
		is_param=1
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
	# Check if the user has specified a macro and a path
	NBPARAM=$1
	MACROPATH=$2
	if [ $NBPARAM -lt 3 ] || [ -z "$MACROPATH" ]; then
		echo "You need to specify a macro and a path to add : cdb -a <macro>:<path>"
		return 1
	fi
	IFS=':' read -r LINE MPATH <<< "$MACROPATH" || return 1
	# Check if path is empty or macro is empty
	if [ -z "$MPATH" ]; then
		echo "You need to specify a macro and a path to add : no path specified."
		return 1
	elif [ -z "$LINE" ]; then
		echo "You need to specify a macro and a path to add : no macro specified."
		return 1
	fi

	# Check if the macro is between 1 and 9
	if [ $LINE -lt 1 ] || [ $LINE -gt 9 ]; then
		echo "You need to specify a macro between 1 and 9."
		return 1
	fi

	# Convert any relative path (for example, perso/test) to an absolute path.
	if [[ "$MPATH" != /* ]]; then
		if [[ "$MPATH" == ~* ]]; then
			# Replace the ~ by $HOME to not trigger the -d (sensible)
			case $ACT_SHELL in
				zsh)    MPATH=${~MPATH} ;;
				bash)   MPATH=${MPATH/#~/$HOME} ;;
			esac
		fi

		if [ -d "$MPATH" ]; then
			MPATH="$(cd "$MPATH" && pwd)"
		fi
	else
		echo "The directory you try to assign (${MPATH}) doesn't exist."
		return 1
	fi
	MPATH="$MPATH"

	sed -i "${LINE}c\\${green}${LINE}: ${MPATH} ${nc}" $cdbuffercolor
	sed -i "${LINE}c\\${LINE}: ${MPATH}" $cdbuffer

	echo "Macro $LINE has been set to $MPATH"

    return 0
}


empty_func() {
	if [ $1 -lt 2 ]; then
		echo "You need to specify a macro to empty."
		return 1
	fi
	LINE=$2
    confirmation
    if [ $IS_OK = true ]; then
	    sed -i "${LINE}c\\${red}${LINE}: [None] ${nc}" $cdbuffercolor
	    sed -i "${LINE}c\\${LINE}: [None]" $cdbuffer
    fi
    return 0
}


reset_func() {
	if [ $1 -eq 0 ]; then
    	confirmation
	fi
	
    if [[ $IS_OK = true ]]; then
		: > "$cdbuffercolor"
		: > "$cdbuffer"
		for i in $(seq 1 9); do
			printf '%s%s: [None] %s\n' "$red" "$i" "$nc" >> "$cdbuffercolor"
			printf '%s: [None]\n' "$i" >> "$cdbuffer"
		done
		echo "All macros have been reset."
    else
		echo "Reset cancelled."
		return 1
	fi
    return 0
}


print_func() {
	if [ $1 -lt 2 ]; then
		echo "You need to specify a macro to print."
		return 1
	fi
	LINE=$2

    line_file=$(sed -n "${LINE}p" $cdbuffer)
    IFS=':' read -r LINE MPATH <<< "$line_file" || return 1
	#remove useless space
	MPATH="${MPATH# }"
	if [ "$MPATH" == "[None]" ]; then
		echo "There's no path associated to that macro"
		return 1
	fi
    echo $MPATH
    return 0
}

goto() {
    line_file=$(sed -n "${LINE}p" $cdbuffer)
    IFS=':' read -r LINE MPATH <<< "$line_file" || return 1
    # Rid of useless space
    MPATH="${MPATH# }"


    if [ -d $MPATH ]; then
	    echo "cd $MPATH"
	    cd $MPATH
	    return 0
    else
	    echo "There's no path associated to that macro"
	    return 0
    fi
    
    return 1
}


# END FUNCTIONS ################################

SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%x}}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
is_param=0

# Check if zsh or bash
case "$(basename "$SHELL")" in
    zsh)    ACT_SHELL="zsh" ;;
    bash)   ACT_SHELL="bash" ;;
    *)      echo "Error : cdb is only available with bash or zsh at the moment."; exit 1; ;;
esac

cdbuffersh="${SCRIPT_DIR}/cdbuffer.sh"
cdbuffer="${SCRIPT_DIR}/cdbuffer"
cdbuffercolor="${SCRIPT_DIR}/cdbuffercolor"

# Color used
red=$'\033[0;31m'
green=$'\033[0;32m'
nc=$'\033[0m'

# Create buffers if not already done
if [ ! -f $cdbuffer ] || [ ! -f $cdbuffercolor ]; then
    echo "Init..."
    echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9" > "$cdbuffer"
    echo -e "1\n2\n3\n4\n5\n6\n7\n8\n9" > "$cdbuffercolor"
	validate=1
    reset_func $validate
fi

# Check if buffer files have either [None] or a path associated to them, if not, reset all macros
for i in $(seq 1 9); do
	line_file=$(sed -n "${i}p" $cdbuffer)
	IFS=':' read -r LINE MPATH <<< "$line_file" || return 1
	# Rid of useless space
	MPATH="${MPATH# }"
	if [ "$MPATH" != "[None]" ] && [ ! -d "$MPATH" ]; then
		echo "Macro $LINE has an invalid path associated to it. Resetting all macros."
		echo "Do not write anything in the buffer files, they will be reset otherwise."
		validate=1
		reset_func $validate
		is_param=1
		break
	fi
done


OPTS=$(getopt -o lcra:e:p:h --long list,listcolor,reset,uninstall,add:,empty:,print:,help -n 'cdb' -- "$@") || return 1

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


while true; do
    case "$1" in
	-a | --add)
		#$1 => -a
		#$2 => macro:path
	    add_func $# $2
		if [ $? -ne 0 ]; then
			return 1
		fi
	    shift 2
	    ;;
	-e | --empty)
	    empty_func $# $2
		if [ $? -ne 0 ]; then
			return 1
		fi
	    shift 2
	    ;;
	-p | --print)
	    print_func $# $2
		if [ $? -ne 0 ]; then
			return 1
		fi
	    return 0
	    shift 2
	    ;;
	-l | --list) 
	    list_func
		is_param=1
	    shift
	    ;;
	-c | --listcolor)
	    list_func_color
		is_param=1
	    shift
	    ;;
	-r | --reset)
		validate=0
	    reset_func $validate
		if [ $? -ne 0 ]; then
			return 1
		fi
		is_param=1
	    shift
	    ;;
	-h | --help) 
	    usage
		is_param=1
	    shift
	    ;;
	--uninstall)
		_cdb_uninstall
		return 0
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

if [ $# -eq 0 ] && [ $is_param -eq 0 ]; then
    list_func_color
    return 0
fi
}

_cdb_uninstall() {
	#TODO
	echo "Uninstalling cdb..."
	text_confirmation="Are you sure you want to uninstall cdb commandlet ? (Y/N) : "
	case $ACT_SHELL in
        zsh)    vared -p $text_confirmation -c answer; SHELL_RC=$HOME/.zshrc ;;
        bash)   read -r -p $text_confirmation answer; SHELL_RC=$HOME/.bashrc ;;
    esac


	case $answer in
	[Yy]*)
	    echo "Removing cdb commandlet from $SHELL_RC..."
	    sed -i '/# Start of cdb commandlet/,/# End of cdb commandlet/d' "$SHELL_RC"
		echo "Removing cdbuffer and cdbuffercolor files..."
	    rm -f "$cdbuffer" "$cdbuffercolor"
	    echo "Removing cdbuffer.sh from $SCRIPT_DIR..."
	    rm -f "$cdbuffersh"
	    # Functions loaded in the current shell survive removal of the startup
	    # file, so remove the command from this shell as well.
	    unset -f cdb _cdb_internal 2>/dev/null
	    unalias cdb 2>/dev/null
	    echo "Uninstallation completed."
	    ;;
	[Nn]*)
		echo "Uninstallation cancelled."
	    ;;
	*)
	    echo "Please restart the procedure and answer with Y or N."
	    ;;
    esac

}
