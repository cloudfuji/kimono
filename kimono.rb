gem "bushido", :git=>"https://github.com/Bushido/bushidogem.git"
gem "devise_bushido_authenticatable", :git =>"https://github.com/Bushido/devise_cas_authenticatable.git"

gem "rspec-rails",     :group => "development"
gem "awesome_print",   :group => "development"
gem "tane",            :group => "development", :git => "https://github.com/Bushido/tane.git"


lib("bushido/hooks/user_hooks.rb") do
<<EOF
class BushidoUserHooks < Bushido::EventObserver
  def user_added
    user.create(:email  => params['data']['email'],
      :ido_id => params['data']['ido_id'],
      :active => true)
  end

  def user_removed
    User.find_by_ido_id(params['data']['ido_id']).try(:disable!)
  end
end
EOF
end

lib('bushido/hooks/app_hooks.rb') do
<<EOF
class BushidoAppHooks < Bushido::EventObserver
  def app_claimed
    User.find(1).update_attributes(:email  => params['data']['email'],
      :ido_id => params['data']['ido_id'])
  end
end
EOF
end

lib("bushido/bushido_mail_routes.rb") do
<<EOF
# Mail routes
::Bushido::Mailroute.map do |m|

  m.route("mail.simple") do
    m.subject("hello")
  end

end
EOF
end

lib("bushido/hooks/email_hooks.rb") do
<<EOF
class BushidoEmailHooks < Bushido::EventObserver

  def mail_simple
    puts "YAY!"
    puts params.inspect
  end

  private
end
EOF
end

create_file("config/initializers/bushido_hooks.rb") do
<<EOF
Dir["\#{Dir.pwd}/lib/bushido/**/*.rb"].each { |file| require file }
EOF
end

create_file("config/initializers/bushido_mail_routes.rb") do
<<EOF
require './lib/bushido/bushido_mail_routes.rb'
EOF
end

prepend_to_file("config/routes.rb") do
<<EOF
begin
  Rails.application.routes.draw do
    bushido_routes
  end
rescue => e
  puts "Error loading the Bushido routes:"
  puts "\#{e.inspect}"
end
EOF
end

run "bundle install"

generate('devise:install')
generate('devise', 'User')
