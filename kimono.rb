# >----------------------------[ Initial Setup ]------------------------------<

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY

@recipes = ["devise", "bushido", "tane", "test_tools"] 

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

# >----------------------[ Devise and devise_bushido_authenticatable ]----------------------<

@current_recipe = "devise"
@before_configs["devise"].call if @before_configs["devise"]
say_recipe "Devise"

@configs[@current_recipe] = config

gem "devise"
gem "devise_bushido_authenticatable", :git =>"https://github.com/Bushido/devise_cas_authenticatable.git"

after_bundler do
  generate("devise:install")
  generate("devise", "User")
  
  Dir["db/migrate/*devise_create_*"].each do |file|
    # Replace database_authenticatable with bushido_authenticatable in the migration
    gsub_file file, "database_authenticatable :null => false", "bushido_authenticatable"

    # Replace the following lines to create fields for extra attributes
    gsub_file file, "t.recoverable",  "t.string :email"
    gsub_file file, "t.rememberable", "t.string :first_name"
    gsub_file file, "t.trackable",    "t.string :last_name"

    # Replace add_index for reset_password_token with ido_id
    gsub_file file, "reset_password_token", "ido_id"
  end
  
  user_model_file = "app/models/user.rb"

  inject_into_class user_model_file, "User" do
  <<-EOF
    def bushido_extra_attributes(extra_attributes)
      self.first_name = extra_attributes["first_name"].to_s
      self.last_name  = extra_attributes["last_name"].to_s
      self.email      = extra_attributes["email"]
      self.locale     = extra_attributes["locale"]
    end
  EOF
  end

  gsub_file user_model_file, ":recoverable, :rememberable, :trackable, :validatable", ""
  gsub_file user_model_file, ":database_authenticatable, :registerable,", ":bushido_authenticatable"

  gsub_file user_model_file,
            "attr_accessible :email, :password, :password_confirmation, :remember_me",
            "attr_accessible :email, :ido_id, :first_name, :last_name"
  
end

# >-------------------------------[ Bushido ]---------------------------------<

@current_recipe = "bushido"
@before_configs["bushido"].call if @before_configs["bushido"]
say_recipe "Bushido"

@configs[@current_recipe] = config

gem "bushido", :git=>"https://github.com/Bushido/bushidogem.git"

after_bundler do 
  generate("bushido:mail_routes")
  generate("bushido:hooks")
  generate("bushido:routes")
end


# >----------------------------------[ Tane ]----------------------------------<

@current_recipe = "tane"
@before_configs["tane"].call if @before_configs["tane"]
say_recipe "Tane"

gem "tane",               :group => "development", :git => "https://github.com/Bushido/tane.git"

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
