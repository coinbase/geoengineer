require_relative './spec_helper'

class GeoEngineer::RemoteResources < GeoEngineer::Resource
  def self._fetch_remote_resources
    [{ _geo_id: "geo_id1" }, { _geo_id: "geo_id2" }, { _geo_id: "geo_id2" }]
  end
end

describe("GeoEngineer::Resource") do
  describe '#remote_resource' do
    it 'should return a list of resources' do
      rem_res = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id1"
      }

      norem_res = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id3"
      }

      expect(rem_res.remote_resource.nil?).to eq false
      expect(norem_res.remote_resource.nil?).to eq true
    end

    it 'should error if you match more than one' do
      rem = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id2"
      }
      expect { rem.remote_resource }.to raise_error(StandardError)
    end
  end

  describe '#to_terraform_json' do
    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFJSON < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      res = GeoEngineer::TFJSON.new('tf_json', 'ididid') {
        blue "TRUE"
        tags {
          not_blue "FALSE"
        }
        # i.e. s3 bucket multilevel subresources
        lifecycle_rule {
          expiration {
            days 90
          }
        }

        lifecycle_rule {
          transition {
            days 60
          }
        }
      }

      tfjson = res.to_terraform_json

      expect(tfjson['blue']).to eq 'TRUE'
      expect(tfjson['tags'][0]['not_blue']).to eq 'FALSE'
      expect(tfjson['lifecycle_rule'][0]['expiration'][0]['days']).to eq 90
      expect(tfjson['lifecycle_rule'][1]['transition'][0]['days']).to eq 60
    end
  end

  describe '#to_terraform_state' do
    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFState < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      tfs = GeoEngineer::TFState.new('tf_state', 'asd').to_terraform_state
      expect(tfs[:type]).to eq 'tf_state'
      expect(tfs[:primary][:id]).to eq 'tid'
    end

    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFState < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      tfs = GeoEngineer::TFState.new('tf_state', 'asd').to_terraform_state
      expect(tfs[:type]).to eq 'tf_state'
      expect(tfs[:primary][:id]).to eq 'tid'
    end
  end

  describe '#fetch_remote_resources' do
    it 'should return a list of resources' do
      class GeoEngineer::FetchableResources < GeoEngineer::Resource
        def self._fetch_remote_resources
          [{ _geo_id: "geoid" }]
        end
      end

      resources = GeoEngineer::FetchableResources.fetch_remote_resources()
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid"
    end
  end

  describe '#_resources_to_ignore' do
    it 'lets you ignore certain resources' do
      class GeoEngineer::IgnorableResources < GeoEngineer::Resource
        def self._fetch_remote_resources
          [{ _geo_id: "geoid1" }, { _geo_id: "geoid2" }]
        end

        def self._resources_to_ignore
          ["geoid1"]
        end
      end

      resources = GeoEngineer::IgnorableResources.fetch_remote_resources()
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid2"
    end
  end

  describe '#validate_required_subresource' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasSRAttrResource < GeoEngineer::Resource
        validate -> { validate_required_subresource :tags }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {}
      with_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_subresource_required_attributes' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasSRAttrResource < GeoEngineer::Resource
        validate -> { validate_subresource_required_attributes :tags, [:blue] }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {}
      }
      with_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_required_attributes' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasAttrResource < GeoEngineer::Resource
        validate -> { validate_required_attributes [:blue] }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasAttrResource.new('has_attr', 'id')
      with_blue = GeoEngineer::HasAttrResource.new('has_attr', 'id') {
        blue "True"
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_has_tag' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasTagResource < GeoEngineer::Resource
        validate -> { validate_has_tag :blue }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasTagResource.new('has_tag', 'id')
      with_blue = GeoEngineer::HasTagResource.new('has_tag', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_tag_merge' do
    it 'should combine resource and project tags' do
      project = GeoEngineer::Project.new('org', 'project_name', 'test') {
        tags {
          a  '1'
        }
      }
      resource = project.resource('type', '1') {
        tags {
          d  '4'
        }
      }
      resource.merge_project_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'd' => '4' })
    end

    it 'should give priority to resource tags' do
      project = GeoEngineer::Project.new('org', 'project_name', 'test') {
        tags {
          a  'project_value'
        }
      }
      resource = project.resource('type', '1') {
        tags {
          a  'resource_value'
        }
      }
      resource.merge_project_tags
      expect(resource.tags.attributes).to eq({ 'a' => 'resource_value' })
    end

    it 'should return project tags if there are no resource tags' do
      project = GeoEngineer::Project.new('org', 'project_name', 'test') {
        tags {
          a  '1'
          b  '2'
        }
      }
      resource = project.resource('type', '1') {}
      resource.merge_project_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'should return resource tags if there are no project tags' do
      project = GeoEngineer::Project.new('org', 'project_name', 'test') {}
      resource = project.resource('type', '1') {
        tags {
          c  '3'
          d  '4'
        }
      }
      resource.merge_project_tags
      expect(resource.tags.attributes).to eq({ 'c' => '3', 'd' => '4' })
    end
  end

  describe '#reset' do
    let(:subject) do
      GeoEngineer::RemoteResources.new('resource', 'id') {
        tags {
          Name "foo"
        }
        _geo_id -> { tags['Name'] }
      }
    end

    it 'resets lazily computed attributes' do
      expect(subject._geo_id).to eq('foo')
      subject.tags['Name'] = 'bar'
      subject.reset
      expect(subject._geo_id).to eq('bar')
    end

    it 'resets remote resource' do
      expect(subject.remote_resource).to be_nil
      subject.tags['Name'] = "geo_id1"
      subject.reset
      expect(subject.remote_resource).to_not be_nil
    end
  end

  describe 'class method' do
    describe('#type_from_class_name') do
      it 'should return resource' do
        expect(GeoEngineer::Resource.type_from_class_name).to eq 'resource'
      end

      it 'should remove module' do
        class GeoEngineer::ResourceType < GeoEngineer::Resource
        end
        expect(GeoEngineer::ResourceType.type_from_class_name).to eq 'resource_type'
      end
    end
  end
end
