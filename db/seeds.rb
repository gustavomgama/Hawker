driver = User.create!(
  email_address: 'd@d.com',
  password: 'd@d.com',
  driver: true
)

puts "Created driver user: #{driver.email_address}"
puts "Password: d@d.com"
