$LOAD_PATH.unshift File.dirname(__FILE__) + "/../helpers"
$LOAD_PATH.unshift File.dirname(__FILE__) + "/../../lib"
require 'jruby-parser'
require 'parser_helpers'
require 'node_helpers'

describe Parser do
  [1.9].each do |v|
    it "parses a simple multiple assignment [#{v}]" do
      parse("a,b,c = 1,2,3", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, 2], [:c, 3]])
      end
    end

    it "parses a simple lhs splat multiple assignment [#{v}]" do
      parse("a,*b = 1,2,3", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, [2, 3]]])
      end
      parse("a,b,*c = 1,2,3,4", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, 2], [:c, [3,4]]])
      end
    end

    it "parses a simple lhs splat multiple assignment [#{v}]" do
      parse("*a,b = 1,2,3", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, [1, 2]], [:b, 3]])
      end
      parse("*a,b,c = 1,2,3,4", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, [1, 2]], [:b, 3], [:c, 4]])
      end
    end

    it "parses a simple lhs splat multiple assignment [#{v}]" do
      parse("a,*b, c = 1,2,3,4", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, [2, 3]], [:c, 4]])
      end
      parse("a, b, *c, d = 1,2,3,4,5", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, 2], [:c, [3, 4]], [:d, 5]])
      end
      parse("a, *b, c, d = 1,2,3,4,5", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, [2, 3]], [:c, 4], [:d, 5]])
      end
    end

    it "parses a simple lhs splat multiple assignment [#{v}]" do
      parse("a,*b,c,d = 1,2,3", v).find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, []], [:c, 2], [:d, 3]])
      end
    end

    it "parses a simple rhs splat multiple assignment [#{v}]" do
      ast = parse("a,*b = 1,*foo", v)
      foo = ast.find_node(:vcall)
      ast.find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, 1], [:b, foo]])
      end
    end

    it "parses a simple rhs splat multiple assignment [#{v}]" do
      ast = parse("*a,b = *foo,1", v)
      splatted_foo = ast.find_node(:splat)
      ast.find_node(:multipleasgn19).tap do |masgn|
        masgn.should have_static_assignments([[:a, splatted_foo], [:b, 1]])
      end
    end

    it "Can detect simple parameter is used" do
      parse("def foo(a); a; end").find_node(:defn) do |defn|
        defn.args.get_normative_parameter_name_list(true).each do |parameter|
          defn.is_parameter_used(parameter).should == true
        end
      end

      parse("def foo(a,b); a; b; end").find_node(:defn) do |defn|
        defn.args.get_normative_parameter_name_list(true).each do |parameter|
          defn.is_parameter_used(parameter).should == true
        end
      end
    end

    it "Can detect some simple parameters are used" do
      parse("def foo(a,b); b; end").find_node(:defn) do |defn|
        defn.is_parameter_used("a").should == false
        defn.is_parameter_used("b").should == true
      end

      parse("def foo(a,b); b if true; end").find_node(:defn) do |defn|
        defn.is_parameter_used("a").should == false
        defn.is_parameter_used("b").should == true
      end

      parse("def foo(a,b); proc { b if true }; end").find_node(:defn) do |defn|
        defn.is_parameter_used("a").should == false
        defn.is_parameter_used("b").should == true
      end

      parse("def foo a, b, c\nputs a, b, c\nend").find_node(:defn) do |defn|
        defn.is_parameter_used("a").should == true
        defn.is_parameter_used("b").should == true
        defn.is_parameter_used("c").should == true
      end

      parse("def foo(a, b); b.each_answer {|n| data if n == a }; end") do |defn|
        defn.is_parameter_used("a").should == true
        defn.is_parameter_used("b").should == true
      end
    end
  end
end
