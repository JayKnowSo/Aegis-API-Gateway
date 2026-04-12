package container.security

import rego.v1

deny contains msg if {
    input.user == "root"
    msg := "Container must not run as root"
}

deny contains msg if {
    input.user == "0"
    msg := "Container must not run as root (uid 0)"
}

deny contains msg if {
    not input.user
    msg := "Container must specify a non-root user"
}
