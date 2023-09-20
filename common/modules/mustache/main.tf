variable "vars" {
  type    = map(any)
  default = {}
}

variable "template_file" {
  type    = string
  default = ""
}

# Render mustache template from template context
data "external" "render_mustache" {
  program = [
    "sh", "-c",
    "echo '${jsonencode(var.vars)}' | mustache ${var.template_file} | jq -Rs '{s: .}'"
  ]
}

output "rendered" {
  value = data.external.render_mustache.result.s
}
