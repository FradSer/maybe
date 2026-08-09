class OnboardingsController < ApplicationController
  layout "wizard"

  before_action :set_user
  before_action :load_invitation

  def show
  end

  def preferences
  end

  def trial
  end

  # Bypass the current onboarding step. Invited users must still complete
  # onboarding (their hidden onboarded_at field is normally set on submit),
  # so mark them onboarded here instead of looping back to the wizard.
  def skip
    if @invitation && !Current.user.onboarded?
      Current.user.update!(onboarded_at: Time.current)
    end
    redirect_to @invitation ? root_path : preferences_onboarding_path
  end

  private
    def set_user
      @user = Current.user
    end

    def load_invitation
      @invitation = Current.family.invitations.accepted.find_by(email: Current.user.email)
    end
end
