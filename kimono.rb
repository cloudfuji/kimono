# >----------------------------[ Initial Setup ]------------------------------<

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY

@recipes = ["devise", "cloudfuji", "tane", "test_tools"] 

def recipes; @recipes end
def recipe?(name); @recipes.include?(name) end

def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end
def say_recipe(name); say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..." end
def say_wizard(text); say_custom(@current_recipe || 'wizard', text) end

def ask_wizard(question)
  ask "\033[1m\033[30m\033[46m" + (@current_recipe || "prompt").rjust(10) + "\033[0m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

def no_wizard?(question); !yes_wizard?(question) end

def multiple_choice(question, choices)
  say_custom('question', question)
  values = {}
  choices.each_with_index do |choice,i| 
    values[(i + 1).to_s] = choice[1]
    say_custom (i + 1).to_s + ')', choice[0]
  end
  answer = ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

@current_recipe = nil
@configs = {}

@after_blocks = []
def after_bundler(&block); @after_blocks << [@current_recipe, block]; end
@after_everything_blocks = []
def after_everything(&block); @after_everything_blocks << [@current_recipe, block]; end
@before_configs = {}
def before_config(&block); @before_configs[@current_recipe] = block; end

# >----------------------[ Devise and devise_cloudfuji_authenticatable ]----------------------<

@current_recipe = "devise"
@before_configs["devise"].call if @before_configs["devise"]
say_recipe "Devise"

@configs[@current_recipe] = config

gem "devise"
gem "devise_cloudfuji_authenticatable"

after_bundler do
  generate("devise:install")
  generate("devise", "User")
  
  Dir["db/migrate/*devise_create_*"].each do |file|
    # Replace database_authenticatable with cloudfuji_authenticatable in the migration
    gsub_file file, "database_authenticatable :null => false", "cloudfuji_authenticatable"

    # Replace the following lines to create fields for extra attributes
    gsub_file file, "t.recoverable",  "t.string :email"
    gsub_file file, "t.rememberable", "t.string :first_name"
    gsub_file file, "t.trackable",    "t.string :last_name"
    inject_into_file file, "t.string :locale\n", :after => "t.string :last_name\n"
    inject_into_file file, "t.string :timezone\n", :after => "t.string :locale\n"

    # Replace add_index for reset_password_token with ido_id
    gsub_file file, "reset_password_token", "ido_id"
  end
  
  user_model_file = "app/models/user.rb"

  inject_into_class user_model_file, "User" do
  <<-EOF
    def cloudfuji_extra_attributes(extra_attributes)
      self.first_name = extra_attributes["first_name"].to_s
      self.last_name  = extra_attributes["last_name"].to_s
      self.email      = extra_attributes["email"]
      self.locale     = extra_attributes["locale"]
      self.timezone     = extra_attributes["timezone"]
    end
  EOF
  end

  gsub_file user_model_file, ":recoverable, :rememberable, :trackable, :validatable", ""
  gsub_file user_model_file, ":database_authenticatable, :registerable,", ":cloudfuji_authenticatable"

  gsub_file user_model_file,
            "attr_accessible :email, :password, :password_confirmation, :remember_me",
            "attr_accessible :email, :ido_id, :first_name, :last_name"
  
end

# >-------------------------------[ Cloudfuji ]---------------------------------<

@current_recipe = "cloudfuji"
@before_configs["cloudfuji"].call if @before_configs["cloudfuji"]
say_recipe "Cloudfuji"

@configs[@current_recipe] = config

gem "cloudfuji"

after_bundler do
  initializer "cloudfuji_bar.rb" do
  <<-EOF
# These are the paths to render the Cloudfuji bar on, which allows users to navigate to their various Cloudfuji apps, to update their account, and to invite others from within your app
# You may include multiple paths, each should be a regex to match against the incoming url
# This defaults to showing the bar on all paths
Cloudfuji::Bar.set_bar_display_paths(/.*/)
  EOF
  end

  generate("cloudfuji:mail_routes")
  generate("cloudfuji:hooks")
  generate("cloudfuji:routes")
end


# >----------------------------------[ Tane ]----------------------------------<

@current_recipe = "tane"
@before_configs["tane"].call if @before_configs["tane"]
say_recipe "Tane"

gem "tane"

# >-------------------------------[ Test Tools ]-------------------------------<

@current_recipe = "test_tools"
@before_configs["test_tools"].call if @before_configs["test_tools"]
say_recipe "Test tools"

gem "rspec-rails",        :group => "development"
gem "factory_girl_rails", :group => "development"
gem "awesome_print",      :group => "development"


# >-----------------------------[ Run Bundler ]-------------------------------<

@current_recipe = nil

say_wizard "Running Bundler install. This will take a while."
run 'bundle install'
say_wizard "Running after Bundler callbacks."
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Running after everything callbacks."
@after_everything_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}
