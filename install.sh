#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SRC_SCRIPT="${SCRIPT_DIR}/cdbuffer.sh"

# check shell
case "$(basename -- "$SHELL")" in
    zsh)    SHELL_RC="${HOME}/.zshrc" ;;
    bash)   SHELL_RC="${HOME}/.bashrc" ;;
    *)      echo "Error : cdb is only available with bash or zsh at the moment."; exit 1; ;;
esac

TARGET_DIR=""
IFS=':' read -ra PATH_DIRS <<< "$PATH"
for dir in "${PATH_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        TARGET_DIR="$dir"
        break
    fi
done

if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="${HOME}/.local/bin"
    mkdir -p "$TARGET_DIR"
fi

CDBUFFER_SCRIPT="${TARGET_DIR}/cdbuffer.sh"

echo "Copie de cdbuffer.sh vers $CDBUFFER_SCRIPT..."
if [ "$SRC_SCRIPT" != "$CDBUFFER_SCRIPT" ]; then
    cp "$SRC_SCRIPT" "$CDBUFFER_SCRIPT"
fi
chmod +x "$CDBUFFER_SCRIPT"



echo "Installation of cdb in $SHELL_RC..."


# TODO :
# - Check if installed in another shell (remove duplicate)
# - Check if the cdbuffer_script is the same as in the shell => wrong source if double install / update

CURRENT_CDB=$(grep -A1 "# Start of cdb commandlet" "$SHELL_RC" | grep "^source " | awk '{print $2}')
CURRENT_CDB_PATH="$(dirname -- "$CURRENT_CDB")"

if [ -z "$CURRENT_CDB" ]; then
    echo "cdb is not configured in $SHELL_RC."
        cat << EOF >> "$SHELL_RC"

# Start of cdb commandlet
source ${CDBUFFER_SCRIPT}
cdb() {
    _cdb_internal "\$@"
}
# End of cdb commandlet

EOF
    echo "Configuration added with success in $SHELL_RC !"
elif [ "$CURRENT_CDB" != "$CDBUFFER_SCRIPT" ]; then
    echo "cdb is already configured in $SHELL_RC but with a different path : $CURRENT_CDB"
    sed -i '/^# Start of cdb commandlet/,/^# End of cdb commandlet/d' "$SHELL_RC"
    cat << EOF >> "$SHELL_RC"

# Start of cdb commandlet
source ${CDBUFFER_SCRIPT}
cdb() {
    _cdb_internal "\$@"
}
# End of cdb commandlet

EOF
    echo "Configuration updated with success in $SHELL_RC !"
    echo "Moving existing cdbuffer.sh, cdbuffer and cdbuffercolor from $CURRENT_CDB_PATH to $TARGET_DIR..."
    if [ -f "$CURRENT_CDB" ]; then
        mv "$CURRENT_CDB" "$CDBUFFER_SCRIPT"
        echo "=> Moved existing cdbuffer.sh to $CDBUFFER_SCRIPT"
    fi
    if [ -f "$CURRENT_CDB_PATH/cdbuffer" ]; then
        mv "$CURRENT_CDB_PATH/cdbuffer" "$TARGET_DIR/cdbuffer"
        echo "=> Moved existing cdbuffer to $TARGET_DIR/cdbuffer"
    fi
    if [ -f "$CURRENT_CDB_PATH/cdbuffercolor" ]; then
        mv "$CURRENT_CDB_PATH/cdbuffercolor" "$TARGET_DIR/cdbuffercolor"
        echo "=> Moved existing cdbuffercolor to $TARGET_DIR/cdbuffercolor"
    fi

else
    echo "cdb is already configured in $SHELL_RC."
    echo "Updating cdbuffer.sh in $CDBUFFER_SCRIPT..."
fi


echo "Installation completed ! Recharge your file with the following command : source $SHELL_RC"
