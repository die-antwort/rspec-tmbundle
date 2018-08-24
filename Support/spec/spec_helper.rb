ENV['TM_PROJECT_DIRECTORY'] ||= '.'

require 'stringio'
require 'rspec/mate'
require 'rspec/core'
require 'rspec/core/sandbox'

RSpec.configure do |config|
  # See https://github.com/rspec/rspec-core/blob/5bee47543e78cf769ee4812c3bf7c00a91765b3a/spec/support/sandboxing.rb
  config.around(:example, :sandboxed) do |ex|
    RSpec::Core::Sandbox.sandboxed do |sandbox_config|
      # If there is an example-within-an-example, we want to make sure the inner example
      # does not get a reference to the outer example (the real spec) if it calls
      # something like `pending`
      sandbox_config.before(:context) { RSpec.current_example = nil } # rubocop:disable RSpec/BeforeAfterAll

      orig_load_path = $LOAD_PATH.dup
      ex.run
      $LOAD_PATH.replace(orig_load_path)
    end
  end

  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
