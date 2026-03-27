#!/usr/bin/env bash
# @description Template for sub-command scripts (not a real command)
# @require <Required function list splited by space> (optional)
#
# This file demonstrates the sub-command convention for this.d/ scripts.
# Copy it to create a new sub-command:
#
#   cp this.d/_template.sh this.d/my-command.sh
#   chmod +x this.d/my-command.sh
#
# Convention:
#   - Shebang line: #!/usr/bin/env bash
#   - Description:  # @description <short description>
#   - Strict mode:  set -euo pipefail
#   - Standalone:   Must work when executed directly (bash this.d/my-command.sh)
#   - Via this.sh:  Also works when dispatched (this.sh my-command)
#
# Files prefixed with _ are excluded from the help listing and dispatch.

set -euo pipefail

echo "This is a template. Copy it to create a new sub-command."
echo "Arguments received: $*"
