#Load the WEB APP configuration for the current environment
WEBAPP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/webapp_config.yml")[Rails.env]


ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default_charset = "utf-8"

ActionMailer::Base.smtp_settings = {
  :address => "#{WEBAPP_CONFIG["smtp_settings"]["address"]}",
  :port => WEBAPP_CONFIG["smtp_settings"]["port"],
  :domain => "#{WEBAPP_CONFIG["smtp_settings"]["domain"]}",
  :authentication => :login,
  :user_name => "#{WEBAPP_CONFIG["smtp_settings"]["user_name"]}",
  :password => "#{WEBAPP_CONFIG["smtp_settings"]["password"]}"
}
