function get-current-org-task() {
    local ORG_TASK_FILE='/tmp/org-currently-clocked-in-task'
    local orgTask="$(head -n 1 ${ORG_TASK_FILE} 2>/dev/null || echo '')"
    echo "${orgTask}"
}
