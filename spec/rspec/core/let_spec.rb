require 'spec_helper'

describe "#let" do
  let(:counter) do
    Class.new do
      def initialize
        @count = 0
      end
      def count
        @count += 1
      end
    end.new
  end

  let(:nil_value) do
    @nil_value_count += 1
    nil
  end

  let foo: -> {1},
      bar: -> {2}

  it "generates an instance method" do
    counter.count.should eq(1)
  end

  it "caches the value" do
    counter.count.should eq(1)
    counter.count.should eq(2)
  end

  it "caches a nil value" do
    @nil_value_count = 0
    nil_value
    nil_value

    @nil_value_count.should eq(1)
  end

  it "should allow multiple lets from a hash" do
    foo.should eq(1)
    bar.should eq(2)
  end
end

describe "#let!" do
  let!(:creator) do
    Class.new do
      @count = 0
      def self.count
        @count += 1
      end
    end
  end

  let! foo: -> {1},
       bar: -> {2}

  it "evaluates the value non-lazily" do
    lambda { creator.count }.should_not raise_error
  end

  it "does not interfere between tests" do
    creator.count.should eq(1)
  end


  it "should allow multiple let!s from a hash" do
    foo.should eq(1)
    bar.should eq(2)
  end
end
