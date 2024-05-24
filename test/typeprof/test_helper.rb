begin
  require "simplecov"
  SimpleCov.start do
    add_filter "rbs"
  end
rescue LoadError
end

require "test-unit"
require "stringio"

module TypeProf
  class TestRun
    def self.run(name, rbs_path: nil, **opt)
      new(name, rbs_path).run(**opt)
    end

    def initialize(name, rbs_path)
      @name, @rbs_path = name, rbs_path
    end

    def run(gem_rbs_features: [], **options)
      verbose_back, $VERBOSE = $VERBOSE, nil

      rb_files = [@name]
      rbs_files = [@rbs_path].compact
      output = StringIO.new(+"")
      options[:show_untyped] = true unless options.key?(:show_untyped)
      options[:show_errors] = true unless options.key?(:show_errors)
      options[:show_indicator] = false unless options.key?(:show_indicator)
      options[:show_typeprof_version] = false unless options.key?(:show_typeprof_version)
      config = TypeProf::ConfigData.new(
        rb_files: rb_files,
        rbs_files: rbs_files,
        gem_rbs_features: gem_rbs_features,
        output: output,
        options: options,
        verbose: 0,
      )
      TypeProf.analyze(config)

      output = output.string

      RBS::Parser.parse_signature(output[/# Classes.*\z/m]) unless options[:skip_parsing_test]

      output

    ensure
      $VERBOSE = verbose_back
    end

    def self.setup_testbed_repository(dir, github_repo_url, revision)
      dir = File.join(__dir__, "../../testbed/", dir)
      unless File.directory?(dir)
        Dir.mkdir(dir)
        system("git", "init", "-b", "master", chdir: dir, exception: true)
        system("git", "remote", "add", "origin", github_repo_url, chdir: dir, exception: true)
        system("git", "fetch", "origin", revision, chdir: dir, exception: true)
      end
      system("git", "reset", "--quiet", "--hard", revision, chdir: dir, exception: true)

      true
    rescue Errno::ENOENT
      false
    end
  end
end
