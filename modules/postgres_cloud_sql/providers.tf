# ToDo: Fix this as soon as the following issue is resolved:
# https://github.com/hashicorp/terraform-provider-google/issues/16275
# See the following comment for further information on this workaround:
# https://github.com/hashicorp/terraform-provider-google/issues/16275#issuecomment-1825752152

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>4"
    }
  }
}
