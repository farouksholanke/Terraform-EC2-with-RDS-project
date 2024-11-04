resource "aws_eip" "public_ip1" {
  vpc = true
  network_interface = aws_network_interface.nw-interface1.id
}

resource "aws_eip" "public_ip2" {
  vpc = true
  network_interface = aws_network_interface.nw-interface2.id
}
