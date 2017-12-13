########################################################################
# AwsAlbTargetGroup is the +aws_alb_target_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/alb_target_group.html Terraform Docs}
########################################################################
require_relative "./aws_lb_target_group"
class GeoEngineer::Resources::AwsAlbTargetGroup < GeoEngineer::Resources::AwsLbTargetGroup
end
