require_relative './spec_helper'

class GeoEngineer::RemoteResources < GeoEngineer::Resource
  def self._fetch_remote_resources(provider)
    [{ _geo_id: "geo_id1" }, { _geo_id: "geo_id2" }, { _geo_id: "geo_id2" }]
  end
end

describe GeoEngineer::Resource do
  let(:env) { GeoEngineer::Environment.new("testing") }

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
      expect(tfjson['tags']['not_blue']).to eq 'FALSE'
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
    class GeoEngineer::FetchableResources < GeoEngineer::Resource
      def self._fetch_remote_resources(provider)
        [{ _geo_id: "geoid #{provider.id}" }]
      end
    end

    it 'should return a list of resources' do
      provider = GeoEngineer::Provider.new("prov_1")
      resources = GeoEngineer::FetchableResources.fetch_remote_resources(provider)
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid prov_1"
    end

    it 'should retrieve different resources for different providers' do
      provider1 = GeoEngineer::Provider.new("prov_1")
      resources = GeoEngineer::FetchableResources.fetch_remote_resources(provider1)
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid prov_1"

      provider2 = GeoEngineer::Provider.new("prov_2")
      resources = GeoEngineer::FetchableResources.fetch_remote_resources(provider2)
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid prov_2"
    end
  end

  describe '#_resources_to_ignore' do
    it 'lets you ignore certain resources' do
      class GeoEngineer::IgnorableResources < GeoEngineer::Resource
        def self._fetch_remote_resources(provider)
          [{ _geo_id: "geoid1" }, { _geo_id: "geoid2" }, { _geo_id: "anotherid" }, { _geo_id: "otherid" }]
        end

        def self._resources_to_ignore
          ["otherid", /^geoid/]
        end
      end

      resources = GeoEngineer::IgnorableResources
                  .fetch_remote_resources(GeoEngineer::Provider.new('aws'))
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "anotherid"
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
    it 'combines resource and parent tags' do
      environment = GeoEngineer::Environment.new('test') {
        tags {
          a '1'
        }
      }
      project = GeoEngineer::Project.new('org', 'project_name', environment) {
        tags {
          b  '2'
        }
      }
      resource = project.resource('type', '1') {
        tags {
          c  '3'
        }
      }
      resource.merge_parent_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'b' => '2', 'c' => '3' })
    end

    it 'works if just project is present' do
      project = GeoEngineer::Project.new('org', 'project_name', nil) {
        tags {
          a  '1'
        }
      }
      resource = project.resource('type', '1') {
        tags {
          b  '2'
        }
      }
      resource.merge_parent_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'works if just environment is present' do
      environment = GeoEngineer::Environment.new('test') {
        tags {
          a  '1'
        }
      }
      resource = environment.resource('type', '1') {
        tags {
          b  '2'
        }
      }
      resource.merge_parent_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'uses priority: resource > project > environment' do
      environment = GeoEngineer::Environment.new('test') {
        tags {
          a '1'
        }
      }
      project = GeoEngineer::Project.new('org', 'project_name', environment) {
        tags {
          a  '2'
          b  '1'
        }
      }
      resource = project.resource('type', '1') {
        tags {
          a  '3'
          b  '2'
          c  '1'
        }
      }
      resource.merge_parent_tags
      expect(resource.tags.attributes).to eq({ 'a' => '3', 'b' => '2', 'c' => '1' })
    end

    it 'returns project tags if there are no resource tags' do
      project = GeoEngineer::Project.new('org', 'project_name', env) {
        tags {
          a  '1'
          b  '2'
        }
      }
      resource = project.resource('type', '1') {}
      resource.merge_parent_tags
      expect(resource.tags.attributes).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'returns resource tags if there are no project tags' do
      project = GeoEngineer::Project.new('org', 'project_name', env) {}
      resource = project.resource('type', '1') {
        tags {
          c  '3'
          d  '4'
        }
      }
      resource.merge_parent_tags
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

  describe '#duplicate' do
    let!(:project) do
      GeoEngineer::Project.new('org', 'project_name', nil) {
        tags {
          a  '1'
        }
      }
    end
    let!(:resource_class) do
      class GeoEngineer::Resources::Derp < GeoEngineer::Resource
        validate -> { validate_has_tag(:Name) }
        after :initialize, -> {
          _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
        }
        after :initialize, -> { _geo_id       -> { NullObject.maybe(tags)[:Name] } }
        after :initialize, -> { _number       -> { NullObject.maybe(_geo_id)[-1] } }

        def self._fetch_remote_resources(provider)
          [
            { _geo_id: "geo_id1", _terraform_id: "t1 baby!" },
            { _geo_id: "geo_id2", _terraform_id: "t who?" }
          ]
        end
      end
    end

    let(:subject) do
      project.resource('derp', 'id') {
        tags {
          Name "geo_id1"
        }
      }
    end

    it 'copies over attributes and subresources' do
      copy = subject.duplicate('duplicate')
      # We haven't changed anything, so it should all match
      expect(copy.type).to eq(subject.type)
      expect(copy._geo_id).to eq(subject._geo_id)
      expect(copy._terraform_id).to eq(subject._terraform_id)
      expect(copy._number).to eq(subject._number)
      expect(copy.tags["Name"]).to eq(subject.tags["Name"])
    end

    it 'handles procs appropriately' do
      copy = subject.duplicate('duplicate')
      copy.tags["Name"] = "geo_id2"

      expect(copy.type).to eq(subject.type)
      expect(copy._geo_id).to_not eq(subject._geo_id)
      expect(copy._terraform_id).to_not eq(subject._terraform_id)
      expect(copy._number).to_not eq(subject._number)
      expect(copy._number).to eq("2")
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

  describe '#_deep_symbolize_keys' do
    let(:simple_obj) { JSON.parse({ foo: "bar", baz: "qux" }.to_json) }
    let(:complex_obj) do
      JSON.parse(
        {
          foo: {
            bar: {
              baz: [
                { qux: "quack" }
              ]
            }
          },
          bar: [
            { foo: "bar" },
            nil,
            [{ baz: "qux" }],
            1,
            "baz"
          ]
        }.to_json
      )
    end

    it "converts top level keys to symbols" do
      expect(simple_obj.keys.include?(:foo)).to eq(false)
      expect(simple_obj.keys.include?("foo")).to eq(true)
      converted = described_class._deep_symbolize_keys(simple_obj)
      expect(converted.keys.include?(:foo)).to eq(true)
      expect(converted.keys.include?("foo")).to eq(false)
    end

    it "converts deeply nested keys to symbols" do
      converted = described_class._deep_symbolize_keys(complex_obj)
      expect(converted[:foo][:bar][:baz].first[:qux]).to eq("quack")
      expect(converted[:bar].first[:foo]).to eq("bar")
    end
  end
end
