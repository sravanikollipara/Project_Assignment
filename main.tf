provider "aws" {
  region = "us-east-1"

}
terraform{
    backend "s3"{
      bucket = "krishika-s3-bucket"
      key    = "krishika-s3-bucket/s3"
      region = "us-east-1"
    }
}
 data "aws_availability_zones" "available" {

 }

resource "aws_vpc" "custom-vpc" {
   cidr_block       = "10.0.0.0/16"
   enable_dns_hostnames = true

   tags = {
     Name = "customvpc"
  }
}

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.custom-vpc.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_subnet" "public-subnet1" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "public-SN1"
  }
}
resource "aws_subnet" "public-subnet2" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "public-SN2"
  }
}

resource "aws_subnet" "private-subnet1" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.2.0/24"
  
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-SN1"
  }
}
resource "aws_subnet" "private-subnet2" {
  vpc_id     = aws_vpc.custom-vpc.id
  cidr_block = "10.0.3.0/24"
  
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-SN2"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet1.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "public-rt" {
   vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
  tags = {
    Name = "main"
  }
} 

resource "aws_route_table_association" "a-public1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "b-public2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table" "private-rt" {
   vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "a-private1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "b-private2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.private-rt.id
}

########## ELB-SG ######
resource "aws_security_group" "elb-sg" {
  name        = "ELB-SG"
  description = "ELB Security Rules"
  vpc_id      = aws_vpc.custom-vpc.id

  tags = {
    Name = "ELB-SG rules"
  }
}

resource "aws_security_group_rule" "elb-sg-http-ingress" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb-sg.id
}

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
    Name = "WEB-SG rules"
  }
}

resource "aws_security_group_rule" "web-sg-ingress-http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = aws_security_group.web-sg.id
  source_security_group_id = aws_security_group.elb-sg.id
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
#####  ASG  ######

resource "aws_autoscaling_group" "autoscaling" {
  launch_configuration = aws_launch_configuration.awslaunchconfiguration.name
  vpc_zone_identifier  = ["${aws_subnet.public-subnet1.id}", "${aws_subnet.public-subnet2.id}"]
  load_balancers =  ["${aws_elb.loadbalancer.name}"]
  health_check_type    = "EC2"
  min_size             = "1"
  max_size             = "2"
  tag {
    key                 = "Name"
    value               = "Terraform ASG"
    propagate_at_launch = true
  }
}
#scaling policies and event rules


resource "aws_cloudwatch_event_rule" "cloud_watch_event_rule" {
  name        = "ec2-cloud_watch_event_rule"
  description = "Capture all EC2 scaling events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful",
    "EC2 Instance Launch Unsuccessful",
    "EC2 Instance Terminate Unsuccessful"
  ]
}
PATTERN
}
resource "aws_autoscaling_policy" "scale-out" {
  name                   = "heavy-out-asg-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 10
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

resource "aws_autoscaling_policy" "scale-in" {
  name                   = "heavy-in-asg-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 10
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

resource "aws_cloudwatch_metric_alarm" "heavy_asg_cpu_usage" {
  alarm_name          = "asg_scale_out"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.autoscaling.name}"
  }
  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "low_asg_cpu_usage" {
  alarm_name          = "asg_scale_in"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.autoscaling.name}"
  }
  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale-in.arn}"]
}


resource "aws_launch_configuration" "awslaunchconfiguration" {
  image_id= "ami-0a887e401f7654935"
  instance_type   = "t2.micro"
  #key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.web-sg.id}"]
  user_data       = <<-EOF
                #!/bin/bash
                sudo yum install httpd -y 
                echo "Hello World"  '<br />' > /var/www/html/index.html
                echo "HOSTNAME :" >> /var/www/html/index.html
                hostname >> /var/www/html/index.html
                service httpd start
                EOF
  lifecycle {
    create_before_destroy = true
  }

}

###ELB Loan balancer

# Create a new load balancer
resource "aws_elb" "loadbalancer" {
  name               = "ec2-loadbalancer"
  #availability_zones = ["us-east-1a", "us-east-1b"]
  subnets = ["${aws_subnet.public-subnet1.id}", "${aws_subnet.public-subnet2.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
 

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "project-terraform-elb"
  }
}












