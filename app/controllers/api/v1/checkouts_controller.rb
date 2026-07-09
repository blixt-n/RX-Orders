class Api::V1::CheckoutsController < ApplicationController
  def create
    order = Order.find(params[:order_id])
    result = StripeCheckout.new(order).call

    if result[:success]
      render json: { client_secret: result[:client_secret] }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end
end
