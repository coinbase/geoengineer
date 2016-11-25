# This example demonstrates how to define custom validations
#
# In this example GeoEngineer::Resources::AwsElb has two custom validations added
# To run this example:
# 1. export AWS environment variables AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
# 2. Execute geo plan -e staging ./examples/example_custom_validations.rb


environment("staging") {
  account_id  "1"
  subnet      "1"
}

# Create the Project
project = project('org', 'first_project') {
  environments 'staging'
}

# Add Validation to Security Group
class GeoEngineer::Resources::AwsElb < GeoEngineer::Resource
  validate :validate_listeners_must_be_https
  validate -> { validate_has_tag(:ForProject) }

  def validate_listeners_must_be_https
    errors = []
    all_listener.select{ |i| i.lb_protocol != 'https' }.each do
      errors << "ELB must use https protocol #{for_resource}"
    end
    return errors
  end
end

# This ELB will fail both custom validations
# 1. It does not use the https protocol
# 2. It does not have the ForProject tag
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
  tags {
    Name "elb"
  }
}
