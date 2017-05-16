require 'html-proofer'

task :test do
  sh "bundle exec jekyll build"
  options = { :check_html => true, # :validation => { :report_missing_names, :report_invalid_tags => true, :report_script_embeds => true },
              :assume_extension => true, :url_ignore => [/localhost/] }
  HTMLProofer.check_directory("./_site", options).run
end
