class Admin::ProductsController < Admin::BaseController
  resource_controller
  before_filter :check_json_authenticity, :only => :index
  before_filter :load_data, :except => :index

  index.response do |wants|
    wants.html { render :action => :index }
    wants.json { render :json => json_data }
  end

  new_action.response do |wants|
    wants.html {render :action => :new, :layout => !request.xhr?}
  end

  update.before :update_before

  create.response do |wants|
    # go to edit form after creating as new product
    wants.html {redirect_to edit_admin_product_url(@product) }
  end

  update.response do |wants|
    # override the default redirect behavior of r_c
    # need to reload Product in case name / permalink has changed
    wants.html {redirect_to edit_admin_product_url(@product) }
  end

  # override the destory method to set deleted_at value
  # instead of actually deleting the product.
  def destroy
    @product = Product.find_by_permalink(params[:id])
    @product.deleted_at = Time.now()

    @product.variants.each do |v|
      v.deleted_at = Time.now()
      v.save
    end

    if @product.save
      flash.notice = I18n.t("notice_messages.product_deleted")
    else
      flash.notice = I18n.t("notice_messages.product_not_deleted")
    end

    respond_to do |format|
      format.html { redirect_to collection_url }
      format.js  { render_js_for_destroy }
    end
  end

  def clone
    load_object
    @new = @product.duplicate

    if @new.save
      flash.notice = I18n.t("notice_messages.product_cloned")
    else
      flash.notice = I18n.t("notice_messages.product_not_cloned")
    end

    redirect_to edit_admin_product_url(@new)
  end

  # Allow different formats of json data to suit different ajax calls
  def json_data
    json_format = params[:json_format] or 'default'
    case json_format
    when 'basic'
      collection.map {|p| {'id' => p.id, 'name' => p.name}}.to_json
    else
      collection.to_json(:include => {:variants => {:include => {:option_values => {:include => :option_type}, :images => {}}}, :images => {}, :master => {}})
    end
  end

  def load_data
    @tax_categories = TaxCategory.order(:name)
    @shipping_categories = ShippingCategory.order(:name)
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

      pagination_options = {:include   => {:variants => [:images, :option_values]},
                            :per_page  => Spree::Config[:admin_products_per_page],
                            :page      => params[:page]}

      @collection = @search.relation.group_by_products_id.paginate(pagination_options)
    else
      includes = [{:variants => [:images,  {:option_values => :option_type}]}, :master, :images]

      @collection = end_of_association_chain.where(["name LIKE ?", "%#{params[:q]}%"])
      @collection = @collection.includes(includes).limit(params[:limit] || 10)

      tmp = end_of_association_chain.where(["variants.sku LIKE ?", "%#{params[:q]}%"])
      tmp = tmp.includes(:variants_including_master).limit(params[:limit] || 10)
      @collection.concat(tmp)

      @collection.uniq
    end

  end

  def update_before
    # note: we only reset the product properties if we're receiving a post from the form on that tab
    return unless params[:clear_product_properties]
    params[:product] ||= {}
  end

end
