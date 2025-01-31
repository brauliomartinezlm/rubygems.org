class Mailer < ActionMailer::Base
  layout "mailer"
  include Roadie::Rails::Automatic

  default from: Clearance.configuration.mailer_sender

  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = User.find(user["id"])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.unconfirmed_email,
         subject: I18n.t("mailer.confirmation_subject",
           default: "Please confirm your email address with RubyGems.org")
  end

  def email_confirmation(user)
    @user = User.find(user["id"])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t("mailer.confirmation_subject",
           default: "Please confirm your email address with RubyGems.org")
  end

  def deletion_complete(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t("mailer.deletion_complete.subject")
  end

  def deletion_failed(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t("mailer.deletion_failed.subject")
  end

  def notifiers_changed(user_id)
    user = User.find(user_id)
    @ownerships = user.ownerships.by_gem_name

    mail to: user.email,
         subject: I18n.t("mailer.notifiers_changed.subject",
           default: "You changed your RubyGems.org email notification settings")
  end

  def gem_pushed(pushed_by_user_id, version_id)
    @version = Version.find(version_id)
    owners_to_notify = @version.rubygem.owners.where(ownerships: { notifier: true }).pluck(:email)
    return if owners_to_notify.empty?

    @pushed_by_user = User.find(pushed_by_user_id)

    mail bcc: owners_to_notify,
         subject: I18n.t("mailer.gem_pushed.subject", gem: @version.to_title,
           default: "Gem %{gem} pushed to RubyGems.org")
  end
end
