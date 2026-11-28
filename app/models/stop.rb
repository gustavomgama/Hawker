class Stop < ApplicationRecord
  class Unavailable < StandardError; end
  class InvalidTransition < StandardError; end

  STATUSES = %w[requested accepted arrived fulfilled declined expired voided dropped].freeze
  ON_ROUTE = %w[accepted arrived].freeze

  belongs_to :customer

  validates :address, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :requested, -> { where(status: "requested") }
  scope :on_route, -> { where(status: ON_ROUTE).order(:sequence) }

  def self.request!(customer_name:, address:, items: nil, customer_phone: nil)
    raise Unavailable, "the hawker is not working" unless HawkerProfile.instance.working?

    transaction do
      create!(
        customer: find_or_build_customer(customer_name, customer_phone),
        address: address,
        items: items
      )
    end
  end

  def self.find_or_build_customer(name, phone)
    customer = phone.present? ? Customer.find_or_initialize_by(phone: phone) : Customer.new
    customer.name = name
    customer.save! if customer.new_record? || customer.changed?
    customer
  end
  private_class_method :find_or_build_customer

  def accept!
    ensure_status!("requested")

    transaction do
      self.status = "accepted"
      self.sequence = (Stop.on_route.maximum(:sequence) || 0) + 1
      self.accepted_at = Time.current
      save!
    end
  end

  def decline!
    ensure_status!("requested")
    update!(status: "declined")
  end

  def arrive!
    ensure_status!("accepted")
    update!(status: "arrived", arrived_at: Time.current)
  end

  def fulfill!
    ensure_status!("arrived")
    update!(status: "fulfilled")
  end

  def void!
    ensure_status!("requested")
    update!(status: "voided")
  end

  def drop!
    ensure_status!(*ON_ROUTE)
    update!(status: "dropped", sequence: nil)
  end

  private

  def ensure_status!(*allowed)
    return if allowed.include?(status)

    raise InvalidTransition, "cannot move a #{status} stop to this state"
  end
end
