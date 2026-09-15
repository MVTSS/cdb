#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
SRC_SCRIPT="${SCRIPT_DIR}/cdbuffer.sh"

# check shell
case "$(basename "$SHELL")" in
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

if grep -q "cdbuffer.sh" "$SHELL_RC" 2>/dev/null; then
    echo "cdb is already configured in $SHELL_RC."
else
    cat << EOF >> "$SHELL_RC"

# For cdb commandlet
source ${CDBUFFER_SCRIPT}
cdb() {
    _cdb_internal "\$@"
}
EOF
    echo "Configuration added with success in $SHELL_RC !"
fi

echo "Installation completed ! Recharge your file with the following command : source $SHELL_RC"
