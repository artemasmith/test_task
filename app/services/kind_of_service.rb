# frozen_string_literal: true

module KindOfService
  extend ActiveSupport::Concern
  include LogsHelper

  class ServiceError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end

  class Calls
    def initialize(user, actor, klass)
      @actor = actor
      @user = user
      @klass = klass
    end

    def call(*args, **kwargs)
      @klass.call(@user, @actor, *args, **kwargs)
    end
  end

  DEFAULT_ERROR_MESSAGE = 'Error occurred.'

  ERRORS_ARRAY_KEY_REGEXP = /(?<array_name>.*)\[(?<index>.*)\]/

  class_methods do
    delegate :t, to: I18n

    def call(*args, **kwargs)
      instance = new(*args, **kwargs)
      instance.args = args
      instance.log_level = @log_level || :debug
      instance.verbose_params = @verbose_params || false
      instance.call
    end

    def calls(user, actor)
      return unless block_given?

      result = []

      instance = Calls.new(user, actor, self)
      result << yield(instance)
      result
    end

    # Set log level for service
    # +level+
    #   Integer or Logger::Severity constant  (DEBUG, INFO, WARN, ERROR, etc)
    #
    def log_level(level)
      @log_level = level
    end

    def verbose_params
      @verbose_params = true
    end
  end

  delegate :t, to: I18n

  attr_accessor :args, :log_level, :verbose_params

  def call
    with_logs_and_timings do
      result = ActiveRecord::Base.logger.silence(@log_level) { perform }
      @result = result.is_a?(KindOfService::Result) ? result : KindOfService::Result.new(result)
      log_failure(@result) if @result.failed?
    end

    @result
  end

  def error(data = nil, errors = [DEFAULT_ERROR_MESSAGE], error_code = nil)
    if Rails.env.development? || Rails.env.test?
      log(WARN) { "Warning! Deprecated method #error in service #{self.class.name}, use #failure instead" }
    end

    { data:, errors: extract_nested_error_messages(errors), error_code: }
  end

  def failure(errors, data = nil)
    { data:, errors: }
  end

  def success(data = nil)
    { data:, errors: [] }
  end

  def validation_error(errors)
    validation_errors =
      if errors.is_a?(Array)
        errors.map { |e| extract_nested_error_messages(e) }
      else
        extract_nested_error_messages(errors)
      end

    res = general_error('Validation error', :validation_error)
    res.merge(validation: validation_errors)
  end

  def general_error(message, reason)
    { general: {
      message:,
      reason:
    } }
  end

  def after_commit(connection: ActiveRecord::Base.connection, &block)
    connection.add_transaction_record(AfterCommitWrap.new(connection, &block))
  end

  def transaction(requires_new: true, &block)
    ActiveRecord::Base.transaction(requires_new:, &block)
  end

  private

  def log_failure(result)
    log(ERROR) { "Error occurred in service [#{self.class}])" }
    log(ERROR) { "\tData: #{filtered_args(result.data, verbose_params)}" }
    log(ERROR) { "\tErrors: #{filtered_args(result.errors, verbose_params)}" }
  end

  def with_logs_and_timings
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    log(INFO) { "Calling service [#{self.class}] with parameters: #{filtered_args(args, verbose_params)}" }
    yield
  rescue StandardError => e
    @unhandled_exception = e
  ensure
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    log(INFO) { "Processed service [#{self.class}] in #{(end_time - start_time).round(3)} s" }
    raise @unhandled_exception if @unhandled_exception
  end

  def extract_nested_error_messages(errors)
    return errors unless errors.is_a?(ActiveModel::Errors)

    error_messages = errors.messages.with_indifferent_access
    error_messages.reduce({}) do |messages, (attribute, attribute_errors)|
      message_path = attribute.split('.')
      assign_by_path(message_path, attribute_errors, messages)
    end
  end

  def assign_by_path(path, value, hash)
    root_key = path.first

    return hash.deep_merge(root_key => value) if path.length == 1

    if array_item?(root_key)
      array_name = array_name(root_key)
      index = array_index(root_key)

      value = assign_by_path(path[1..], value, get_array_item(array_name, index, hash))
      array = merge_array_item(array_name, index, value, hash)
      hash.merge(array_name => array)
    else
      value = assign_by_path(path[1..], value, hash[root_key] || {})
      hash.deep_merge(path.first => value)
    end
  end

  def merge_array_item(array_name, index, value, hash)
    array = hash[array_name] || []
    array = array.dup
    array[index] = get_array_item(array_name, index, hash).deep_merge(value)
    array
  end

  def get_array_item(array_name, index, hash)
    array = hash[array_name] || []
    array[index] || {}
  end

  def array_item?(key)
    ERRORS_ARRAY_KEY_REGEXP.match?(key)
  end

  def array_name(key)
    match = ERRORS_ARRAY_KEY_REGEXP.match(key)
    match[:array_name]
  end

  def array_index(key)
    match = ERRORS_ARRAY_KEY_REGEXP.match(key)
    match[:index].to_i
  end

  def system_actor
    @system_actor ||= System.new
  end

  def system_user
    system_actor.user
  end
end
