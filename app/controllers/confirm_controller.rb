class ConfirmController < Spree::BaseController

  def paypal
    path = "#{@_env['PATH_INFO']}".gsub("confirm/","")

    @order = Order.where("number = ?", "#{params[:order_id]}").first
    @store = Store.where("id = ?", @order.store_id).first

    if @store.domains != request.host_with_port
      redirect_to "http://" + @store.domains  + path  + "?" +  "#{@_env['QUERY_STRING']}"
    else
      redirect_to "http://" + request.host_with_port  + path  + "?" +  "#{@_env['QUERY_STRING']}"
    end
  end

end