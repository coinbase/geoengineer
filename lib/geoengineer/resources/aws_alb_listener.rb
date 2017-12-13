########################################################################
# AwsAlbListener is the +aws_alb_listener+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_listener.html Terraform Docs}
########################################################################
require_relative "./aws_lb_listener"
class GeoEngineer::Resources::AwsAlbListener < GeoEngineer::Resources::AwsLbListener
end
