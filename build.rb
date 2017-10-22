#!/usr/bin/env ruby

require 'rbconfig'
require 'optparse'
require 'fileutils'
require 'open3'

ROOT = File.expand_path(File.dirname(__FILE__))

FLAGS = {
  # Default verbosity.
  :verbose => false,

  # Toggles targeting of mobile platforms, i.e. Android and iOS.
  :mobile => false,

  # Toggles targeting of closed platforms, i.e. Xbox One and PlayStation 4.
  :closed => false,
}.freeze

$verbose = FLAGS[:verbose]

module Terminal
  def self.black(message); self.colorize(message, 30) end
  def self.red(message); self.colorize(message, 31) end
  def self.green(message); self.colorize(message, 32) end
  def self.yellow(message); self.colorize(message, 33) end
  def self.blue(message); self.colorize(message, 34) end
  def self.magenta(message); self.colorize(message, 35) end
  def self.cyan(message); self.colorize(message, 36) end
  def self.white(message); self.colorize(message, 37) end

 private
  def self.colorize(message, cc)
    $stdout.isatty() ? "\e[#{cc}m#{message}\e[0m" : message
  end
end

def log(message)
  puts(message) if $verbose
end

def panic(message)
  puts Terminal.red(message)
  exit 1
end

class Platform
  attr_reader :name

  def initialize(name)
    @name = name.dup.freeze
  end

  def self.detect
    case RbConfig::CONFIG["host_os"]
      when /mswin|windows|mingw|cygwin/i
        Platform.new('windows')
      when /darwin/i
        Platform.new('mac')
      when /linux/i
        Platform.new('linux')
        'linux'
      when /bsd/i
        Platform.new('bsd')
      else
        Platform.new('unknown')
      end
  end

  def defaults
    DEFAULTS[@name]
  end

  def windows?; @name == 'windows'; end
  def mac?; @name == 'mac'; end
  def linux?; @name == 'linux'; end
  def bsd?; @name == 'bsd'; end
  def uwp?; @name == 'uwp'; end
  def android?; @name == 'android'; end
  def ios?; @name == 'ios'; end
  def xb1?; @name == 'xb1'; end
  def ps4?; @name == 'ps4'; end

  def host?
    %w(windows mac linux).include?(@name)
  end

  def target?
    if mobile?
      FLAGS[:mobile]
    elsif closed?
      FLAGS[:closed]
    else
      true
    end
  end

  def desktop?; %w(windows mac linux bsd uwp).include?(@name); end
  def server?; %w(linux bsd).include?(@name); end
  def mobile?; %w(android ios).include?(@name); end

  def open?; !closed?; end
  def closed?; %w(xb1 ps4).include?(@name); end

  def known?; !unknown?; end
  def unknown?; @name == 'unknown'; end
end

HOST = Platform.detect.freeze

unless HOST.host?
  host = RbConfig::CONFIG["host_os"]
  panic "Building on `#{host}` is not supported."
end

if HOST.bsd?
  panic "Building on `bsd` is not supported yet."
end

HOSTS = %w(windows mac linux).freeze

TOOLCHAINS = %w(vs clang gcc).freeze

PLATFORMS = %w(windows mac linux uwp android ios xb1 ps4).freeze

ARCHITECTURES = %w(x86 x86_64).freeze

CONFIGURATIONS = %w(debug release).freeze

def filter_out_mobile(platforms)
  if FLAGS[:mobile] then platforms else [] end
end

def filter_out_closed(platforms)
  if FLAGS[:closed] then platforms else [] end
end

WHITELIST = {
  # Which toolchains can be used by which hosts.
  :toolchains => {
    'windows' => %w(vs),
    'mac' => %w(gcc clang),
    'linux' => %w(gcc clang)
  },

  # Which platforms can be targeted by which hosts.
  :platforms => {
    'windows' => %w(windows uwp) + filter_out_mobile(%w(android)) + filter_out_closed(%w(xb1 ps4)),
    'mac' => %w(mac) + filter_out_mobile(%w(ios)),
    'linux' => %w(linux) + filter_out_mobile(%w(android))
  },

  # Which architectures are supported on which platforms.
  :architectures => {
    'windows' => %w(x86 x86_64),
    'mac' => %w(x86 x86_64),
    'linux' => %w(x86 x86_64),
    'uwp' => %w(x86 x86_64 arm),
    'android' => %w(arm),
    'ios' => %w(arm),
    'xb1' => %w(x86_64),
    'ps4' => %w(x86_64)
  },

  # Which configurations are supported on which platforms.
  :configurations => {
    'windows' => %w(debug release),
    'mac' => %w(debug release),
    'linux' => %w(debug release),
    'uwp' => %w(debug release),
    'android' => %w(debug release),
    'ios' => %w(debug release),
    'xb1' => %w(debug release),
    'ps4' => %w(debug release)
  }
}.freeze

DEFAULTS = {
  'windows' => {
    toolchain: 'vs',
    platforms: %w(windows),
    architectures: %w(x86 x86_64),
    configurations: %w(debug release)
  },

  'mac' => {
    toolchain: 'clang',
    platforms: %w(mac),
    architectures: %w(x86 x86_64),
    configurations: %w(debug release)
  },

  'linux' => {
    toolchain: 'gcc',
    platforms: %w(linux),
    architectures: %w(x86 x86_64),
    configurations: %w(debug release)
  }
}.freeze

TARGETS = %w(project)

DEPENDENCIES = {
  'project' => []
}.freeze

SCRIPTS = {
  'project' => {
    'debug_windows_x86'      => '_build/build_debug_windows_32.bat',
    'release_windows_x86'    => '_build/build_release_windows_32.bat',
    'debug_windows_x86_64'   => '_build/build_debug_windows_64.bat',
    'release_windows_x86_64' => '_build/build_release_windows_64.bat',
    'debug_mac_x86'          => '_build/build_debug_mac_32.sh',
    'release_mac_x86'        => '_build/build_release_mac_32.sh',
    'debug_mac_x86_64'       => '_build/build_debug_mac_64.sh',
    'release_mac_x86_64'     => '_build/build_release_mac_64.sh',
    'debug_linux_x86'        => '_build/build_debug_linux_32.sh',
    'release_linux_x86'      => '_build/build_release_linux_32.sh',
    'debug_linux_x86_64'     => '_build/build_debug_linux_64.sh',
    'release_linux_x86_64'   => '_build/build_release_linux_64.sh'
  }
}.freeze

class BuildOptions
  attr_reader :toolchain,
              :platforms,
              :architectures,
              :configurations

  def initialize
    @toolchain = @platforms = @architectures = @configurations = nil
  end

  def parse(arguments)
    # Use built-in option parser to parse arguments.
    options = {}
    self.parser(options).parse!(arguments)

    # Validate and extract.
    extract!(options)

    self
  rescue OptionParser::ParseError => e
    puts e
    puts
    puts parser
    exit 1
  end

  def extract!(parsed)
    if parsed[:toolchain]
      if parsed[:toolchain][:name] == 'vs'
        version = if parsed[:toolchain][:version]
                    {
                      '2017' => '15.0',
                      '2015' => '14.0',
                      '2013' => '12.0',
                      '2012' => '11.0',
                      '2010' => '10.0',
                      '2008' => '9.0',
                      '2005' => '8.0',

                      'latest' => 'latest'
                    }.fetch(parsed[:toolchain][:version])
                  else
                    'latest'
                  end

        unless version
          panic "Bad toolchain version!"
        end

        @toolchain = {name: parsed[:toolchain][:name], version: version}
      else
        @toolchain = parsed[:toolchain]
      end
    else
      @toolchain = {name: DEFAULTS[HOST.name][:toolchain], version: 'latest'}
    end

    if parsed[:platforms]
      @platforms = parsed[:platforms]
    else
      @platforms = DEFAULTS[HOST.name][:platforms]
    end

    @platforms.each do |target|
      unless PLATFORMS.include?(target)
        panic "Cannot target `#{target}`!"
      end

      unless WHITELIST[:platforms][HOST.name].include?(target)
        panic "Cannot target `#{target}` on `#{HOST.name}` host!"
      end
    end

    if parsed[:architectures]
      @architectures = parsed[:architectures]
    else
      @architectures = DEFAULTS[HOST.name][:architectures]
    end

    @architectures.each do |architecture|
      unless ARCHITECTURES.include?(architecture)
        panic "Cannot target `#{architecture}` systems!"
      end
    end

    @platforms.each do |target|
      @architectures.each do |architecture|
        unless WHITELIST[:architectures][target].include?(architecture)
          panic "Cannot target `#{architecture}` and `#{target}`!"
        end
      end
    end

    if parsed[:configurations]
      @configurations = parsed[:configurations]
    else
      @configurations = DEFAULTS[HOST.name][:configurations]
    end

    @configurations.each do |configuration|
      unless CONFIGURATIONS.include?(configuration)
        panic "No `#{configuration}` configuration!"
      end
    end

    @platforms.each do |target|
      @configurations.each do |configuration|
        unless WHITELIST[:configurations][target].include?(configuration)
          panic "Cannot target `#{configuration}` configuration and `#{target}`."
        end
      end
    end
  end

  def parser(parsed)
    OptionParser.new do |options|
      options.banner = "Usage: build.rb [OPTIONS] [TARGETS]"

      options.separator ""

      options.on '--toolchain TOOLCHAIN', "Toolchain to use." do |toolchain|
        regex = /^([a-z]+)(?:\@([.0-9]*|latest))?$/
        matches = regex.match(toolchain)
        raise "Indecipherable toolchain specification!" unless matches
        parsed[:toolchain] = {name: matches[1], version: matches[2] || 'latest'}
      end

      options.on '--platform PLATFORMS', "Platforms to target." do |platform|
        parsed[:platform] = platform.split(',')
      end

      options.on '--architecture ARCHITECTURES', "Architectures to target." do |architectures|
        parsed[:architectures] = architectures.split(',')
      end

      options.on '--config CONFIGURATIONS', "Configurations to build." do |configurations|
        parsed[:configurations] = configurations.split(',')
      end

      options.separator ""

      options.on '-v', '--verbose', "Increases verbosity of output." do
        $verbose = true
      end

      options.separator ""

      options.on("-h", "--help", "Prints this help.") do
        puts options
        exit
      end
    end
  end
end

class CommandLineParser
  attr_reader :options,
              :targets

  def initialize
    @options = BuildOptions.new
    @targets = []
  end

  def parse(arguments)
    @options.parse(arguments)

    if arguments.length > 0
      # Targets have been explicitly specified.
      @targets.concat(arguments)
    else
      @targets.concat(TARGETS.dup)
    end

    validate!

    self
  end

  def validate!
    bad = @targets.reject do |target|
      TARGETS.include?(target)
    end

    if bad.length > 1
      panic "Given target `#{bad}` does not exist."
    elsif bad.length > 0
      panic "Given targets #{bad.join(' and ')} do not exist."
    end
  end
end

class BuildDriver
  def initialize(options)
    @threads = options.fetch(:threads, 1)
    @options = nil
    @targets = []
    @workload = 0
    @remaining = 0
    @tasks = []
  end

  def run(arguments)
    parse_command_line(arguments)
    expand_targets_to_dependencies
    derive_build_matrix
    calculate_work_load
    break_into_tasks
    run_tasks
  end

 private
  def parse_command_line(arguments)
    command_line_parser = CommandLineParser.new
    command_line_parser.parse(arguments.dup)

    @options = command_line_parser.options
    @targets = command_line_parser.targets
  end

  def expand_targets_to_dependencies
    tree = lambda { |targets|
      [*targets].map do |target|
        DEPENDENCIES[target].map do |dependency|
          tree.(dependency)
        end + [target]
      end.flatten.uniq
    }

    @targets = tree.(@targets)
  end

  def derive_build_matrix
    platforms = @options.platforms
    architectures = @options.architectures
    configurations = @options.configurations

    @matrix = configurations.product(platforms.product(architectures)).map(&:flatten)
  end

  def calculate_work_load
    @workload = @targets.length * @matrix.length
    @remaining = @workload
  end

  def break_into_tasks
    @targets.each do |target|
      @matrix.each do |config, platform, architecture|
        @tasks << lambda {
          task = @workload - (@remaining = @remaining - 1)

          triplet = "#{config}_#{platform}_#{architecture}"

          puts "[%2d/%-2d] Building `%s` for %s..." % [task, @workload, target, triplet]

          env = {
            'VERBOSE' => $verbose ? '1' : '0',
            'TOOLCHAIN' => @options.toolchain[:version]
          }

          success = !!system(ENV.to_h.merge(env), SCRIPTS[target][triplet])

          if success
            puts Terminal.green("[%2d/%-2d] Done." % [task, @workload])
          else
            puts Terminal.red("[%2d/%-2d] Failed!" % [task, @workload])
          end
        }
      end
    end
  end

  def run_tasks
    Dir.chdir(ROOT) do
      @tasks.each(&:call)
    end
  end
end

BuildDriver.new(:threads => 1).run(ARGV)
