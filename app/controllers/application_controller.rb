class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include Clearance::Authorization

  helper :announcements
  helper ActiveSupport::NumberHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_forbidden

  before_action :set_locale
  before_action :reject_null_char_param

  def set_locale
    I18n.locale = user_locale

    # after store current locale
    session[:locale] = params[:locale] if params[:locale]
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
  end

  rescue_from(ActionController::ParameterMissing) do |e|
    render plain: "Request is missing param '#{e.param}'", status: :bad_request
  end

  protected

  def fastly_expires_in(seconds)
    response.headers["Surrogate-Control"] = "max-age=#{seconds}"
  end

  def set_surrogate_key(*surrogate_keys)
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  def redirect_to_signin
    response.headers["Cache-Control"] = "private, max-age=0"
    redirect_to sign_in_path, alert: t("please_sign_in")
  end

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id] || params[:id])
    return if @rubygem
    respond_to do |format|
      format.any do
        render plain: t(:this_rubygem_could_not_be_found), status: :not_found
      end
      format.html do
        render file: "public/404", status: :not_found, layout: false, formats: [:html]
      end
    end
  end

  def find_versioned_links
    @versioned_links = @rubygem.links(@latest_version)
  end

  def set_page(max_page = Gemcutter::MAX_PAGES)
    @page = Gemcutter::DEFAULT_PAGE && return unless params.key?(:page)
    redirect_to_page_with_error && return unless valid_page_param?(max_page)

    @page = params[:page].to_i
  end

  def user_locale
    params[:locale] || session[:locale] || http_head_locale || I18n.default_locale
  end

  def http_head_locale
    http_accept_language.language_region_compatible_from(I18n.available_locales)
  end

  def render_not_found
    respond_to do |format|
      format.html { render file: "public/404", status: :not_found, layout: false }
      format.json { render json: { error: t(:not_found) }, status: :not_found }
      format.yaml { render yaml: { error: t(:not_found) }, status: :not_found }
      format.any(:all) { render text: t(:not_found), status: :not_found }
    end
  end

  def render_forbidden
    render plain: "forbidden", status: :forbidden
  end

  def redirect_to_page_with_error
    flash[:error] = t("invalid_page") unless controller_path.starts_with? "api"
    page_params = params.except(:controller, :action, :page)
      .permit(:query, :to, :from, :format, :letter)
      .merge(page: Gemcutter::DEFAULT_PAGE)
    redirect_to url_for(page_params)
  end

  def valid_page_param?(max_page)
    params[:page].respond_to?(:to_i) && params[:page].to_i.between?(Gemcutter::DEFAULT_PAGE, max_page)
  end

  def reject_null_char_param
    render plain: "bad request", status: :bad_request if params.to_s.include?("\\u0000")
  end
end
