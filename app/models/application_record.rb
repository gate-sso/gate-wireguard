# frozen_string_literal: true

# first active record base class
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
