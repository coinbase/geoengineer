########################################################################
# AwsRdsClusterInstance is the +aws_rds_cluster_instance+ terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_instance.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRdsClusterInstance < GeoEngineer::Resource
  validate -> { validate_required_attributes([:db_subnet_group_name]) unless publicly_accessible }
  validate -> { validate_required_attributes([:cluster_identifier, :instance_class, :engine]) }

  after :initialize, -> { _terraform_id -> { identifier } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'identifier' => _terraform_id
    }
    tfstate
  end

  def short_type
    "rds_instance"
  end

  def self._is_aurora?(rds)
    rds.key?(:storage_type) && rds[:storage_type] == 'aurora'
  end

  def self._fetch_remote_resources(provider)
    AwsClients.rds(provider).describe_db_instances['db_instances']
              .map(&:to_h).select { |rds| _is_aurora?(rds) }.map do |rds|
      rds[:_terraform_id] = rds[:db_instance_identifier]
      rds[:_geo_id]       = rds[:db_instance_identifier]
      rds[:identifier]    = rds[:db_instance_identifier]
      rds
    end
  end
end
