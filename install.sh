#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
CDBUFFER_SCRIPT="${SCRIPT_DIR}/cdbuffer.sh"

# check shell
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="${HOME}/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="${HOME}/.bashrc"
else
    SHELL_RC="${HOME}/.profile"
fi

echo "Installation of cdb in $SHELL_RC..."

chmod +x "$CDBUFFER_SCRIPT"

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
