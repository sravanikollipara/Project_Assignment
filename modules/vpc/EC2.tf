###########  AutoScalingGroup  ###########

resource "aws_autoscaling_group" "autoscaling" {
  launch_configuration = aws_launch_configuration.awslaunchconfiguration.name
  vpc_zone_identifier  = ["${aws_subnet.public-subnet1.id}", "${aws_subnet.public-subnet2.id}"]
  load_balancers =  ["${aws_elb.loadbalancer.name}"]
  health_check_type    = "EC2"
  min_size             = var.min_size
  max_size             = var.max_size
  tag {
    key                 = "Name"
    value               = "Terraform ASG"
    propagate_at_launch = true
  }
}

#########   cloudwatch event rules   #########

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

############  Scaling policies  #############
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

############  Heavy-asg-cpu-usage  ########
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

###########  low-asg-cpu-usage  ############
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

#############  Launch Configuration  ######
resource "aws_launch_configuration" "awslaunchconfiguration" {
  image_id = var.image-id
  instance_type   = var.instance-type
  key_name        = var.key-name
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  security_groups = ["${aws_security_group.web-sg.id}"]
  user_data       = <<-EOF
                #!/bin/bash
                sudo yum install httpd -y 
                cd /var/www/html/
                sudo aws s3 cp s3://onica-venkata-kollipara/onica-image.jpg .
                sleep 10
                sudo aws s3 cp s3://onica-venkata-kollipara/index.html .
                sudo chmod 777 index.html
  
                echo '<br />' >> /var/www/html/index.html
                echo "HOSTNAME :"  >> /var/www/html/index.html
                hostname >> /var/www/html/index.html
                service httpd start
                EOF
  lifecycle {
    create_before_destroy = true
  }

}

####### New ELB Load balancer  ########

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
    Name         = "${var.platform}-${var.env}-loadbalancer"
    Env          = var.env
    OwnerContact = var.OwnerContact
  }
}

########## iam-role-policy ########
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.s3_role.id

  policy = <<-EOF
{
	"Version": "2012-10-17",
	"Id": "Policy1573782037453",
	"Statement": [{
		"Sid": "Stmt1573782014292",
		"Effect": "Allow",
		"Action": [
			"s3:Get*",
			"s3:List*",
			"s3:Put*"
		],
		"Resource": [
			"arn:aws:s3:::onica-venkata-kollipara/",
			"arn:aws:s3:::onica-venkata-kollipara/*"
		]
	}]
}
  EOF
  
}

########### iam-role ########
resource "aws_iam_role" "s3_role" {
  name = "s3_role"

    assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
  
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = aws_iam_role.s3_role.name
}
