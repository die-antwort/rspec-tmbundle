require 'stringio'
require 'cgi'

module RSpec
  module Mate
    class Runner
      def run_files(stdout, options={})
        files = ENV['TM_SELECTED_FILES'].scan(/'(.*?)'/).flatten.map do |path|
          File.expand_path(path)
        end

        options.merge!({:files => files})
        run(stdout, options)
      end

      def run_file(stdout, options={})
        options.merge!({:files => [single_file]})
        run(stdout, options)
      end

      def run_last_remembered_file(stdout, options={})
        options.merge!({:files => [last_remembered_single_file]})
        run(stdout, options)
      end

      def run_focussed(stdout, options={})
        options.merge!(
          {
            :files => [single_file],
            :line  => ENV['TM_LINE_NUMBER']
          }
        )

        run(stdout, options)
      end

      def run(stdout, options)
        stderr     = StringIO.new
        old_stderr = $stderr
        $stderr    = stderr
        default_formatter = rspec3? ? 'RSpec::Mate::Formatters::TextMateFormatter' : 'textmate'
        formatter  = ENV['TM_RSPEC_FORMATTER'] || default_formatter

        if rspec3?
          # If :line is given, only the first file from :files is used. This should be ok though, because
          # :line is only ever set in #run_focussed, and there :files is always set to a single file only.
          argv = options[:line] ? ["#{options[:files].first}:#{options[:line]}"] : options[:files].dup
        else
          argv = options[:files].dup
          if options[:line]
            argv << '--line'
            argv << options[:line]
          end
        end

        argv << '--format' << formatter
        argv << '-r' << File.join(File.dirname(__FILE__), 'text_mate_formatter') if formatter == 'RSpec::Mate::Formatters::TextMateFormatter'
        argv << '-r' << File.join(File.dirname(__FILE__), 'filter_bundle_backtrace')

        if ENV['TM_RSPEC_OPTS']
          argv += ENV['TM_RSPEC_OPTS'].split(" ")
        end

        Dir.chdir(project_directory) do
          if use_binstub?
             system 'bin/rspec', *argv
          elsif rspec3? || rspec2?
            ::RSpec::Core::Runner.disable_autorun!
            ::RSpec::Core::Runner.run(argv, stderr, stdout)
          else
            ::Spec::Runner::CommandLine.run(
              ::Spec::Runner::OptionParser.parse(argv, stderr, stdout)
            )
          end
        end
      rescue Exception => e
        require 'pp'

        stdout <<
          "<h1>Uncaught Exception</h1>" <<
          "<p>#{e.class}: #{e.message}</p>" <<
          "<pre>" <<
            CGI.escapeHTML(e.backtrace.join("\n  ")) <<
          "</pre>" <<
          "<h2>Options:</h2>" <<
          "<pre>" <<
            CGI.escapeHTML(PP.pp(options, '')) <<
          "</pre>"
      ensure
        unless stderr.string == ""
          stdout <<
            "<h2>stderr:</h2>" <<
            "<pre>" <<
              CGI.escapeHTML(stderr.string) <<
            "</pre>"
        end

        $stderr = old_stderr
      end

      def save_as_last_remembered_file(file)
        File.open(last_remembered_file_cache, "w") do |f|
          f << file
        end
      end

      def last_remembered_file_cache
        "/tmp/textmate_rspec_last_remembered_file_cache.txt"
      end


    private

      def last_remembered_single_file
        file = File.read(last_remembered_file_cache).strip

        if file.size > 0
          File.expand_path(file)
        end
      end

      def project_directory
        File.expand_path(ENV['TM_PROJECT_DIRECTORY']) rescue File.dirname(single_file)
      end

      def single_file
        File.expand_path(ENV['TM_FILEPATH'])
      end
    end
  end
end