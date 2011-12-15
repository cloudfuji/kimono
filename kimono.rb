gem "bushido", :git=>"https://github.com/Bushido/bushidogem.git"
gem "devise_bushido_authenticatable", :git =>"https://github.com/Bushido/devise_cas_authenticatable.git"

gem "rspec-rails",        :group => "development"
gem "factory_girl_rails", :group => :development
gem "awesome_print",      :group => "development"
gem "tane",               :group => "development", :git => "https://github.com/Bushido/tane.git"


# lib/bushido/hooks/user_hooks.rb
lib("bushido/hooks/user_hooks.rb") do
<<-EOF
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


# lib/bushido/hooks/app_hooks.rb
lib('bushido/hooks/app_hooks.rb') do
<<-EOF
class BushidoAppHooks < Bushido::EventObserver
  def app_claimed
    User.find(1).update_attributes(:email  => params['data']['email'],
      :ido_id => params['data']['ido_id'])
  end
end
EOF
end


# lib/bushido/bushido_mail_routes.rb
lib("bushido/bushido_mail_routes.rb") do
<<-EOF
# Mail routes
::Bushido::Mailroute.map do |m|

  m.route("mail.simple") do
    m.subject("hello")
  end

end
EOF
end


# lib/bushido/hooks/email_hooks.rb
lib("bushido/hooks/email_hooks.rb") do
<<-EOF
class BushidoEmailHooks < Bushido::EventObserver

  def mail_simple
    puts "YAY!"
    puts params.inspect
  end

  private
end
EOF
end


# config/initializers/bushido_hooks.rb
create_file("config/initializers/bushido_hooks.rb") do
<<-EOF
Dir["\#{Dir.pwd}/lib/bushido/**/*.rb"].each { |file| require file }
EOF
end


# config/initializers/bushido_mail_routes.rb
create_file("config/initializers/bushido_mail_routes.rb") do
<<-EOF
require './lib/bushido/bushido_mail_routes.rb'
EOF
end


# config/routes.rb
prepend_to_file("config/routes.rb") do
<<-EOF
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


run("bundle install")
generate("devise:install")
generate("devise", "User")


Dir["db/migrate/*devise_create_*"].each do |file|
  # Replace database_authenticatable with bushido_authenticatable in the migration
  gsub_file file, "database_authenticatable :null => false", "bushido_authenticatable"

  # Replace the following lines to create fields for extra attributes
  gsub_file file, "t.recoverable",  "t.string :email"
  gsub_file file, "t.rememberable", "t.string :first_name"
  gsub_file file, "t.trackable",    "t.string :last_name"

  # replace add_index for reset_password_token with ido_id
  gsub_file file, "reset_password_token", "ido_id"
end

inject_into_class "app/models/user.rb", "User" do
<<-EOF
  def bushido_extra_attributes(extra_attributes)
    self.first_name = extra_attributes["first_name"].to_s
    self.last_name  = extra_attributes["last_name"].to_s
    self.email      = extra_attributes["email"]
  end
EOF
end


gsub_file "app/models/user.rb", ":recoverable, :rememberable, :trackable, :validatable", ""
gsub_file "app/models/user.rb", ":database_authenticatable", ":bushido_authenticatable"
gsub_file "app/models/user.rb", ", :registerable,", ""

gsub_file "app/models/user.rb",
          "attr_accessible :email, :password, :password_confirmation, :remember_me",
          "attr_accessible :email, :ido_id, :first_name, :last_name"

