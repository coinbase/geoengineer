########################################################################
## AwsEfsMountTarget is the +aws_efs_mount_target+ terraform resource,
##
## {https://www.terraform.io/docs/providers/aws/d/efs_mount_target.html Terraform Docs}
#########################################################################
class GeoEngineer::Resources::AwsEfsMountTarget < GeoEngineer::Resource
  validate -> { validate_required_attributes([:mount_target_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def self._fetch_remote_resources(provider)
    AwsClients.efs.describe_mount_targets['mount_targets'].map(&:to_h).map do |mount_target|
      mount_target.merge(
        {
          _terraform_id: mount_target["mount_target_id"]
        }
      )
    end
  end
end
