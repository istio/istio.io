netlify:
	@bundle install
	@bundle exec jekyll build --config _config.yml,config_override.yml
