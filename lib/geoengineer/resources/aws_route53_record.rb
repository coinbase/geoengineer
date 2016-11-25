########################################################################
# AwsRoute53Record is the +aws_route53_record+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route53_record.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute53Record < GeoEngineer::Resource
  validate -> { validate_required_attributes([:zone_id, :name, :type]) }
  validate -> { validate_required_attributes([:ttl, :records]) unless self.alias }

  validate -> {
    if self.alias
      validate_subresource_required_attributes(:alias, [:name, :zone_id, :evaluate_target_health])
    end
  }

  after :initialize, -> { _terraform_id -> { "#{zone_id}_#{name}_#{type}" } }

  def self._fetch_remote_resources
    _fetch_zones.map { |zone| _fetch_records_for_zone(zone) }.flatten.compact
  end

  def self._fetch_zones
    AwsClients.route53.list_hosted_zones.hosted_zones.map(&:to_h)
  end

  def self._fetch_records_for_zone(zone)
    records = AwsClients.route53.list_resource_record_sets({ hosted_zone_id: zone[:id] })
    records.resource_record_sets.map(&:to_h).map do |record|
      record.merge({ _terraform_id: "#{record[:zone_id]}_#{record[:name]}_#{record[:type]}" })
    end
  end
end
