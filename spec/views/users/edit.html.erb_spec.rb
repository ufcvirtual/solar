require 'spec_helper'

describe "users/edit.html.erb" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :id => 1,
      :login => "MyString",
      :email => "MyString",
      :password => "MyString",
      :name => "MyString",
      :nick => "MyString",
      :enrollment_code => "MyString",
      :cpf => "MyString",
      :sex => "MyString",
      :special_needs => "MyString",
      :address => "MyString",
      :address_number => 1,
      :address_complement => "MyString",
      :address_neighborhood => "MyString",
      :zipcode => 1,
      :country => "MyString",
      :state => "MyString",
      :city => "MyString",
      :telephone => 1,
      :cell_phone => 1,
      :institution => "MyString"
    ))
  end

  it "renders the edit user form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => user_path(@user), :method => "post" do
      assert_select "input#user_id", :name => "user[id]"
      assert_select "input#user_login", :name => "user[login]"
      assert_select "input#user_email", :name => "user[email]"
      assert_select "input#user_password", :name => "user[password]"
      assert_select "input#user_name", :name => "user[name]"
      assert_select "input#user_nick", :name => "user[nick]"
      assert_select "input#user_enrollment_code", :name => "user[enrollment_code]"
      assert_select "input#user_cpf", :name => "user[cpf]"
      assert_select "input#user_sex", :name => "user[sex]"
      assert_select "input#user_special_needs", :name => "user[special_needs]"
      assert_select "input#user_address", :name => "user[address]"
      assert_select "input#user_address_number", :name => "user[address_number]"
      assert_select "input#user_address_complement", :name => "user[address_complement]"
      assert_select "input#user_address_neighborhood", :name => "user[address_neighborhood]"
      assert_select "input#user_zipcode", :name => "user[zipcode]"
      assert_select "input#user_country", :name => "user[country]"
      assert_select "input#user_state", :name => "user[state]"
      assert_select "input#user_city", :name => "user[city]"
      assert_select "input#user_telephone", :name => "user[telephone]"
      assert_select "input#user_cell_phone", :name => "user[cell_phone]"
      assert_select "input#user_institution", :name => "user[institution]"
    end
  end
end
