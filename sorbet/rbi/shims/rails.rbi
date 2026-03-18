# typed: true
# Minimal shims for Rails framework classes that Sorbet needs to resolve.
# These will be replaced by tapioca-generated RBIs when gems are fully installed.

module ActiveRecord
  class Base
    extend T::Sig
  end

  class RecordNotFound < StandardError; end
  class RecordInvalid < StandardError
    sig { params(record: T.untyped).void }
    def initialize(record = nil); end
  end

  class Migration
    def self.[](version); end

    class Current < Migration; end
  end

  module Associations
    module ClassMethods; end
  end

  class Schema
    def self.[](version); end
  end
end

module ActionController
  class Base; end
  class API; end
end

module ActionCable
  module Connection
    class Base; end
  end
  module Channel
    class Base; end
  end
end

module ActiveSupport
  module Concern; end
end

module ActionMailer
  class Base; end
end

class ActiveJob
  class Base; end
end

module Rails
  sig { returns(T.untyped) }
  def self.root; end

  sig { returns(T.untyped) }
  def self.logger; end

  sig { returns(T.untyped) }
  def self.env; end

  module VERSION
    STRING = T.let('8.0.2', String)
  end
end

# ActiveRecord class methods used in models
class ActiveRecord::Base
  extend T::Sig

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.find(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.find_by(**args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def self.exists?(*args); end

  sig { returns(T.untyped) }
  def self.all; end

  sig { returns(T.untyped) }
  def self.first; end

  sig { returns(Integer) }
  def self.count; end

  sig { params(args: T.untyped).returns(T::Array[T.untyped]) }
  def self.pluck(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.where(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.order(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.includes(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.create!(**args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.find_by!(**args); end

  sig { params(conditions: T.untyped).returns(T.untyped) }
  def self.destroy_all(conditions = nil); end

  sig { params(name: T.untyped, body: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.scope(name = nil, body = nil, &blk); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.validates(*args); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.validate(*args, &blk); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.belongs_to(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.has_one(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.has_many(*args); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.before_action(*args, &blk); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.after_action(*args, &blk); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.before_destroy(*args, &blk); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.update_all(*args); end

  sig { void }
  def self.primary_abstract_class; end

  sig { params(block: T.untyped).returns(T.untyped) }
  def self.transaction(&block); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def save!(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def update!(**args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def update(**args); end

  sig { returns(T::Boolean) }
  def destroy!; end

  sig { returns(T.untyped) }
  def errors; end

  sig { returns(T.untyped) }
  def attributes; end

  sig { returns(Integer) }
  def id; end

  sig { returns(T.nilable(Time)) }
  def created_at; end
end

# ActionController shims
class ActionController::Base
  extend T::Sig

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.before_action(*args, &blk); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def self.after_action(*args, &blk); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.layout(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.include(*args); end

  sig { returns(T.untyped) }
  def params; end

  sig { returns(T.untyped) }
  def session; end

  sig { returns(T.untyped) }
  def request; end

  sig { returns(T.untyped) }
  def response; end

  sig { params(args: T.untyped).returns(T.untyped) }
  def redirect_to(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def render(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def send_data(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def head(*args); end

  sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
  def respond_to(*args, &blk); end
end

class ActionController::API
  extend T::Sig

  sig { params(args: T.untyped).returns(T.untyped) }
  def self.include(*args); end

  sig { returns(T.untyped) }
  def params; end

  sig { params(args: T.untyped).returns(T.untyped) }
  def render(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def head(*args); end
end

# Redis constant used in DnsRecord
REDIS = T.let(T.unsafe(nil), T.untyped)

# RQRCode
module RQRCode
  class QRCode
    sig { params(data: String).void }
    def initialize(data); end

    sig { params(args: T.untyped).returns(String) }
    def as_svg(**args); end
  end
end
