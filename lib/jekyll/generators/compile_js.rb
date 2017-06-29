#  (c) Aaron Gustafson
#  https://github.com/aarongustafson/jekyll-webmention_io 
#  Licence : MIT
#  
#  This generator gathers webmentions of your pages
#

require 'uglifier'

module Jekyll
  module WebmentionIO
    using StringInflection
    class CompileJS < Generator
      
      safe true
      priority :low
      
      def generate(site)
        if site.config['webmentions']['js'] == false
          Jekyll::WebmentionIO::log 'info', 'Skipping JavaScript inclusion.'
          return
        end

        config = {
          'destination' => "js",
          'uglify'      => true
        }
        site_config = site.config['webmentions']['js'] || {}
        
        config = config.merge(site_config)
        
        source = File.join(File.dirname(File.expand_path(__FILE__)), '../assets/')
        
        javascript = ''
        Dir["#{source}/*.js"].each do |file|
          handler = File.open(file, 'rb')
          javascript << File.read(handler)
        end
        
        # Dump in types
        types_js = ';(function(window,JekyllWebmentionIO){'
        types_js << 'if ( ! ( \'JekyllWebmentionIO\' in window ) ){ window.JekyllWebmentionIO = {}; }'
        types_js << 'JekyllWebmentionIO.types = { '
        js_types = []
        Jekyll::WebmentionIO::types.each do |type|
          js_types.push "'#{type}': '#{type.to_singular}'"
        end
        types_js << js_types.join(',')
        types_js << '};(this, this.JekyllWebmentionIO));'
        javascript << types_js
        
        unless config['uglify'] == false
          uglify_config = {
            :harmony => true
          }
          javascript = Uglifier.new(uglify_config).compile(javascript)
        end

        # Generate the file in the source folder
        source_file_destination = "#{site.config['source']}/#{config['destination']}"
        Dir.mkdir( source_file_destination ) unless File.exists?( source_file_destination )
        file_name = 'JekyllWebmentionIO.js'
        File.open("#{source_file_destination}/#{file_name}", 'w') { |f| f.write( javascript ) }

        unless config['deploy'] == false
          # Make sure Jekyll picks it up too
          js_file = StaticFile.new(site, site.config['source'], config['destination'], file_name)
          site.static_files << js_file
        end
      end
    end
  end
end