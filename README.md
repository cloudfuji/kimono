Kimono
=======

Rails template repo for Bushido. Right now there's only one template called "Kimono" which installs devise and devise_bushido_authenticatable.

To use this template to create a new Rails app, run:

        rails new your_rails_app -m https://raw.github.com/Bushido/kimono/master/kimono.rb

And that should generate a User model with devise installed and some
support files in the `config/initializers` and `lib/bushido` directory
of the app. You are ready to run `bundle exec rake db:migrate` and get
on with your life.
