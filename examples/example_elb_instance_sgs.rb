# This example demonstrates how to define security groups and load balancers.
#
# To run this example:
# 1. Replace the subnets, vpcs and the cloud_config with real values
# 2. export AWS environment variables AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
# 3. Execute geo apply -e staging ./examples/example_elb_instance_sgs.rb
#    or geo apply -e production ./examples/example_elb_instance_sgs.rb

staging_subnet = "1"
staging_vpc = "1"
production_subnet = "2"
production_vpc = "2"

cloud_config = %{
#cloud-config
runcmd:
  - docker run -d --name nginx -p 8000:80 nginx
}

environment("production") {
  account_id  "2"
  subnet      production_subnet
  vpc_id      production_vpc
}

environment("staging") {
  account_id  "1"
  subnet      staging_subnet
  vpc_id      staging_vpc
}

project = project('org', 'first_project') {
  environments 'staging', 'production'
}

### Security Groups
elb_sg = project.resource("aws_security_group", "allow_http") {
  name         "allow_http"
  description  "Allow All HTTP"
  vpc_id       env.vpc_id
  ingress {
      from_port    80
      to_port      80
      protocol     "tcp"
      cidr_blocks  ["0.0.0.0/0"]
  }
  tags {
    Name "allow_http"
  }
}

ec2_sg = project.resource("aws_security_group", "allow_elb") {
  name         "allow_elb"
  description  "Allow ELB to 80"
  vpc_id       env.vpc_id
  ingress {
      from_port    8000
      to_port      8000
      protocol     "tcp"
      security_groups  [elb_sg]
  }
  tags {
    Name "allow_elb"
  }
}

instance = project.resource("aws_instance", "web") {
  ami           "ami-1c94e10b" #COREOS AMI
  instance_type "t1.micro"
  subnet_id     env.subnet
  user_data     cloud_config # cloud_config to run webserver
  tags {
    Name "ec2_instance"
  }
}

# ELB
project.resource("aws_elb", "main-web-app") {
  name             "main-app-elb"
  security_groups  [elb_sg]
  subnets          [env.subnet]
  instances        [instance]
  listener {
    instance_port     8000
    instance_protocol "http"
    lb_port           80
    lb_protocol       "http"
  }
}
