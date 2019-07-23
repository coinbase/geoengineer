########################################################################
# AwsMskCluster is the +aws_msk_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/msk_cluster.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsMskCluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_name, :kafka_version, :number_of_broker_nodes]) }
  validate -> { validate_required_subresource(:broker_node_group_info) }
  validate -> { validate_required_subresource(:encryption_info) }
  validate -> {
             validate_subresource_required_attributes(:broker_node_group_info,
                                                      [:client_subnets,
                                                       :ebs_volume_size,
                                                       :instance_type,
                                                       :security_groups])
           }
  validate -> { validate_subresource_required_attributes(:configuration_info, [:arn, :revision]) }
  validate -> { validate_subresource_required_attributes(:encryption_info, [:encryption_in_transit]) }
  validate -> { validate_subresource_required_attributes(:encryption_in_transit, [:client_broker]) }
  validate :validate_encryption_in_transit_protocol
  validate :validate_cluster_name
  validate :validate_ebs_volume_size

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { self[:cluster_name] } }

  def validate_encryption_in_transit_protocol
    return nil unless encryption_info # needed for specs
    valid_values = ["TLS", "TLS_PLAINTEXT", "PLAINTEXT"]
    proto = encryption_info.encryption_in_transit.client_broker
    return "Error: #{proto} is invalid encryption protocol" unless valid_values.include?(proto)
  end

  def validate_cluster_name
    return nil unless cluster_name # needed for specs
    return "Error: #{cluster_name} is invalid cluster name" if cluster_name.match(/^[a-zA-Z0-9-]+$/).nil? ||
                                                               cluster_name.length > 64
  end

  def validate_ebs_volume_size
    return nil unless broker_node_group_info # needed for specs
    vol_size = broker_node_group_info.ebs_volume_size
    return "Error: invalid EBS volume size of #{vol_size} GiB" if vol_size > 16_384 ||
                                                                  vol_size < 1
  end

  def self._fetch_remote_resources(provider)
    AwsClients.kafka(provider).list_clusters['cluster_info_list'].map { |msk_cluster|
      {
        name: msk_cluster[:cluster_name],
        _terraform_id: msk_cluster[:cluster_arn],
        _geo_id: msk_cluster[:cluster_name]
      }
    }
  end
end
