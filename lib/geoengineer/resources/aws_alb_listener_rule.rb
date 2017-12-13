########################################################################
# AwsAlbListenerRule is the +aws_alb_listener_rule+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_listener_rule.html Terraform Docs}
########################################################################
require_relative "./aws_lb_listener_rule"
class GeoEngineer::Resources::AwsAlbListenerRule < GeoEngineer::Resources::AwsLbListenerRule
end
