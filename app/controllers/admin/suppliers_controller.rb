class Admin::SuppliersController < Admin::BaseController
  resource_controller
  before_filter :check_json_authenticity, :only => :index

  index.response do |wants|
    wants.html { render :action => :index }
    wants.json { render :json => json_data }
  end

  new_action.response do |wants|
    wants.html {render :action => :new, :layout => !request.xhr?}
  end

  update.before :update_before

  create.response do |wants|
    # go to edit form after creating as new supplier
    wants.html {redirect_to edit_admin_supplier_url(@supplier) }
  end

  update.response do |wants|
    # override the default redirect behavior of r_c
    # need to reload Supplier in case name / permalink has changed
    wants.html {redirect_to edit_admin_supplier_url(@supplier) }
  end

  # override the destory method to set deleted_at value
  # instead of actually deleting the product.
  def destroy
    @supplier = Supplier.find_by_param(params[:id])
    @supplier.deleted_at = Time.now()

    #@supplier.variants.each do |v|
    #  v.deleted_at = Time.now()
    #  v.save
    #end

    if @supplier.save
      flash.notice = I18n.t("notice_messages.supplier_deleted")
    else
      flash.notice = I18n.t("notice_messages.supplier_not_deleted")
    end

    respond_to do |format|
      format.html { redirect_to collection_url }
      format.js  { render_js_for_destroy }
    end
  end


  # Allow different formats of json data to suit different ajax calls
  def json_data
    json_format = params[:json_format] or 'default'
    case json_format
    when 'basic'
      collection.map {|p| {'id' => p.id, 'name' => p.name}}.to_json
    else
     # collection.to_json(:include => {:variants => {:include => {:option_values => {:include => :option_type}, :images => {}}}, :images => {}, :master => {}})
    end
  end

  def collection
    return @collection if @collection.present?

    unless request.xhr?
      params[:search] ||= {}
      # Note: the MetaSearch scopes are on/off switches, so we need to select "not_deleted" explicitly if the switch is off
      if params[:search][:deleted_at_is_null].nil?
        params[:search][:deleted_at_is_null] = "1"
      end

      params[:search][:meta_sort] ||= "name.asc"
      @search = end_of_association_chain.metasearch(params[:search])

      pagination_options = {
           :per_page => Spree::Config[:supplier_per_page],
           :page     => params[:page]
      }

      @collection = @search.paginate(pagination_options)

    else
      puts "xxx"

    end



  end

  def update_before
    # note: we only reset the product properties if we're receiving a post from the form on that tab
    #return unless params[:clear_product_properties]
    #params[:product] ||= {}
  end

end
