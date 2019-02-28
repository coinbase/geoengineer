require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::YamlTag do
  let(:n0) { GeoEngineer::GPS::Nodes::TestNode.new("p", "e", "c", "n", {}) }
  let(:nodes) { [n0] }
  let(:constants) { GeoEngineer::GPS::Constants.new({ "e": { "here": "hello" } }) }

  context '!sub' do
    it 'replaces constant' do
      yaml = YAML.load('test: !sub prefix-{{constant:e:here}}-postfix')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "prefix-hello-postfix"
    end

    it 'replaces constants' do
      yaml = YAML.load('test: !sub prefix-{{constant:e:here}}-midfix-{{constant:e:here}}-postfix')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "prefix-hello-midfix-hello-postfix"
    end

    context 'references' do
      it 'returns a list of referenced nodes' do
        yaml = YAML.load('test: !sub prefix-{{p:e:c:test_node:n#elb}}-postfix')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
        expect(yaml["test"].references).to eq [n0]
      end
    end
  end

  context '!ref' do
    it 'replaces constant' do
      yaml = YAML.load('test: !ref constant:e:here')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "hello"
    end

    it 'replaces node with terraform id or arn' do
      yaml = YAML.load('test: !ref p:e:c:test_node:n#elb')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.id}"

      yaml = YAML.load('test: !ref p:e:c:test_node:n#elb.arn')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
    end

    context 'references' do
      it 'returns a list of referenced nodes' do
        yaml = YAML.load('test: !ref p:e:c:test_node:n#elb')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
        expect(yaml["test"].references).to eq [n0]
      end
    end

    context 'context' do
      it 'replaces project' do
        yaml = YAML.load('test: !ref :e:c:test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { project: "p" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end

      it 'replaces env for constant' do
        yaml = YAML.load('test: !ref constant::here')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { environment: "e" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "hello"
      end

      it 'replaces env for node' do
        yaml = YAML.load('test: !ref p::c:test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { environment: "e" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end

      it 'replaces config' do
        yaml = YAML.load('test: !ref p:e::test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { configuration: "c" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end
    end
  end

  context '!flatten' do
    it 'flattens a list' do
      yaml = YAML.load("test: !flatten
        - 1
        - - 2
      ")
      expect(HashUtils.json_dup(yaml)["test"]).to eq [1, 2]
    end

    it 'replaces internal refs first' do
      yaml = YAML.load("test: !flatten
        - !ref constant:e:here
        - - !ref constant:e:here
        - !ref constant:e:here
      ")
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq ["hello", "hello", "hello"]
    end

    context 'references' do
      it 'returns a list of referenced nodes' do
        yaml = YAML.load("test: !flatten
          - !ref p:e:c:test_node:n#elb
        ")
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
        expect(yaml["test"].references).to eq [n0]
      end
    end
  end

  context 'to_yaml' do
    it 'serializes to itself' do
      yaml = <<~HEREDOC
        ---
        sub_test: !sub prefix-{{constant:e:here}}-postfix
        test: !flatten
        - !ref constant:e:here
        - - !ref constant:e:here
        - !ref constant:e:here
      HEREDOC
      expect(YAML.load(yaml).to_yaml).to eq(yaml)
    end
  end

  context '==' do
    it 'returns true if the values are the same' do
      tag1 = GeoEngineer::GPS::YamlTag.new("tag::ref", "foobarbaz")
      tag2 = GeoEngineer::GPS::YamlTag.new("tag::ref", "foobarbaz")
      expect(tag1).to eq(tag2)
    end
  end

  context '<=>' do
    it 'sorts based on tag value' do
      unsorted = [
        GeoEngineer::GPS::YamlTag.new("tag::ref", 1),
        GeoEngineer::GPS::YamlTag.new("tag::ref", 3),
        GeoEngineer::GPS::YamlTag.new("tag::ref", 2)
      ]

      sorted = [
        GeoEngineer::GPS::YamlTag.new("tag::ref", 1),
        GeoEngineer::GPS::YamlTag.new("tag::ref", 2),
        GeoEngineer::GPS::YamlTag.new("tag::ref", 3)
      ]

      expect(unsorted.sort).to eq(sorted)
    end
  end
end
