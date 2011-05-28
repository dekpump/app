class Supplier < ActiveRecord::Base


  before_create :generate_supplier_number


  # use deleted? rather than checking the attribute directly. this
  # allows extensions to override deleted? if they want to provide
  # their own definition.
  def deleted?
    !!deleted_at
  end

  def generate_supplier_number
    record = true
    while record
      random = "S#{Array.new(9){rand(9)}.join}"
      record = self.class.find(:first, :conditions => ["code = ?", random])
    end
    self.code = random if self.code.blank?
    self.code
  end
end