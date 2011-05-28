class TaxonsController < Spree::BaseController
  #prepend_before_filter :reject_unknown_object, :only => [:show]
  before_filter :load_data, :only => :show
  resource_controller
  actions :show
  helper :products
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404

  private
  def load_data
    @taxon ||= object
    render_404 and return if @taxon.nil?
    params[:taxon] = @taxon.id
    @searcher = Spree::Config.searcher_class.new(params)
    @products = @searcher.retrieve_products
  end

  def object
    @object ||= end_of_association_chain.find_by_permalink(params[:id])
  end

  def accurate_title
    @taxon ? @taxon.name : nil
  end
end
