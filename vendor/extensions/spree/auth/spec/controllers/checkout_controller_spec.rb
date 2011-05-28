require 'spec_helper'

describe CheckoutController do
  let(:order) { Order.new }
  let(:user) { mock_model User }
  let(:token) { "some_token" }

  before do
    order.stub :checkout_allowed? => true, :user => user, :new_record? => false
    controller.stub :current_order => order
    controller.stub :current_user => nil
  end


  context "#edit" do
    context "when registration step enabled" do
      before do
        controller.stub :check_authorization
        Spree::Auth::Config.set(:registration_step => true)
      end

      context "when authenticated as registered user" do
        before { controller.stub :current_user => user }

        it "should proceed to the first checkout step" do
          get :edit, { :state => "confirm" }
          response.should render_template :edit
        end
      end

      context "when authenticated as guest" do
        before { controller.stub :auth_user => user }

        it "should redirect to registration step" do
          get :edit, { :state => "confirm" }
          response.should redirect_to checkout_registration_path
        end
      end

    end

    context "when registration step disabled" do
      before do
        Spree::Auth::Config.set(:registration_step => false)
        controller.stub :check_authorization
      end

      context "when authenticated as registered" do
        before { controller.stub :current_user => user }

        it "should proceed to the first checkout step" do
          get :edit, { :state => "confirm" }
          response.should render_template :edit
        end
      end

      context "when authenticated as guest" do
        before { controller.stub :auth_user => user }

        it "should proceed to the first checkout step" do
          get :edit, { :state => "confirm" }
          response.should render_template :edit
        end
      end

    end

    it "should check if the user is authorized for :edit" do
      controller.should_receive(:authorize!).with(:edit, order, token)
      get :edit, { :state => "confirm" }, { :access_token => token }
    end

  end


  context "#update" do

    it "should check if the user is authorized for :edit" do
      controller.should_receive(:authorize!).with(:edit, order, token)
      post :update, { :state => "confirm" }, { :access_token => token }
    end

    context "when save successful" do
      before do
        controller.stub :check_authorization
        order.stub(:update_attribute).and_return true
        order.should_receive(:update_attributes).and_return true
      end

      context "when in the confirm state" do
        before do
          order.stub :next => true
          order.stub :state => "complete"
          order.stub :number => "R123"
        end

        context "with a guest user" do
          before do
            order.stub :token => "ABC"
            user.stub :has_role? => true
            controller.stub :current_user => nil
          end

          it "should redirect to the tokenized order view" do
            post :update, {:state => "confirm"}
            response.should redirect_to token_order_path("R123", "ABC")
          end

          it "should populate the flash message" do
            post :update, {:state => "confirm"}
            flash[:notice].should == I18n.t(:order_processed_successfully)
          end
        end

        context "with a registered user" do
          before do
            user.stub :has_role? => true
            controller.stub :current_user => mock_model(User, :has_role? => true)
          end

          it "should redirect to the standard order view" do
            post :update, {:state => "confirm"}
            response.should redirect_to order_path("R123")
          end
        end

      end
    end


  end

  context "#registration" do

    it "should not check registration" do
      controller.stub :check_authorization
      controller.should_not_receive :check_registration
      get :registration
    end

    it "should check if the user is authorized for :edit" do
      controller.should_receive(:authorize!).with(:edit, order, token)
      get :registration, {}, { :access_token => token }
    end

  end

  context "#update_registration" do
    let(:user) { user = mock_model User }

    it "should not check registration" do
      controller.stub :check_authorization
      order.stub :update_attributes => true
      controller.should_not_receive :check_registration
      put :update_registration
    end

    it "should render the registration view if unable to save" do
      controller.stub :check_authorization
      order.should_receive(:update_attributes).with("email" => "invalid").and_return false
      put :update_registration, { :order => {:email => "invalid"} }
      response.should render_template :registration
    end

    it "should redirect to the checkout_path after saving" do
      order.stub :update_attributes => true
      controller.stub :check_authorization
      put :update_registration, { :order => {:email => "jobs@railsdog.com"} }
      response.should redirect_to checkout_path
    end

    it "should check if the user is authorized for :edit" do
      order.stub :update_attributes => true
      controller.should_receive(:authorize!).with(:edit, order, token)
      put :update_registration, { :order => {:email => "jobs@railsdog.com"} }, { :access_token => token }
    end

  end

end
