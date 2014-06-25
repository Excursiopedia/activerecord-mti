# ActiveRecord MTI (Multiple Tables Inheritance)

This gem allows you to make models which attributes are distributed by two tables.

## Installation

Add to your Gemfile:

```gem 'activerecord-mti'```

## Usage

Consider the following DB schema:

```ruby
create_table :subjects do |t|
  t.string :name
end

create_table :roles do |t|
  t.integer :subject_id
  # MTI fields
  t.integer :role_id
  t.integer :role_type
end

create_table :employees do |t|
  t.string :appointment
end

create_table :clients do |t|
  t.string :address
end
```

and corresponding models: 

```ruby
class Subject < ActiveRecord::Base
  has_many :roles
end

class Role < ActiveRecord::Base
  mti_base  
  belongs_to :subject
end

class Employee < ActiveRecord::Base
  mti_implementation_of :role
end

class Client < ActiveRecord::Base
  mti_implementation_of :role
end
```

Have fun with roles as base and implementation objects at the same time:

```ruby
Subject.first.roles # => [#<Employee …>, #<Client …>]
Employee.first.subject # => #<User …>
Role.where(role_type: Client).first.address # => String
Client.first.role # => #<Role …>
Client.first.role_id == Client.first.role.id # => true
Client.create!(:address => 'somewhere').role # => #<Role …>
```

## Testing

```bundle exec rspec spec```
