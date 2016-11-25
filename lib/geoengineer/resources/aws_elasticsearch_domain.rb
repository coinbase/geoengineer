########################################################################
# AwsElasticsearchDomain is the +aws_elasticsearch_domain+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elasticsearch_domain.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsElasticsearchDomain < GeoEngineer::Resource
  validate -> { validate_required_attributes([:domain_name]) }

  after :initialize, -> {
    _terraform_id -> {
      "arn:aws:es:#{environment.region}:#{environment.account_id}:domain/#{self.domain_name}"
    }
  }
  after :initialize, -> { _geo_id -> { domain_name } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'domain_name' => domain_name,
      'access_policies' => access_policies
    }
    tfstate
  end

  def short_type
    "es"
  end

  def self._fetch_remote_resources
    AwsClients.elasticsearch.list_domain_names['domain_names'].map(&:to_h).map do |esd|
      esd[:_geo_id] = esd[:domain_name]
      esd
    end
  end
end
