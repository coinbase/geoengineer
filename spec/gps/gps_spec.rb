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

    it 'should expand meta_nodes' do
      h = {
        "org/p1" => { "e1" => { "c1" => { "test_meta_node" => { "n1" => {} } } } }
      }
      g = GeoEngineer::GPS.new(h, {})

      called = false
      g.create_project("org", "p1", GeoEngineer::Environment.new("e1")) do |project, config, nodes|
        called = true
        expect(config).to eq "c1"
        expect(project.full_name).to eq "org/p1"
        expect(nodes.where(":::test_meta_node:n1").length).to eq 1
        expect(nodes.where(":::test_node:n1").length).to eq 1
      end

      expect(called).to eq true
      expect(g.nodes.length).to eq 2
    end

    it 'should expand meta nodes which build meta nodes' do
      h = {
        "org/p1" => { "e1" => { "c1" => { "test_meta_meta_node" => { "n1" => {} } } } }
      }
      g = GeoEngineer::GPS.new(h, {})

      called = false
      g.create_project("org", "p1", GeoEngineer::Environment.new("e1")) do |project, config, nodes|
        called = true
        expect(config).to eq "c1"
        expect(project.full_name).to eq "org/p1"
        expect(nodes.where(":::test_meta_meta_node:*").length).to eq 1
        expect(nodes.where(":::test_meta_node:*").length).to eq 1
        expect(nodes.where(":::test_node:*").length).to eq 1
      end

      expect(called).to eq true
      expect(g.nodes.length).to eq 3
    end

    it 'should expand meta nodes which build meta nodes and reference each other' do
      h = {
        "org/p1" => { "e1" => { "c1" => { "test_circular_meta" => {
          "n1" => { "child_resource" => "org/p2:e1:c1:test_circular_node:n2#elb" }
        } } } },
        "org/p2" => { "e1" => { "c1" => { "test_circular_node" => {
          "n2" => { "child_resource" => "org/p1:e1:c1:test_node:n1#elb" }
        } } } }
      }
      g = GeoEngineer::GPS.new(h, {})
      e = GeoEngineer::Environment.new("e1")

      called = false
      g.create_project("org", "p2", e)
      g.create_project("org", "p1", e) do |project, config, nodes|
        called = true
        expect(config).to eq "c1"
        expect(project.full_name).to eq "org/p1"
        expect(nodes.where(":::test_circular_meta:n1").length).to eq 1
        expect(nodes.where(":::test_node:n1").length).to eq 1
        expect(nodes.where("org/p2:e1:c1:test_circular_node:n2").length).to eq 1
      end

      expect(called).to eq true
      expect(g.nodes.length).to eq 3

      n1 = g.where("org/p1:e1:c1:test_circular_meta:n1")
      expect(n1.first.child_resource).to eq "${aws_elb.elb_org_p2_c1_test_circular_node_n2.id}"

      expect(g.where("org/p1:e1:c1:test_node:n1").length).to eq 1
      expect(g.where("org/p1:e1:c1:test_node:n1").first.elb).to_not be_nil
      expect(g.where("org/p2:e1:c1:test_circular_node:n2").first.child_resource).to eq "${aws_elb.elb_org_p1_c1_test_node_n1.id}"
      expect(g.where("org/p2:e1:c1:test_circular_node:n2").first.elb).to_not be_nil
    end
  end

  describe '#load_gps_file' do
    before(:each) do
      @old_pwdir = Dir.pwd
      Dir.chdir(File.join(File.dirname(__FILE__), 'examples'))
    end

    after(:each) do
      Dir.chdir(@old_pwdir)
    end

    it 'should load gps files' do
      g = GeoEngineer::GPS.load_projects(File.join(Dir.pwd, "projects", ""), { "e1" => {} })
      def g.env
        GeoEngineer::Environment.new("e1")
      end

      GeoEngineer::GPS.load_gps_file(g, File.join('projects', 'org', 'p1.gps.yml'))
      GeoEngineer::GPS.load_gps_file(g, File.join('projects', 'org', 'p2.gps.yml'))

      expect(g.nodes.length).to eq 3

      cmn1 = g.where("org/p1:e1:c1:test_circular_meta:n1").first
      expect(cmn1.child_resource).to eq "${aws_elb.elb_org_p2_c1_test_circular_node_n2.id}"

      tnn1 = g.where("org/p1:e1:c1:test_node:n1")
      expect(tnn1.length).to eq 1
      expect(tnn1.first.elb).to_not be_nil
      expect(tnn1.first.elb).to_not be_nil

      tcnn2 = g.where("org/p2:e1:c1:test_circular_node:n2")
      expect(tcnn2.length).to eq 1
      expect(tcnn2.first.child_resource).to eq "${aws_elb.elb_org_p1_c1_test_node_n1.id}"
      expect(tcnn2.first.elb).to_not be_nil
    end

    it 'should load ruby files' do
      g = GeoCLI.instance.gps
      def g.env
        GeoEngineer::Environment.new("e1")
      end

      g.load_gps_file(File.join('projects', 'org', 'p3.rb'))
      g.load_gps_file(File.join('projects', 'org', 'p2.gps.yml'))
      g.load_gps_file(File.join('projects', 'org', 'p1.gps.yml'))

      expect(g.nodes.length).to eq 3

      cmn1 = g.where("org/p1:e1:c1:test_circular_meta:n1")
      expect(cmn1.first.child_resource).to eq "${aws_elb.elb_org_p2_c1_test_circular_node_n2.id}"

      tnn1 = g.where("org/p1:e1:c1:test_node:n1")
      expect(tnn1.length).to eq 1
      expect(tnn1.first.elb).to_not be_nil
      expect(tnn1.first.elb).to_not be_nil

      tcnn2 = g.where("org/p2:e1:c1:test_circular_node:n2")
      expect(tcnn2.length).to eq 1
      expect(tcnn2.first.child_resource).to eq "${aws_elb.elb_org_p1_c1_test_node_n1.id}"
      expect(tcnn2.first.elb).to_not be_nil
    end
  end
end
