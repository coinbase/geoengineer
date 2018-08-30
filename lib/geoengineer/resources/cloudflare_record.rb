################################################################################
# CloudflareRecord is the +cloudlare_record+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/cloudflare/r/record.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::CloudflareRecord < GeoEngineer::Resource
  validate -> { validate_required_attributes([:domain, :name, :type]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { [domain, name, self['type']].join('|') } }
  after :initialize, -> { self['ttl'] ||= 1 }

  def self._fetch_remote_resources(provider)
    records = CloudflareClient.records.map do |record|
      record[:_terraform_id] = record.delete(:id)
      record[:_geo_id] = [record[:domain], record[:name], record[:type]].join('|')
      record
    end

    records
  end

  def to_terraform_state
    tfstate = super

    # Need to explicitly define these attributes in order for Terraform to
    # identify the resource correctly (record ID isn't enough). Otherwise you'll
    # get Terraform errors like:
    # cloudflare_record.my-record: Error finding zone "": Zone could not be found
    tfstate[:primary][:attributes] = {
      domain: domain,
      name: name,
      zone_id: CloudflareClient.zone_by_name(domain).id,
    }

    tfstate
  end
end
