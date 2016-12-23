require_relative '../spec_helper'

describe("HasResources") do
  class WithResources
    include HasResources

    def all_resources
      resources
    end
  end

  class GeoEngineer::Resources::AwesomeResource < GeoEngineer::Resource
  end

  describe '#resources_grouped_by' do
    it 'should return a hash of grouped resource' do
      x = WithResources.new()
      x.create_resource("type", "id") {
        blue true
      }
      x.create_resource("type", "id") {
        blue true
      }
      x.create_resource("type", "id") {
        blue false
      }
      group = x.resources_grouped_by(&:blue)
      expect(group[true].length).to eq 2
      expect(group[false].length).to eq 1
    end
  end

  describe('#get_resource_class_from_type') do
    it 'should default to GeoEngineer::Resource' do
      expect(WithResources.get_resource_class_from_type("asd")).to eq GeoEngineer::Resource
    end

    it 'should find a defined class' do
      clazz = WithResources.get_resource_class_from_type("awesome_resource")
      expect(clazz).to eq GeoEngineer::Resources::AwesomeResource
    end
  end

  describe('#find_resource_by_ref') do
    it 'should find a resource given terraform ref' do
      x = WithResources.new()
      x.create_resource("type", "id") {
        value 10
      }
      expect(x.find_resource_by_ref('${type.id.param}').value).to eq 10
    end
  end

  describe('#create_resource') do
    it 'should add resources with a block' do
      x = WithResources.new()
      resource = x.create_resource("type", "id") {
        value 20
      }

      expect(resource.value).to eq 20
    end

    it 'should look up the class for the resources' do
      x = WithResources.new()
      resource = x.create_resource("awesome_resource", "id") {
        value 30
      }
      expect(resource.class).to eq GeoEngineer::Resources::AwesomeResource
    end
  end
end
