require 'support/aruba_support'

RSpec.describe 'Shared Example Rerun Commands' do
  include_context "aruba support"
  before { clean_current_dir }

  it 'prints a rerun command for shared examples in external files that works to rerun' do
    write_file "spec/support/shared_examples.rb", """
      RSpec.shared_examples 'a failing example' do
        example { expect(1).to eq(2) }
      end
    """

    write_file "spec/host_group_spec.rb", """
      load File.expand_path('../support/shared_examples.rb', __FILE__)

      RSpec.describe 'A group with shared examples' do
        include_examples 'a failing example'
      end

      RSpec.describe 'A group with a passing example' do
        example { expect(1).to eq(1) }
      end
    """

    run_command ""
    expect(last_cmd_stdout).to include("2 examples, 1 failure")
    run_rerun_command_for_failing_spec
    expect(last_cmd_stdout).to include("1 example, 1 failure")
    # There was originally a bug when doing it again...
    run_rerun_command_for_failing_spec
    expect(last_cmd_stdout).to include("1 example, 1 failure")
  end

  def run_rerun_command_for_failing_spec
    command = last_cmd_stdout[/Failed examples:\s+rspec (\S+) #/, 1]
    run_command command
  end

  context "with a shared example containing a context in a separate file" do
    it "runs the example nested inside the shared" do
      write_file_formatted 'spec/shared_example.rb', """
        RSpec.shared_examples_for 'a shared example' do
          it 'succeeds' do
          end

          context 'with a nested context' do
            it 'succeeds (nested)' do
            end
          end
        end
      """

      write_file_formatted 'spec/simple_spec.rb', """
        require File.join(File.dirname(__FILE__), 'shared_example.rb')

        RSpec.describe 'top level' do
          it_behaves_like 'a shared example'
        end
      """

      run_command 'spec/simple_spec.rb:3 -fd'
      expect(last_cmd_stdout).to match(/2 examples, 0 failures/)
    end
  end

  context "passing a line-number-filtered file and a non-filtered file" do
    it "applies the line number filtering only to the filtered file, running all specs in the non-filtered file" do
      write_file_formatted "spec/file_1_spec.rb", """
        RSpec.describe 'File 1' do
          it('passes') {      }
          it('fails')  { fail }
        end
      """

      write_file_formatted "spec/file_2_spec.rb", """
        RSpec.describe 'File 2' do
          it('passes') { }
          it('passes') { }
        end
      """

      run_command "spec/file_1_spec.rb:2 spec/file_2_spec.rb -fd"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)
      expect(last_cmd_stdout).not_to match(/fails/)
    end
  end
end