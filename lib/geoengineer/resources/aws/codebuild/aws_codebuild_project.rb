########################################################################
# AwsCodebuildProject is the +aws_codebuild_project+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/codebuild_project.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCodebuildProject < GeoEngineer::Resource
  validate -> { validate_required_attributes([:service_role, :name]) }
  validate -> { validate_required_subresource(:artifacts) }
  validate -> { validate_required_subresource(:environment) }
  validate -> { validate_required_subresource(:source) }

  validate -> { validate_subresource_required_attributes(:artifacts, [:type]) }
  validate -> { validate_subresource_required_attributes(:source, [:type]) }
  validate -> { validate_subresource_required_attributes(:auth, [:type]) }

  validate -> { validate_subresource_required_attributes(:vpc_config, [:security_group_ids, :subnets, :vpc_id]) }

  validate -> { validate_subresource_required_attributes(:secondary_artifacts, [:type, :artifact_identifier]) }
  validate -> { validate_subresource_required_attributes(:secondary_sources, [:type, :source_identifier]) }

  validate -> { validate_subresource_required_attributes(:environment, [:compute_type, :image, :type]) }

  validate -> { validate_subresource_required_attributes(:environment_variable, [:name, :value]) }

  after :initialize, -> { _terraform_id -> { self[:name] } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def _environment(&block)
    self.send(:[]=, :environment, nil, &block)
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .codebuild(provider)
      .list_projects.projects.map do |codebuild_project|
      {
        name: codebuild_project,
        _terraform_id: codebuild_project,
        _geo_id: codebuild_project
      }
    end
  end
end
