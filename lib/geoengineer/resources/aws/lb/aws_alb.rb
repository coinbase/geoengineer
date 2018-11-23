########################################################################
# AwsAlb is the +aws_alb+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb.html Terraform Docs}
########################################################################
require_relative "./aws_lb"
class GeoEngineer::Resources::AwsAlb < GeoEngineer::Resources::AwsLb
  after :initialize, -> { self.load_balancer_type = "application" }
end
