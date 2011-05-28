class Admin::PurchasesController < Admin::BaseController

  resource_controller



  def new
    @purchase = @object = Purchase.create
  end



  private

  def object
    @object ||= Purchase.find_by_number(params[:id]) if params[:id]
    return @object || current_purchase
  end

  def collection
    params[:search] ||= {}
    @show_only_completed = params[:search][:completed_at_is_not_null].present?
    params[:search][:meta_sort] ||= @show_only_completed ? 'completed_at.desc': 'created_at.desc'

    @search = Purchase.metasearch(params[:search])

    if !params[:search][:created_at_greater_than].blank?

    end

    #-------------
    if @show_only_completed
      params[:search][:completed_at_greater_than] = params[:search].delete(:created_at_greater_than)
      params[:search][:completed_at_less_than] = params[:search].delete(:created_at_less_than)
    end

    @collection = Purchase.metasearch(params[:search]).paginate(
        # include odering
        :per_page => Spree::Config[:purchases_per_page],
        :page     => params[:page]
    )

  end

end  