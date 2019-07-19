# Sweatbox
An FSD server written in Ruby designed to mimic a simple VATSIM sweatbox.

## Installation and Dependencies

- Only tested on Ubuntu 16.04 or 18.04
- Ruby 2.5 or above (`apt-get install ruby`)
- Mysql server (`apt-get install mysql-server`)

On the mysql console:
- Create sweatbox DB user: `CREATE USER 'sweatbox'@'localhost' IDENTIFIED BY 'sweatbox';`
- Create database: `CREATE DATABASE SWEATBOX;`
- Give user permissions: `GRANT ALL PRIVILEGES ON SWEATBOX.* TO 'sweatbox'@'localhost'`

Import database template into mysql: `mysql SWEATBOX < sweatbox_database_template.db`

Ruby Dependencies:

- Mysql2 gem dependencies: (`apt-get install mysql-client libmysqlclient-dev bundler`)
- mysql2 gem (`gem install mysql2`)
- geokit gem (`gem install geokit`)
- ansicolor gem (`gem install term-ansicolor`)

## Usage

Run `cert_tool.rb` to set up an account to login to the sweatbox.

To start the FSD server, run `fsdserver.rb`

The server will run on all network interfaces by default on port 6809.

Once started, you can connect with a client like VRC.

See wiki for more usage information within the sweatbox.
