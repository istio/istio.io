require 'html-proofer'

task :test do
  sh "rm -fr _rakesite"
  sh "mkdir _rakesite"
  sh "bundle exec jekyll build --config _config.yml,_rake_config_override.yml"
  typhoeus_configuration = {
  :timeout => 30,
#  :verbose => true
  }
  options = { :check_html => true,
              # :validation => { :report_missing_names => true, :report_invalid_tags => true },
              :cache => { :timeframe => '2d'},
              :enforce_https => false, # we should turn this on eventually
              :directory_index_file => "index.html",
              :check_external_hash => false,
              :assume_extension => true,
  #            :log_level => :debug,
              :url_ignore => [/localhost|github\.com\/istio\/istio\.github\.io\/edit\/master\//],
              :typhoeus => typhoeus_configuration,
             }
  HTMLProofer.check_directory("./_rakesite", options).run
end
