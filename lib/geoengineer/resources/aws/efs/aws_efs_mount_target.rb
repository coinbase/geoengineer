########################################################################
## AwsEfsMountTarget is the +aws_efs_mount_target+ terraform resource,
##
## {https://www.terraform.io/docs/providers/aws/d/efs_mount_target.html Terraform Docs}
#########################################################################
class GeoEngineer::Resources::AwsEfsMountTarget < GeoEngineer::Resource
  validate -> { validate_required_attributes([:file_system_id, :subnet_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{file_system_id}::#{subnet_id}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.efs.describe_file_systems['file_systems'].map(&:to_h).map { |file_system|
      args = { file_system_id: file_system[:file_system_id] }
      AwsClients.efs.describe_mount_targets(args)['mount_targets'].map(&:to_h).map do |mount_target|
        mount_target.merge(
          {
            _terraform_id: mount_target[:mount_target_id],
            _geo_id: "#{mount_target[:file_system_id]}::#{mount_target[:subnet_id]}"
          }
        )
      end
    }.flatten
  end
end
