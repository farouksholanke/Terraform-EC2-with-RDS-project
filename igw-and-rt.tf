
# create internet gateway and route table
resource "aws_internet_gateway" "AppIGW" {
  vpc_id = aws_vpc.AppVPC.id

  tags = {
    Name = "AppInternetGateway"
  }
}

resource "aws_route_table" "AppRouteTable" {
  vpc_id = aws_vpc.AppVPC.id
  tags = {
    Name = "AppRouteTable"
  }
}

output "route_table_ID" {
  value = aws_route_table.AppRouteTable.id
}

## create out 
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.AppRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.AppIGW.id
}

## associate route table

resource "aws_route_table_association" "AppSubnet1_association" {
  subnet_id      = aws_subnet.AppSubnet1.id
  route_table_id = aws_route_table.AppRouteTable.id
}

resource "aws_route_table_association" "AppSubnet2_association" {
  subnet_id      = aws_subnet.AppSubnet2.id
  route_table_id = aws_route_table.AppRouteTable.id
}
