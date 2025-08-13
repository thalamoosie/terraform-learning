provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  name_prefix     = "terraform-example-"
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = templatefile("user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })
  # user_data = base64encode(<<-EOF
  #   #!/bin/bash
  #   echo "Hello, World!" > index.html
  #   echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
  #   echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
  #   nohup busybox httpd -f -p ${var.server_port} &
  #   EOF
  # )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_configuration.example.name
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page ain't found captain"
      status_code  = 404
    }
  }
}

# Listner rule that sends requests that match any path tot he target group that contains your ASG

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# Need to create a Security Group, as by default all AWS resources don't allow any incoming or outgoing traffic

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow Inboud HTTP Requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a target group for ASG using aws_lb_target_group
# This Target Group will health check your instances by periodically sending an HTTP request to each Instance
# It will consider the instance Healthy only if it returns a response that matches the 'matcher'
# If an instance fails to respond, it will be marked as unhealthy and the target group will automatically stop sending traffic to it

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-up-and-running-state-apz-2025-01"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

terraform {
  backend "s3" {
    # bucket         = "terraform-up-and-running-state-apz-2025-01"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    # region         = "us-east-2"
    # dynamodb_table = "terraform-up-and-running-locks"
    # encrypt        = true
  }
}
