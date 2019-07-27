class WebauthnMultifactorAuthsController < Applications
  before_action :redirect_to_signin, unless: :signed_in?

  def create
    credential_options = WebAuthn.credential_creation_options(
      user_id: Base64.strict_encode64(current_user.email),
      user_name: current_user.username,
      display_name: current_user.username
    )

    credential_options[:challenge] = bin_to_str(credential_options[:challenge])
    current_user.update!(current_challenge: credential_options[:challenge])

    respond_to do |format|
      format.json { render json: credential_options.merge(user_id: current_user.id) }
    end
  end

  def callback
  end
end
