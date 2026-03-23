#!/bin/bash
. "/usr/local/lib/gsx-messages.sh"

echo -e "\n"
info "=== WEEK 4 SECURITY & LIMITS VERIFICATION ==="

TEST_USER="dev1"

if ! id "$TEST_USER" &>/dev/null; then
    error "User $TEST_USER does not exist. Run the setup first."
fi
test = '0' # Counter for passed tests
# ---- ACCESS TESTS (Access Control) ----

info "--- Testing Access Control ---"

BIN_PERMS=$(stat -c "%A" /home/greendevcorp/bin)

if [ "$BIN_PERMS" == "drwxr-x---" ]; then
    success "/bin folder permissions correct: $BIN_PERMS (0750)"
    test=$((test + 1))
else
    warning "/bin folder permissions incorrect: $BIN_PERMS"
fi

SHARED_PERMS=$(stat -c "%A" /home/greendevcorp/shared)

if [ "$SHARED_PERMS" == "drwxrws--T" ]; then
    success "/shared folder permissions correct: $SHARED_PERMS (3770 -> SGID + Sticky)"
    test=$((test + 1))
else
    warning "/shared folder permissions incorrect: $SHARED_PERMS"
fi

LOG_PERMS=$(stat -c "%A" /home/greendevcorp/done.log)
LOG_OWNER=$(stat -c "%U" /home/greendevcorp/done.log)

if [ "$LOG_PERMS" == "-rw-r--r--" ] && [ "$LOG_OWNER" == "dev1" ]; then
    success "done.log permissions correct: $LOG_PERMS (Owned by $LOG_OWNER)"
    test=$((test + 1))
else
    warning "done.log permissions incorrect: $LOG_PERMS / $LOG_OWNER"
fi

# ---- LIMITS TESTS (Resource Limits) ----

info "--- Testing Resource Limits (PAM) ---"

# Switch to dev1 and use ulimit to check hard limits
# -Hu = Hard max user processes
# -Hn = Hard max open files

MAX_PROCS=$(su - "$TEST_USER" -c "ulimit -Hu")
MAX_FILES=$(su - "$TEST_USER" -c "ulimit -Hn")

if [ "$MAX_PROCS" -eq 700 ]; then
    success "Max processes correctly enforced to: 700"
    test=$((test + 1))
else
    warning "Max processes limit failed: $MAX_PROCS"
fi

if [ "$MAX_FILES" -eq 4096 ]; then
    success "Max open files correctly enforced to: 4096"
    test=$((test + 1))
else
    warning "Max open files limit failed: $MAX_FILES"
fi

# ---- ENVIRONMENT TEST (Environment Personalization) ----

info "--- Testing Environment Inheritance ---"

# Check if dev1 PATH contains shared bin folder
USER_PATH=$(su - "$TEST_USER" -c "echo \$PATH")
if echo "$USER_PATH" | grep -q "/home/greendevcorp/bin"; then
    success "PATH inherited correctly: contains /home/greendevcorp/bin"
    test=$((test + 1))
else
    warning "PATH inheritance failed."
fi

# Check aliases loaded correctly
USER_ALIASES=$(su - "$TEST_USER" -c "alias")
if echo "$USER_ALIASES" | grep -q "shared="; then
    success "Aliases inherited correctly "
    test=$((test + 1))
else
    warning "Alias inheritance failed."
fi

if [ $test -eq 7 ]; then
    success "All users and groups verifications completed."
else
    warning "Some verifications failed."
fi