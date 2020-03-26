
########## ELB-Security Group  ######

resource "aws_security_group" "elb-sg" {
  name        = "ELB-SG"
  description = "ELB Security Rules"
  vpc_id      = aws_vpc.custom-vpc.id

  tags = {
    Name         = "${var.platform}-${var.env}-elbsg"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
#########  http traffic from outside world
resource "aws_security_group_rule" "elb-sg-http-ingress" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb-sg.id
}
#########  outbound to web security group
resource "aws_security_group_rule" "elb-sg-egress-http" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = aws_security_group.elb-sg.id
  source_security_group_id = aws_security_group.web-sg.id
}

######## WEB-SG ######
resource "aws_security_group" "web-sg" {
  name        = "WEB-SG"
  description = "WEB Security Rules"
  vpc_id      = aws_vpc.custom-vpc.id

  tags = {
    Name         = "${var.platform}-${var.env}-websg"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}
######### Allowing Inbound 80 from ELB 
resource "aws_security_group_rule" "web-sg-ingress-http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = aws_security_group.web-sg.id
  source_security_group_id = aws_security_group.elb-sg.id
}
  resource "aws_security_group_rule" "web_tcp" {
    type                     = "ingress"
    description = "HTTPS Protocol"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_group_id = aws_security_group.web-sg.id
    cidr_blocks = ["76.184.240.110/32"]
  }

resource "aws_security_group_rule" "web-sg-egress-http-elb" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = aws_security_group.web-sg.id
  source_security_group_id = aws_security_group.elb-sg.id
}

resource "aws_security_group_rule" "web-sg-egress-http" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  security_group_id = aws_security_group.web-sg.id
  cidr_blocks     = ["0.0.0.0/0"]
}