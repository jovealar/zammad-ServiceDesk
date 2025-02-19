# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Setting < ApplicationModel
  store         :options
  store         :state_current
  store         :state_initial
  store         :preferences
  before_validation :state_check
  before_create :set_initial
  after_create  :reset_change_id
  after_update  :reset_change_id
  after_commit  :reset_cache, :broadcast_frontend, :check_refresh

  validates_with Setting::Validator

  attr_accessor :state

  @@current         = {} # rubocop:disable Style/ClassVars
  @@raw             = {} # rubocop:disable Style/ClassVars
  @@change_id       = nil # rubocop:disable Style/ClassVars
  @@last_changed_at = nil # rubocop:disable Style/ClassVars
  @@lookup_at       = nil # rubocop:disable Style/ClassVars
  @@lookup_timeout  = if ENV['ZAMMAD_SETTING_TTL'] # rubocop:disable Style/ClassVars
                        ENV['ZAMMAD_SETTING_TTL'].to_i.seconds
                      else
                        15.seconds
                      end

=begin

set config setting

  Setting.set('some_config_name', some_value)

=end

  def self.set(name, value)
    setting = Setting.find_by(name: name)
    if !setting
      raise "Can't find config setting '#{name}'"
    end

    setting.state_current = { value: value }
    setting.save!
    logger.info "Setting.set('#{name}', #{value.inspect})"
    true
  end

=begin

get config setting

  value = Setting.get('some_config_name')

=end

  def self.get(name)
    load
    @@current[name].deep_dup # prevents accidental modification of settings in console
  end

=begin

reset config setting to default

  Setting.reset('some_config_name')

  Setting.reset('some_config_name', force) # true|false - force it false per default

=end

  def self.reset(name, force = false)
    setting = Setting.find_by(name: name)
    if !setting
      raise "Can't find config setting '#{name}'"
    end
    return true if !force && setting.state_current == setting.state_initial

    setting.state_current = setting.state_initial
    setting.save!
    logger.info "Setting.reset('#{name}', #{setting.state_current.inspect})"
    true
  end

=begin

reload config settings

  Setting.reload

=end

  def self.reload
    @@last_changed_at = nil # rubocop:disable Style/ClassVars
    load(true)
  end

  private

  # load values and cache them
  def self.load(force = false)

    # check if config is already generated
    return false if !force && @@current.present? && cache_valid?

    # read all or only changed since last read
    latest = Setting.reorder(updated_at: :desc).limit(1).pluck(:updated_at)
    settings = if @@last_changed_at && @@current.present?
                 Setting.where('updated_at >= ?', @@last_changed_at).reorder(:id).pluck(:name, :state_current)
               else
                 Setting.reorder(:id).pluck(:name, :state_current)
               end

    if latest && latest[0]
      @@last_changed_at = [Time.current, latest[0]].min # rubocop:disable Style/ClassVars
    end

    if settings.present?
      settings.each do |setting|
        @@raw[setting[0]] = setting[1]['value']
      end
      @@raw.each do |key, value|
        if value.class != String
          @@current[key] = value
          next
        end
        @@current[key] = value.gsub(%r{\#\{config\.(.+?)\}}) do
          @@raw[$1].to_s
        end
      end
    end

    @@change_id = Rails.cache.read('Setting::ChangeId') # rubocop:disable Style/ClassVars
    @@lookup_at = Time.now.to_i # rubocop:disable Style/ClassVars
    true
  end
  private_class_method :load

  # set initial value in state_initial
  def set_initial
    self.state_initial = state_current
  end

  def reset_change_id
    change_id = SecureRandom.uuid
    logger.debug { "Setting.reset_change_id: set new cache, #{change_id}" }
    Rails.cache.write('Setting::ChangeId', change_id, { expires_in: 24.hours })
    @@lookup_at = nil # rubocop:disable Style/ClassVars
    true
  end

  def reset_cache
    return if preferences[:cache].blank?

    Array(preferences[:cache]).each do |key|
      Rails.cache.delete(key)
    end
  end

  # check if cache is still valid
  def self.cache_valid?
    if @@lookup_at && @@lookup_at > Time.now.to_i - @@lookup_timeout
      # logger.debug "Setting.cache_valid?: cache_id has been set within last #{@@lookup_timeout} seconds"
      return true
    end

    change_id = Rails.cache.read('Setting::ChangeId')
    if @@change_id && change_id == @@change_id
      @@lookup_at = Time.now.to_i # rubocop:disable Style/ClassVars
      # logger.debug "Setting.cache_valid?: cache still valid, #{@@change_id}/#{change_id}"
      return true
    end
    # logger.debug "Setting.cache_valid?: cache has changed, #{@@change_id}/#{change_id}"
    false
  end
  private_class_method :cache_valid?

  # convert state into hash to be able to store it as store
  def state_check
    return if state.nil? # allow false value
    return if state.try(:key?, :value)

    self.state_current = { value: state }
  end

  # Notify clients about config changes.
  def broadcast_frontend
    return if !frontend

    # Some setting values use interpolation to reference other settings.
    # This is applied in `Setting.get`, thus direct reading of the value should be avoided.
    value = self.class.get(name)

    Sessions.broadcast(
      {
        event: 'config_update',
        data:  { name: name, value: value }
      },
      preferences[:authentication] ? 'authenticated' : 'public'
    )

    Gql::Subscriptions::ConfigUpdates.trigger(self)
  end

  # NB: Force users to reload on SAML credentials config changes
  #   This is needed because the setting is not frontend related,
  #   so we can't rely on 'config_update_local' mechanism to kick in
  # https://github.com/zammad/zammad/issues/4263
  def check_refresh
    return if ['auth_saml_credentials'].exclude?(name)

    AppVersion.set(true, AppVersion::MSG_CONFIG_CHANGED)
  end
end
