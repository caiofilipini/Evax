require "yaml"
require "uglifier"

require_relative "evax/version"
require_relative "evax/css_minifier"
require_relative "evax/logger"

class Evax
  attr_reader :config_file, :relative_path

  def initialize( config_file = "config/assets.yml", relative_path = "public/assets" )
    @config_file   = File.expand_path( config_file )
    @relative_path = File.expand_path( relative_path )

    Evax::Logger.log "Config File: #{self.config_file}"
    Evax::Logger.log "Relative Path: #{self.relative_path}"
  end

  def config
    YAML::load_file( @config_file )
  end

  def join( type, group_name )
    config[type.to_s][group_name].map do |file_path|
      File.read( File.join(relative_path, file_path) )
    end.join( "\n" )
  end

  def build
    build_js
    build_css
  end

  def build_js
    config["javascripts"].each_key do |group_name|
      join_string     = join( :javascripts, group_name )
      compress_string = Evax.compress_js( join_string )

      write_output( "#{group_name}.js", compress_string )
    end
  end

  def build_css
    config["stylesheets"].each_key do |group_name|
      join_string     = join( :stylesheets, group_name )
      compress_string = Evax.compress_css( join_string )

      write_output( "#{group_name}.css", compress_string )
    end
  end

  def write_output( file_name, string )
    path      = File.expand_path( File.join( relative_path, config['output_path'] ) )
    file_path = File.join( path, file_name )

    Evax::Logger.log "Writing file: #{file_path}"

    FileUtils.mkdir_p path
    File.open( file_path, 'w' ) { |f| f.write string }
  end

  def self.compress_js( js_string )
    opts = {
      :max_line_length  => 1024,
      :toplevel         => true,
      :copyright        => false
    }
    Uglifier.compile( js_string, opts )
  end

  def self.compress_css( css_string )
    Evax::CssMinifier.build( css_string )
  end

end
