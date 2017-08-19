require 'spec_helper'
require 'stringio'
require 'shellwords'

describe RSpec::Mate::Runner do
  def capture
    original_stdout = $stdout
    tmp_stdout = StringIO.new
    $stdout = tmp_stdout
    yield
    tmp_stdout.rewind
    tmp_stdout.read
  ensure
    $stdout = original_stdout
  end

  before do
    # TODO: long path
    @first_failing_spec  = %r{fixtures/example_failing_spec\.rb:3}n
    @second_failing_spec = %r{fixtures/example_failing_spec\.rb:7}n

    @original_env = ENV.to_hash
    set_env

    load File.expand_path(
      # TODO: long path
      "#{File.dirname(__FILE__)}/../../../lib/rspec/mate.rb"
    )

    # Make sure we don't overwrite the "real" files when running the examples here
    stub_const("RSpec::Mate::Runner::LAST_RUN_CACHE", "/tmp/textmate_rspec_last_run.test.yml")
    stub_const("RSpec::Mate::Runner::LAST_REMEMBERED_FILE_CACHE", "/tmp/textmate_rspec_last_remembered_file_cache.test.txt")

    @spec_mate = described_class.new
  end

  after do
    ENV.replace(@original_env)

    $".delete_if do |path|
      path =~ /example_failing_spec\.rb/
    end
  end

  describe "#run" do
    it "shows standard error output nicely in a PRE block" do
      ENV['TM_FILEPATH'] = fixtures_path('example_stderr_spec.rb')

      html = capture { @spec_mate.run_file }

      expect(html).to match(/#{Regexp.escape("<pre class='stderr'>2 + 2 = 4\n4 &lt; 8\n</pre>")}/)
    end
  end

  describe "#run_file" do
    it "runs whole file when only file specified" do
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')

      html = capture { @spec_mate.run_file }

      expect(html).to match @first_failing_spec
      expect(html).to match @second_failing_spec
    end
  end

  describe "#run_files" do
    it "runs all selected files" do
      fixtures = [
        'example_failing_spec.rb',
        'example_passing_spec.rb'
      ]

      # TODO: adjust fixtures_path to take an array
      ENV['TM_SELECTED_FILES'] = Shellwords.join(fixtures.map { |fixture| fixtures_path(fixture) })

      html = capture { @spec_mate.run_files }

      expect(html).to match @first_failing_spec
      expect(html).to match @second_failing_spec
      expect(html).to match(/should pass/)
      expect(html).to match(/should pass too/)
    end

    it 'runs all examples in "spec/" if nothing is selected' do
      ENV['TM_SELECTED_FILES'] = nil
      expect(@spec_mate).to receive(:run_rspec) do |argv|
        expect(argv[0]).to eq "spec/"
      end
      @spec_mate.run_files
    end
  end

  describe "#run_last_remembered_file" do
    it "runs all of the selected files" do
      @spec_mate.save_as_last_remembered_file fixtures_path('example_failing_spec.rb')
      html = capture { @spec_mate.run_last_remembered_file }

      expect(html).to match @first_failing_spec
    end
  end

  describe '#run_again' do
    def self.it_works_for(method, options={}, &block)
      run_cmd = options[:run_cmd] || :run_rspec
      it "works for #{method}" do
        original_argv = nil
        rerun_argv = nil
        expect(@spec_mate).to receive(run_cmd) do |argv|
          original_argv = argv.dup
        end
        instance_exec(&block)
        expect(original_argv).to_not be_nil
        expect(@spec_mate).to receive(run_cmd) do |argv|
          rerun_argv = argv.dup
        end
        @spec_mate.run_again
        expect(rerun_argv).to eq original_argv
      end
    end

    it_works_for '#run_file' do
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      @spec_mate.run_file
    end

    it_works_for '#run_files' do
      ENV['TM_SELECTED_FILES'] = "foo/bar_spec.rb baz/baz/baz/baz_spec.rb"
      @spec_mate.run_files
    end

    it_works_for '#run_focussed' do
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      ENV['TM_LINE_NUMBER'] = '4'
      @spec_mate.run_focussed
    end

    it_works_for '#run_focussed(in_terminal: true)', :run_cmd => :run_rspec_in_terminal do
      expect(TextMate).to receive(:exit_discard).twice
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      ENV['TM_LINE_NUMBER'] = '4'
      @spec_mate.run_focussed(:in_terminal => true)
    end
  end

  describe "#run_focussed" do
    it "runs first spec when file and line 4 specified" do
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      ENV['TM_LINE_NUMBER'] = '4'

      html = capture { @spec_mate.run_focussed }

      expect(html).to match @first_failing_spec
      expect(html).to_not match @second_failing_spec
    end

    it "runs second spec when file and line 8 specified" do
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      ENV['TM_LINE_NUMBER'] = '8'

      html = capture { @spec_mate.run_focussed }

      expect(html).to_not match @first_failing_spec
      expect(html).to match @second_failing_spec
    end
  end

  describe '#run_focussed(in_terminal: true)' do
    def expect_applescript_to_be_executed_including(script_line)
      expect(IO).to receive(:popen).with('osascript', 'w') do |&block|
        io = StringIO.new
        block.call(io)
        expect(io.string).to include(script_line)
      end
    end

    before do
      ENV['TM_PROJECT_DIRECTORY'] = '/foo/bar'
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')
      ENV['TM_LINE_NUMBER'] = '4'
      expect(Executable).to receive(:find).with('rspec').and_return(['command_to_run_rspec'])
      expect(TextMate).to receive(:exit_discard)
      @expected_shell_cmd = "cd /foo/bar && command_to_run_rspec #{e_sh(fixtures_path('example_failing_spec.rb'))}\\:4"
    end

    it 'runs RSpec in terminal (via Applescript)' do
      expect_applescript_to_be_executed_including %(do script "#{e_as(@expected_shell_cmd)}")
      @spec_mate.run_focussed(:in_terminal => true)
    end

    context 'with ENV["TM_TERMINAL_USE_TABS"] set' do
      it 'runs RSpec in a new terminal tab (via Applescript)' do
        ENV['TM_TERMINAL_USE_TABS'] = "1"
        expect_applescript_to_be_executed_including %(do script "#{e_as(@expected_shell_cmd)}" in the last tab of window 1)
        @spec_mate.run_focussed(:in_terminal => true)
      end
    end
  end

  describe "alternative formatter" do
    it "adds a custom formatter to the command if TM_RSPEC_FORMATTER is set" do
      ENV['TM_RSPEC_FORMATTER'] = 'RSpec::Core::Formatters::BaseTextFormatter'
      ENV['TM_FILEPATH'] = fixtures_path('example_failing_spec.rb')

      text = capture { @spec_mate.run_file }

      expect(text).to match(/1\) An example failing spec should fail/)
      expect(text).to match(/2\) An example failing spec should also fail/)
    end
  end

  describe '#run_rspec' do
    def expect_rspec_to_be_run_as(cmd)
      expect(Open3).to receive(:popen3).with(*cmd)
    end

    context 'with Gemfile.lock' do
      it 'uses `bundle exec rspec`' do
        ENV["TM_PROJECT_DIRECTORY"] = fixtures_path("project_with_gemfile")
        expect_rspec_to_be_run_as(%w[bundle exec rspec some args])
        @spec_mate.run_rspec(%w[some args])
      end
    end

    context 'without Gemfile.lock' do
      it 'uses `bin/rspec`, if a binstub is present' do
        ENV["TM_PROJECT_DIRECTORY"] = fixtures_path("project_with_binstub")
        expect_rspec_to_be_run_as(%w[bin/rspec some args])
        @spec_mate.run_rspec(%w[some args])
      end

      it 'uses `rspec`, if no binstub is present' do
        path_to_fake_rspec = File.join(fixtures_path("project_with_binstub"), "bin")
        ENV["PATH"] = path_to_fake_rspec + ":" + ENV["PATH"]
        ENV["TM_PROJECT_DIRECTORY"] = fixtures_path("legacy_project")
        expect_rspec_to_be_run_as(%w[rspec some args])
        @spec_mate.run_rspec(%w[some args])
      end
    end

    context 'when TM_RSPEC_BASEDIR is set' do
      it 'looks there for the Gemfile.lock' do
        ENV["TM_PROJECT_DIRECTORY"] = fixtures_path("project_with_gemfile")
        ENV["TM_RSPEC_BASEDIR"] = fixtures_path("project_with_gemfile") + "/subdir"
        expect_rspec_to_be_run_as(%w[bundle exec rspec some args])
        @spec_mate.run_rspec(%w[some args])
      end

      it 'looks there for the binstub' do
        ENV["TM_PROJECT_DIRECTORY"] = fixtures_path("project_with_binstub")
        ENV["TM_RSPEC_BASEDIR"] = fixtures_path("project_with_binstub") + "/subdir"
        expect_rspec_to_be_run_as(%w[bin/rspec some args])
        @spec_mate.run_rspec(%w[some args])
      end
    end
  end

private

  def fixtures_path(fixture_file=nil)
    # TODO: long path
    fixtures_path = File.expand_path(
      File.dirname(__FILE__)
    ) + '/../../../fixtures'

    File.expand_path(fixture_file ? File.join(fixtures_path, fixture_file) : fixtures_path)
  end

  def set_env
    ENV['TM_FILEPATH']          = nil
    ENV['TM_LINE_NUMBER']       = nil
    ENV['TM_PROJECT_DIRECTORY'] = File.expand_path("../../../../", __FILE__)
    ENV['TM_RSPEC_BASEDIR']     = nil
  end
end
