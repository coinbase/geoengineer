########################################################################
# AwsMskCluster is the +aws_msk_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/msk_cluster.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsMskCluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_name, :kafka_version, :number_of_broker_nodes]) }
  validate -> { validate_required_subresource(:broker_node_group_info) }
  validate -> {
             validate_subresource_required_attributes(:broker_node_group_info,
                                                      [:client_subnets,
                                                       :ebs_volume_size,
                                                       :instance_type,
                                                       :security_groups])
           }
  validate -> { validate_subresource_required_attributes(:configuration_info, [:arn, :revision]) }

  after :initialize, -> { _terraform_id -> { self[:cluster_name] } }

  def self._fetch_remote_resources(provider)
    AwsClients.kafka(provider).list_clusters['cluster_info_list'].map { |msk_cluster|
      {
        name: msk_cluster[:cluster_name],
        _terraform_id: msk_cluster[:cluster_name],
        _geo_id: msk_cluster[:cluster_name]
      }
    }
  end
end
