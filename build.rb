#!/usr/bin/env ruby

require 'rbconfig'
require 'optparse'
require 'fileutils'
require 'open3'

HOST =
  case RbConfig::CONFIG["host_os"]
    when /mswin|windows|mingw|cygwin/i
      'windows'
    when /darwin/i
      'mac'
    when /linux/i
      'linux'
    end

TOOLCHAINS = %w(vs clang gcc).freeze
PLATFORMS = %w(windows mac linux uwp android ios xb1 ps4).freeze
ARCHITECTURES = %w(x86 x86_64).freeze
CONFIGURATIONS = %w(debug release).freeze

FLAGS = {
  # Enables targeting of mobile platforms, i.e. Android and iOS.
  :mobile => false,
  # Enables targeting of closed platforms, i.e. Xbox One and PlayStation 4.
  :closed => false,
}.freeze

def filter_out_mobile(platforms)
  if FLAGS[:mobile] then platforms else [] end
end

def filter_out_closed(platforms)
  if FLAGS[:closed] then platforms else [] end
end

WHITELIST = {
  :toolchains => {
    'windows' => %w(vs),
    'mac' => %w(gcc clang),
    'linux' => %w(gcc clang)
  },

  :platforms => {
    'windows' => %w(windows uwp) + filter_out_mobile(%w(android)) + filter_out_closed(%w(xb1 ps4)),
    'mac' => %w(mac) + filter_out_mobile(%w(ios)),
    'linux' => %w(linux) + filter_out_mobile(%w(android))
  },

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

class String
  def default; colorize(39) end

  def black; colorize(30) end
  def red; colorize(31) end
  def green; colorize(32) end
  def yellow; colorize(33) end
  def blue; colorize(34) end
  def magenta; colorize(35) end
  def cyan; colorize(36) end
  def white; colorize(37) end

  def colorize(cc)
    $stdout.isatty() ? "\e[#{cc}m#{self}\e[0m" : self
  end
end

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
          puts "Bad toolchain version!".red
          exit 1
        end

        @toolchain = {name: parsed[:toolchain][:name], version: version}
      else
        @toolchain = parsed[:toolchain]
      end
    else
      @toolchain = [DEFAULTS[HOST][:toolchain], 'latest']
    end

    if parsed[:platforms]
      @platforms = parsed[:platforms]
    else
      @platforms = DEFAULTS[HOST][:platforms]
    end

    @platforms.each do |target|
      unless PLATFORMS.include?(target)
        puts "Cannot target `#{target}`!".red
        exit 1
      end

      unless WHITELIST[:platforms][HOST].include?(target)
        puts "Cannot target `#{target}` on `#{HOST}` host!".red
        exit 1
      end
    end

    if parsed[:architectures]
      @architectures = parsed[:architectures]
    else
      @architectures = DEFAULTS[HOST][:architectures]
    end

    @architectures.each do |architecture|
      unless ARCHITECTURES.include?(architecture)
        puts "Cannot target `#{arch}` systems!".red
        exit 1
      end
    end

    @platforms.each do |target|
      @architectures.each do |architecture|
        unless WHITELIST[:architectures][target].include?(architecture)
          puts "Cannot target `#{architecture}` and `#{target}`!".red
          exit 1
        end
      end
    end

    if parsed[:configurations]
      @configurations = parsed[:configurations]
    else
      @configurations = DEFAULTS[HOST][:configurations]
    end

    @configurations.each do |configuration|
      unless CONFIGURATIONS.include?(configuration)
        puts "No `#{configuration}` configuration!".red
        exit 1
      end
    end

    @platforms.each do |target|
      @configurations.each do |configuration|
        unless WHITELIST[:configurations][target].include?(configuration)
          puts "Cannot target `#{configuration}` configuration and `#{target}`.".red
          exit 1
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

      options.on("-h", "--help", "Prints this help.") do
        puts options
        exit
      end
    end
  end
end

arguments = ARGV.dup

options = BuildOptions.new.parse(arguments)

targets = if arguments.length > 0
            arguments.dup.freeze
          else
            TARGETS
          end

targets.each do |target|
  unless TARGETS.include?(target)
    puts "No target `#{target}`.".red
    exit 1
  end
end

def matrix(configurations, platforms, architectures)
  configurations.product(platforms.product(architectures)).map(&:flatten)
end

def tree(targets)
  [*targets].map do |target|
    DEPENDENCIES[target].map do |dependency|
      tree(dependency)
    end + [target]
  end.flatten.uniq
end

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

tree = tree(targets)
matrix = matrix(options.configurations, options.platforms, options.architectures)

built = 0
building = tree.length * matrix.length

Dir.chdir(File.expand_path(File.dirname(__FILE__))) do
  tree.each do |target|
    matrix.each do |config, platform, architecture|
      triplet = "#{config}_#{platform}_#{architecture}"

      puts "[%2d/%-2d] Building `%s` for %s..." % [built+1, building, target, triplet]

      env = {
        'TOOLCHAIN' => options.toolchain[:version]
      }

      success = !!system(ENV.to_h.merge(env), SCRIPTS[target][triplet])

      if success
        puts ("[%2d/%-2d] Success!" % [built+1, building]).green
      else
        puts ("[%2d/%-2d] Failed!" % [built+1, building]).red
      end

      built = built + 1
    end
  end
end
