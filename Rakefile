require 'html-proofer'

task :test do
  sh "bundle exec jekyll build"
  options = { :check_html => true, # :validation => { :report_missing_names, :report_invalid_tags => true, :report_script_embeds => true },
              :cache => { :timeframe => '2d'},
              :assume_extension => true, :url_ignore => [/localhost|github\.com\/istio\/istio\.github\.io\/edit\/master\//] }
  HTMLProofer.check_directory("./_site", options).run
end
