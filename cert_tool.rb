#!/usr/bin/env ruby
  
require "mysql2"
require 'io/console'
require 'term/ansicolor'
require 'securerandom'

#+--------------+-------------+------+-----+---------+-------+
#| Field        | Type        | Null | Key | Default | Extra |
#+--------------+-------------+------+-----+---------+-------+
#| cert_id      | int(10)     | YES  |     | NULL    |       |
#| password     | varchar(20) | YES  |     | NULL    |       |
#| pilot_rating | int(2)      | YES  |     | NULL    |       |
#| atc_rating   | int(2)      | YES  |     | NULL    |       |
#| full_name    | varchar(30) | YES  |     | NULL    |       |
#| uuid         | varchar(20) | YES  |     | NULL    |       |
#+--------------+-------------+------+-----+---------+-------+

ATC_RANKS = {
  1 => "Observer",
  2 => "Student 1",
  3 => "Student 2",
  4 => "Student 3",
  5 => "Controller 1",
  6 => "Controller 2",
  7 => "Controller 3",
  8 => "Instructor 1",
  9 => "Instructor 2",
  10 => "Instructor 3",
  11 => "Supervisor",
  12 => "Administrator"}

SQL_CLIENT = Mysql2::Client.new(:host => "localhost", :username => "sweatbox", :password => "sweatbox", :database => 'SWEATBOX')
include Term::ANSIColor

def run
  while true

    print green(bold("CERT TOOL")) + "$ "
    unparsedcommand = gets.chomp
    command = unparsedcommand.split(" ")

    if command[0] == 'help'
      puts "Current commands: adduser | removeuser <cert ID to delete> | allusers | lookupcertid | lookuppassword | lookupfullname | modify <cert ID>"
    elsif command[0] == "adduser"
      puts ATC_RANKS
      puts "ATC Rating for this account:"
      atc_rating = gets.chomp
      puts "full name for this account"
      full_name = gets.chomp
      cert_id = rand(100000..999999)
      result = SQL_CLIENT.query("SELECT * FROM certs;")
      result.each do |cert|
        while cert['cert_id'] == cert_id
          cert_id = rand(100000..999999)
        end
      end
      puts "Enter password for account:"
      password = gets.chomp
      puts ""
      puts "Creating user account with details: Certificate ID: #{cert_id} | ATC Rating: #{ATC_RANKS[atc_rating.to_i]} | Full Name: #{full_name}"
      result = SQL_CLIENT.query("INSERT INTO certs (cert_id, password, atc_rating, full_name) VALUES ('#{cert_id}', '#{password}', '#{atc_rating}', '#{full_name}');")
    elsif command[0] == 'removeuser'
      cert_to_delete = command[1]
      if cert_to_delete == nil
        puts "invalid entry"
      else
        result = SQL_CLIENT.query("SELECT * FROM certs WHERE cert_id='#{cert_to_delete}';")
        result_to_compare = []
        result.each do |cert|
          result_to_compare.push cert
        end
        if result_to_compare == []
          puts "couldn't find an account for #{cert_to_delete} in the database"
        else
          print red(bold("Delete account for #{cert_to_delete}?")), " y/n "
          choice = gets.chomp
          if choice == 'y'
            SQL_CLIENT.query("DELETE FROM certs WHERE cert_id='#{cert_to_delete}';")
            puts "Deleted account #{cert_to_delete}"
          else
            puts "Did " + bold("NOT") + " delete #{cert_to_delete}"
          end
        end
      end
    elsif command[0] == 'lookuppassword'
      lookupsearch = unparsedcommand.split(' ', 2)[1]
      result = SQL_CLIENT.query("SELECT * FROM certs WHERE password LIKE '%#{lookupsearch}%';")
      certs = []
      result.each do |cert|
        certs.push cert
      end
      if certs == []
        puts "Nothing found for '#{lookupsearch}'"
      else
        certs.each do |cert|
          puts "ACCOUNT: #{cert['cert_id']}, Full Name: #{cert['full_name']}, ATC Rating: #{ATC_RANKS[cert['atc_rating'].to_i]}, Password: #{cert['password']}"
          puts ""
        end
      end
    elsif command[0] == 'lookupcertid'
      lookupsearch = unparsedcommand.split(' ', 2)[1]
      result = SQL_CLIENT.query("SELECT * FROM certs WHERE cert_id LIKE '%#{lookupsearch}%';")
      certs = []
      result.each do |cert|
        certs.push cert
      end
      if certs == []
        puts "Nothing found for '#{lookupsearch}'"
      else
        certs.each do |cert|
          puts "ACCOUNT: #{cert['cert_id']}, Full Name: #{cert['full_name']}, ATC Rating: #{ATC_RANKS[cert['atc_rating'].to_i]}, Password: #{cert['password']}"
          puts ""
        end
      end
    elsif command[0] == 'lookupfullname'
      lookupsearch = unparsedcommand.split(' ', 2)[1]
      result = SQL_CLIENT.query("SELECT * FROM certs WHERE full_name LIKE '%#{lookupsearch}%';")
      certs = []
      result.each do |cert|
        certs.push cert
      end
      if certs == []
        puts "Nothing found for '#{lookupsearch}'"
      else
        certs.each do |cert|
          puts "ACCOUNT: #{cert['cert_id']}, Full Name: #{cert['full_name']}, ATC Rating: #{ATC_RANKS[cert['atc_rating'].to_i]}, Password: #{cert['password']}"
          puts ""
        end
      end
    elsif command[0] == 'allusers'
      result = SQL_CLIENT.query("SELECT * FROM certs;")
      certs = []
      result.each do |cert|
        certs.push cert
      end
      certs.each do |cert|
        puts "ACCOUNT: #{cert['cert_id']}, Full Name: #{cert['full_name']}, ATC Rating: #{ATC_RANKS[cert['atc_rating'].to_i]}, Password: #{cert['password']}"
        puts ""
      end
    elsif command[0] == 'modify'
      accountid = command[1]
      if accountid == nil 
        puts "Invalid command"
        run
      end
      puts "what to modify? (n)ame, (p)assword, (a)tc rating, (c)ert ID"
      choice = gets.chomp.downcase
      if choice == 'n'
        puts "Change name to what?"
        rename = gets.chomp
        SQL_CLIENT.query("UPDATE certs SET full_name='#{rename}' WHERE cert_id='#{accountid}';")
      elsif choice == 'p'
        puts "Change password to what?"
        password = gets.chomp
        SQL_CLIENT.query("UPDATE certs SET password='#{password}' WHERE cert_id='#{accountid}';")
      elsif choice == 'a'
        puts ATC_RANKS
        puts "What ATC rank to change to?"
        atcrank = gets.chomp
        SQL_CLIENT.query("UPDATE certs SET atc_rating='#{atcrank}' WHERE cert_id='#{accountid}';")
      elsif choice == 'c'
        puts "what to change cert_id to ?"
        certid = gets.chomp
        result = SQL_CLIENT.query("SELECT * FROM certs;")
        certs = []
        result.each do |cert|
          certs.push cert
        end
        output = false
        certs.each do |cert|
          if cert['cert_id'] == certid.to_i
            output = true
          end
        end
        if !output
          SQL_CLIENT.query("UPDATE certs SET cert_id='#{certid}' WHERE cert_id='#{accountid}';")
        else
          puts red(bold("WARNING:")) + " another account with the same cert ID (#{certid}) already exists!"
          print "Continue? y/n "
          choice = gets.chomp.downcase
          if choice == 'y'
            SQL_CLIENT.query("UPDATE certs SET cert_id='#{certid}' WHERE cert_id='#{accountid}';")
          else
            puts "Did NOT change cert_id"
          end
        end
      else
        puts "invalid command"
      end
    else
      puts "Invalid command. Run 'help' for help."
    end
  end
end
run
