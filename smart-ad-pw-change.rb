#!/usr/bin/ruby

# the hostname of a Windows Domain Controller running LDAP
LDAP_AUTH_SERVER = 'hostname.com'

# the name of your Windows domain.
WINDOWS_DOMAIN = 'your_domain_name'

# number of seconds to sleep between password changes.
# if you have problems with the script "getting ahead of AD" you
# should probably increase this. Less than 3 seconds is probably
# not a good idea.
sleep_time = 3

require 'etc'
begin
  require 'net/ldap'
rescue LoadError
  begin
    require 'rubygems'
    require 'net/ldap'
  rescue LoadError
    puts 'You need rubygems & ruby-net-ldap gem'
  end
end

def ldap_bind(login,pass)
  ldap = Net::LDAP.new
  ldap.port = 636 #must be 636 for SSL
  ldap.host = LDAP_AUTH_SERVER
  ldap.encryption :simple_tls
  ldap.auth "#{login}@#{WINDOWS_DOMAIN}", pass
  if ldap.bind
    return ldap
  else
    return false
  end
end

def random_password( len )
  upper_chars = ('a'..'z').to_a
  lower_chars = ('A'..'Z').to_a
  numbers = ('0'..'9').to_a
  punctuation = ['!','?','@']
  sets_of_chars = [upper_chars, lower_chars, numbers, punctuation]
  categories_to_use = [0,1,2,3]
  newpass = String.new
  # first pick one from each category, in random category order
  until categories_to_use.empty?
    cat = categories_to_use[rand(categories_to_use.size)]
    categories_to_use = categories_to_use - Array(cat)
    newpass << sets_of_chars[cat][rand(sets_of_chars[cat].size)]
  end
  # then whatever
  until newpass.length == len
    newpass << sets_of_chars[r=rand(sets_of_chars.size)][rand(sets_of_chars[r].size)]
  end
  return newpass
end

def ldap_change_password(login, oldpw, newpw)
  ldap = ldap_bind(login,oldpw)
  return false unless ldap.bind
  encoded_newpw = ''
  newpw = "\"" + newpw + "\""
  newpw.length.times { |i|
  	encoded_newpw += "#{newpw[i..i]}\000"
  } # encoding password in format Microsoft wants

  encoded_oldpw = ''
  oldpw = "\"" + oldpw + "\""
  oldpw.length.times { |i|
  	encoded_oldpw += "#{oldpw[i..i]}\000"
  } # encoding password in format Microsoft wants

  # finding location of the user, as the change password operation requires the full path to the user
  dn = ldap.search(:filter => Net::LDAP::Filter.eq('samaccountname',login), :base => 'dc=yellowpages,dc=local', :return_result => true).first.dn

  # Microsoft requires that in one operation, you delete the old password then add the new one.
  ops = [[:delete, :unicodePwd, encoded_oldpw],[:add, :unicodePwd, encoded_newpw]] 

  ldap.modify :dn => dn, :operations => ops

  if ldap.get_operation_result.code == 0
    return true
  elsif ldap.get_operation_result.code == 19
    warn "LDAP failure code 19 attempting to change password (probably means your password is too weak)."
    return false
  else
    warn "Error changing LDAP password. Result code: #{ldap.get_operation_result.code}. Message: #{ldap.get_operation_result.message}"
    return false
  end
end


puts 'Important: if this script barfs in the middle of the random password changes,'
puts 'make sure to take note of your current random password so you do not get'
puts 'locked out.'
puts ''

loggedin = Etc.getlogin
print "username [#{loggedin}]: "
login = STDIN.gets.chomp
login = loggedin if login.length == 0
begin
  system 'stty -echo'
  print 'current AD password: '
  password = STDIN.gets.chomp
  puts ''
  print 'enter new password or hit enter to keep it the same: '
  newpassword = STDIN.gets.chomp
  newpassword = password if newpassword.length == 0
ensure
  system 'stty echo; echo ""'
end

unless ldap_bind(login,password)
  warn "Failed to authenticate with current password."
  exit
end

# change to random password
future_random_password = random_password(8)
if ldap_change_password(login,password,future_random_password)
  puts "changed password to #{future_random_password}"
  current_random_password = future_random_password
  # now cycle 8 random passwords to clear out history
  8.times do
    future_random_password = random_password(8)
    puts "sleeping #{sleep_time} seconds so we do not get ahead of AD."
    sleep sleep_time
    if ldap_change_password(login,current_random_password,future_random_password)
      puts "changed password to #{future_random_password}"
      current_random_password = future_random_password
    else
      warn "Error changing password!"
      exit
    end
  end
else
  warn "Error changing password!"
  exit
end

# finally change to desired password

puts "Now a final sleep of 3 seconds..."
sleep 3
if ldap_change_password(login,current_random_password,newpassword)
  puts "And now your desired password is set. All done!"
end
