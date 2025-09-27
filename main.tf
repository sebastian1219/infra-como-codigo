provider "aws" {
  region = var.aws_region
}

# ----------------------
# VPC + Networking
# ----------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "CheeseFactoryVPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "CheeseFactoryIGW" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "CheeseFactoryPublicRT" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "PublicSubnet-${count.index + 1}" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ----------------------
# Security Groups
# ----------------------

# SG para el ALB
resource "aws_security_group" "alb_sg" {
  name        = "ALBSecurityGroup"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.main.id

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

  tags = { Name = "ALBSecurityGroup" }
}

# SG para las instancias EC2
resource "aws_security_group" "ec2_sg" {
  name        = "EC2CheeseSG"
  description = "Allow HTTP from ALB and SSH from my IP"
  vpc_id      = aws_vpc.main.id

  # HTTP solo desde el SG del ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH solo desde tu IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Reemplaza con tu IP real
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "EC2SecurityGroup" }
}

# ----------------------
# Instancias EC2
# ----------------------
resource "aws_instance" "cheese" {
  count         = 3
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 en us-east-1
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 80:80 ${element(var.docker_images, count.index)}
              EOF

  tags = {
    Name      = "CheeseInstance-${count.index + 1}"
    IsPrimary = count.index == 0 ? "true" : "false"
  }
}

# ----------------------
# Load Balancer
# ----------------------
resource "aws_lb" "cheese_alb" {
  name               = "CheeseALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "CheeseALB" }
}

resource "aws_lb_target_group" "cheese_tg" {
  name     = "CheeseTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "CheeseTG" }
}

resource "aws_lb_listener" "cheese_listener" {
  load_balancer_arn = aws_lb.cheese_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cheese_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "cheese_attachment" {
  count            = 3
  target_group_arn = aws_lb_target_group.cheese_tg.arn
  target_id        = aws_instance.cheese[count.index].id
  port             = 80
}

