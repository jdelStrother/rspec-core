module RSpec
  module Core
    module Let

      module ExampleGroupMethods
        # Generates a method whose return value is memoized
        # after the first call.
        #
        # @example
        #
        #  describe Thing do
        #    let(:thing) { Thing.new }
        #
        #    it "does something" do
        #      # first invocation, executes block, memoizes and returns result
        #      thing.do_something
        #
        #      # second invocation, returns the memoized value
        #      thing.should be_something
        #    end
        #  end
        #
        # Under Ruby 1.9, you can also specify them using lambda literals in a hash :
        #
        # @example
        #   let widget: -> {Thing.new},
        #       gadget: -> {Thing.new}

        def let(name, &block)
          if name.is_a?(Hash)
            name.each{|k,v| let(k){v.call} }
          else
            define_method(name) do
              __memoized.fetch(name) {|k| __memoized[k] = instance_eval(&block) }
            end
          end
        end

        # Just like <tt>let()</tt>, except the block is invoked
        # by an implicit <tt>before</tt> hook. This serves a dual
        # purpose of setting up state and providing a memoized
        # reference to that state.
        #
        # @example
        #
        #  class Thing
        #    def self.count
        #      @count ||= 0
        #    end
        #
        #    def self.count=(val)
        #      @count += val
        #    end
        #
        #    def self.reset_count
        #      @count = 0
        #    end
        #
        #    def initialize
        #      self.class.count += 1
        #    end
        #  end
        #
        #  describe Thing do
        #    after(:each) { Thing.reset_count }
        #
        #    context "using let" do
        #      let(:thing) { Thing.new }
        #
        #      it "is not invoked implicitly" do
        #        Thing.count.should eq(0)
        #      end
        #
        #      it "can be invoked explicitly" do
        #        thing
        #        Thing.count.should eq(1)
        #      end
        #    end
        #
        #    context "using let!" do
        #      let!(:thing) { Thing.new }
        #
        #      it "is invoked implicitly" do
        #        Thing.count.should eq(1)
        #      end
        #
        #      it "returns memoized version on first invocation" do
        #        thing
        #        Thing.count.should eq(1)
        #      end
        #    end
        #  end
        def let!(name, &block)
          if name.is_a?(Hash)
            name.each{|k,v| let!(k){v.call} }
          else
            let(name, &block)
            before { __send__(name) }
          end
        end
      end

      module ExampleMethods
        # @api private
        def __memoized
          @__memoized ||= {}
        end
      end

      def self.included(mod)
        mod.extend ExampleGroupMethods
        mod.__send__ :include, ExampleMethods
      end

    end
  end
end
