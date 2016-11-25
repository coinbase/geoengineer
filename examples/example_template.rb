# This example demonstrates how to define custom templates
#
# In this example a template is defined to have an ELB wit an instance
# To run this example:
# 1. Replace the subnets, vpcs, and the cloud_config with real values
# 2. export AWS environment variables AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
# 3. Execute geo apply -e staging ./examples/example_template.rb

staging_subnet = "1"
staging_vpc = "1"

cloud_config = %{
#cloud-config
runcmd:
  - docker run -d --name nginx -p 8000:80 nginx
}

environment("staging") {
  account_id  "1"
  subnet      staging_subnet
  vpc_id      staging_vpc
}

class LoadBalancedInstance < Template
  attr_reader :elb, :elb_sg, :ec2_sg, :ec2_instance

  def initialize(name, project, parameters)
    super(name, project, parameters)
    # parameters are
    # {
    #   user_data: defaults ""
    #   listeners: [{
    #     in: defaults to 80
    #     out: defaults to 8080
    #   }]
    # }

    user_data = parameters[:user_data] || ""

    listeners = parameters[:listeners] || []

    # Create the Security Groups
    elb_sg = resource("aws_security_group", "#{name}_allow_http") {
      name         "#{name}_elb_sg"
      description  ""
      vpc_id       env.vpc_id

      for l in listeners
        ingress {
          from_port    l[:in]
          to_port      l[:in]
          protocol     "tcp"
          cidr_blocks  ["0.0.0.0/0"]
        }
      end

      tags {
        Name "#{name}_elb_sg"
      }
    }

    ec2_sg = resource("aws_security_group", "#{name}_allow_elb") {
      name         "#{name}_ec2_sg"
      description  ""
      vpc_id       env.vpc_id
      for l in listeners
        ingress {
          from_port    l[:out]
          to_port      l[:out]
          protocol     "tcp"
          cidr_blocks  ["0.0.0.0/0"]
        }
      end
      tags {
        Name "#{name}_ec2_sg"
      }
    }

    instance = resource("aws_instance", "web") {
      ami           "ami-1c94e10b" #COREOS AMI
      instance_type "t1.micro"
      subnet_id     env.subnet
      user_data     user_data
      tags {
        Name "#{name}_ec2_instance"
      }
    }

    # ELB
    elb = resource("aws_elb", "main-web-app") {
      name             "#{name}_elb"
      security_groups  [elb_sg]
      subnets          [env.subnet]
      instances        [instance]
      for l in listeners
        listener {
          instance_port     l[:out]
          instance_protocol "http"
          lb_port           l[:in]
          lb_protocol       "http"
        }
      end
    }

    @elb    = elb
    @elb_sg = elb_sg
    @ec2_sg = ec2_sg
    @ec2_instance = instance
  end

  def template_resources
    [@elb, @elb_sg, @ec2_sg, @ec2_instance]
  end
end

# Instantiate the template for this project to forward two ports 80 and 8080
project.from_template("load_balanced_instance", "main_app", {
  user_data: cloud_config,
  listeners: [{in: 80, out: 3000 }, {in: 8080, out: 4000 }]
})
