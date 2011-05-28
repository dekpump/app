class Purchase < ActiveRecord::Base

  attr_accessible :purchase_line_items





  has_many :purchase_line_items
  #has_one :line_item, :through => :purchase_line_item

  accepts_nested_attributes_for :purchase_line_items


  before_create :generate_purchase_number

  scope :by_number, lambda {|number| where("purchases.number = ?", number)}

  make_permalink :field => :number


  # purchase state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => 'waiting', :use_transactions => false do

    event :next do
      transition :from => 'waiting',   :to => 'complete'
    end

    event :cancel do
      transition :to => 'canceled', :if => :allow_cancel?
    end

    after_transition :to => 'complete', :do => :finalize!
    after_transition :to => 'canceled', :do => :after_cancel

  end

  class_attribute :update_hooks
  self.update_hooks = Set.new

  # Use this method in other gems that wish to register their own custom logic that should be called after Order#updat
  def self.register_update_hook(hook)
    self.update_hooks.add(hook)
  end

  def to_param
    number.to_s.parameterize.upcase
  end

  def completed?
    !! completed_at
  end


  # FIXME refactor this method and implement validation using validates_* utilities
  def generate_purchase_number
    record = true
    while record
      random = "P#{Array.new(9){rand(9)}.join}"
      record = self.class.find(:first, :conditions => ["number = ?", random])
    end
    self.number = random if self.number.blank?
    self.number
  end

end