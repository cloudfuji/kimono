Kimono
=======

Rails template repo for Cloudfuji. Right now there's only one template called "Kimono" which installs devise and devise_cloudfuji_authenticatable.

To use this template to create a new Rails app, run:

        rails new your_rails_app -m https://raw.github.com/cloudfuji/kimono/master/kimono.rb

And that should generate a User model with devise installed and some
support files in the `config/initializers` and `lib/cloudfuji` directory
of the app. You are ready to run `bundle exec rake db:migrate` and get
on with your life.
