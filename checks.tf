# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# The module does nothing without at least one project.
check "has_projects" {
  assert {
    condition     = length(var.projects) > 0
    error_message = "No projects were supplied, so this module creates nothing."
  }
}
