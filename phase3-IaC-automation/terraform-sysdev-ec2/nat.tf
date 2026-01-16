resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "webhost-prod-nat-eip"
    Environment = "prod"
    System      = "webhost"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "webhost-prod-nat-gateway"
    Environment = "prod"
    System      = "webhost"
  }

  depends_on = [aws_internet_gateway.main]
}