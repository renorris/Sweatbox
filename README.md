# Sweatbox
An FSD server written in Ruby designed to mimic a simple VATSIM sweatbox.
[FSD Protocol Docs](https://fsd-doc.norrisng.ca/site/index.html)

## Installation and Dependencies

- \> Ruby 2.5
- MySQL server

MySQL:
- Create sweatbox DB user: `CREATE USER 'sweatbox'@'localhost' IDENTIFIED BY 'sweatbox';`
- Create database: `CREATE DATABASE SWEATBOX;`
- Give user permissions: `GRANT ALL PRIVILEGES ON SWEATBOX.* TO 'sweatbox'@'localhost'`

Import database template: `mysql SWEATBOX < sweatbox_database_template.db`

Dependencies:

- MySQL gem dependencies: (`apt-get install mysql-client libmysqlclient-dev bundler`)
- mysql2 (`gem install mysql2`)
- geokit (`gem install geokit`)
- ansicolor (`gem install term-ansicolor`)

## Usage

Run `cert_tool.rb` to set up an account to login to the sweatbox.

To start the FSD server, run `fsdserver.rb`

The server will run on all network interfaces by default on port 6809.

Once started, you can connect with a client like VRC.

See wiki for more usage information within the sweatbox.

## Features

- User accounts
- Modify flightplans and sync across all clients
- Move aircraft
- Instructor commands to manipulate aircraft
- Change position update interval (1sec-5sec)
- See other controllers online in Controllers and Chat windows (VRC)
- NOAA metars for ATC client
- Broadcast messages
