When /^(?:|I )fill (billing|shipping) address with correct data$/ do |address_type|
  str_addr = address_type[0...4] + "_address"
  address = if @me
    @me.send(str_addr)
  else
    state = State.first
    Factory(:address, :state => state)
  end

  When %{I select "United States" from "Country" within "fieldset##{address_type}"}

  ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
    When %{I fill in "order_#{str_addr}_attributes_#{field}" with "#{address.send(field)}"}
  end

  When %{I select "#{address.state.name}" from "order_#{str_addr}_attributes_state_id"}
end

When /^(?:|I )add a product with (.*?)? to cart$/ do |captured_fields|
  fields = {'name' => "RoR Mug", 'count_on_hand' => '10', 'price' => "14.99"}
  captured_fields.split(/,\s+/).each do |field|
    (name, value) = field.split(/:\s*/, 2)
    fields[name] = value.delete('"')
  end

  price = fields.delete('price')

  if Product.search.master_price_equals(price).count(:conditions => fields) == 0
    Factory(:product, fields.merge('price' => price,  :sku => 'ABC',
                                                      :available_on => (Time.now - 100.days)))
  end

  When %{I go to the products page}
  Then %{I should see "#{fields['name']}" within "ul.product-listing"}
  When %{I follow "#{fields['name']}"}
  Then %{I should see "#{fields['name']}" within "h1"}
  And  %{I should see "$#{price}" within "span.price"}
  When %{I press "Add To Cart"}
end

When /^I choose "(.*?)" as shipping method$/ do |shipping_method|
  shipping_method = "order_shipping_method_id_#{ShippingMethod.find_by_name(shipping_method).id}"
  When %{I choose "#{shipping_method}"}
  And %{press "Save and Continue"}
  Then %{I should see "Payment Information"}
end

When /^I choose "(.*?)" as shipping method and "(.*?)" as payment method(?: and set coupon code to "(.*?)")?$/ do |shipping_method, payment_method, coupon_code|
  When %{I choose "#{shipping_method}" as shipping method}

  payment_method = "order_payments_attributes__payment_method_id_#{PaymentMethod.find(:last, :conditions => {:name => payment_method}).id}"

  When %{I choose "#{payment_method}"}

  if coupon_code
    When %{I fill in "order_coupon_code" with "#{coupon_code}"}
  end

  And %{press "Save and Continue"}
end

Then /^cart should be empty$/ do
  Then %{I should not see "Cart: ("}
end

When /^(?:|I )enter valid credit card details$/ do
  And %{I fill in "card_number" with "4111111111111111"}
  And %{I fill in "card_code" with "123"}
  And %{press "Save and Continue"}
end
