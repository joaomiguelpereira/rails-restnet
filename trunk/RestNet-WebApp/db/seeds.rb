# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
user = User.create(:handle=>'admin',
:first_name=>'Super',
:last_name=>'Admin',
:password=>"qazwsx", :password_confirmation=>"qazwsx", 
:email=>"joaomiguel.pereira@gmail.com", :accept=>"1", :active=>true, :admin=>true)
user.admin = true
user.active = true
user.save
