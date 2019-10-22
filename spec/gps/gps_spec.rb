require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS do
  describe '#initialize' do
    it 'works with no input' do
      GeoEngineer::GPS.new({}, {})
    end

    it 'should init and build nodes' do
      g = GeoEngineer::GPS.new({
                                 "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => {} } } } }
                               }, {})
      expect(g.nodes.first.node_id).to eq "p1:e1:c1:test_node:n1"
    end

    it 'should expand meta_nodes' do
      g = GeoEngineer::GPS.new({
                                 "p1" => { "e1" => { "c1" => { "test_meta_node" => { "n1" => {} } } } }
                               }, {})
      expect(g.nodes.length).to eq 2
      expect(g.where("p1:e1:c1:test_meta_node:n1").length).to eq 1
      expect(g.where("p1:e1:c1:test_node:n1").length).to eq 1
    end

    it 'should expand meta nodes which build meta nodes' do
      g = GeoEngineer::GPS.new({
                                 "p1" => { "e1" => { "c1" => { "test_meta_meta_node" => { "n1" => {} } } } }
                               }, {})
      expect(g.nodes.length).to eq 3
      expect(g.where("p1:e1:c1:test_meta_meta_node:*").length).to eq 1
      expect(g.where("p1:e1:c1:test_meta_node:*").length).to eq 1
      expect(g.where("p1:e1:c1:test_node:*").length).to eq 1
    end
  end

  describe '#expanded_hash' do
    it 'builds a hash of all nodes' do
      h = { "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => {} } } } } }
      g = GeoEngineer::GPS.new(h, {})

      # includes default values
      eh = { "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => { "name" => "default" } } } } } }
      expect(g.expanded_hash).to eq(eh)
    end
  end

  describe '#loop_projects_hash' do
    it 'should build a hash of node objects' do
      h = { "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => {} } } } } }
      c = GeoEngineer::GPS::Constants.new({ "e1" => {}, "e2" => {} })
      g = GeoEngineer::GPS.new(h, c)

      # expect the returned hash to match the inputted hash
      expanded_hash = g.loop_projects_hash(h) {}
      expect(expanded_hash).to eq(h)
    end

    it 'should expand _default environment keyword to all known environments' do
      h = { "p1" => { "_default" => { "c1" => { "test_node" => { "n1" => {} } } } } }
      c = GeoEngineer::GPS::Constants.new({ "e1" => {}, "e2" => {} })
      g = GeoEngineer::GPS.new(h, c)

      # expect the returned hash to include the project in all environments (e1, e2)
      eh = { "p1" => {
        "e1" => { "c1" => { "test_node" => { "n1" => {} } } },
        "e2" => { "c1" => { "test_node" => { "n1" => {} } } }
      } }
      expanded_hash = g.loop_projects_hash(h) {}
      expect(expanded_hash).to eq(eh)
    end

    it 'should expand _default environment except ones already specified' do
      h = { "p1" => {
        "_default" => { "c1" => { "test_node" => { "n1" => {} } } },
        "e2" => { "c2" => { "test_node" => { "n2" => {} } } }
      } }
      c = GeoEngineer::GPS::Constants.new({ "e1" => {}, "e2" => {} })
      g = GeoEngineer::GPS.new(h, c)

      # expect the returned hash to include the project in all environments (e1,
      # e2), but they shouldn't match each other.
      eh = { "p1" => {
        "e1" => { "c1" => { "test_node" => { "n1" => {} } } },
        "e2" => { "c2" => { "test_node" => { "n2" => {} } } }
      } }
      expanded_hash = g.loop_projects_hash(h) {}
      expect(expanded_hash).to eq(eh)
    end
  end

  describe '#find' do
    it 'proxies the request to the finder' do
      h = { "org/p1" => { "e1" => { "c1" => { "test_node" => { "n1" => { "name" => "asd" } } } } } }
      gps = GeoEngineer::GPS.new(h)

      expect do
        gps.find("p1:e1:*:*:*")
      end.to raise_error(GeoEngineer::GPS::Finder::NotFoundError)
    end
  end

  describe '#create_project' do
    it 'creates node resources' do
      h = { "org/p1" => { "e1" => { "c1" => { "test_node" => { "n1" => { "name" => "asd" } } } } } }
      g = GeoEngineer::GPS.new(h, {})

      called = false
      g.create_project("org", "p1", GeoEngineer::Environment.new("e1")) do |project, config, nodes|
        called = true
        expect(config).to eq "c1"
        expect(project.full_name).to eq "org/p1"
        expect(nodes.find(":::test_node:n1").attributes["name"]).to eq "asd"
      end

      expect(called).to eq true
    end
  end
end
