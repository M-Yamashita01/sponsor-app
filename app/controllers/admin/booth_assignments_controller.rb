class Admin::BoothAssignmentsController < ::Admin::ApplicationController
  before_action :set_conference

  def show
    @sponsorships = @conference.sponsorships
      .includes(:plan)
      .where(booth_requested: true)
      .or(Sponsorship.includes(:plan).where(booth_assigned: true))
      .order('plans.booth_size desc, sponsorships.name asc')
    @exhibitors = @sponsorships.select(&:booth_assigned?)
  end

  def update
    @sponsorships = @conference.sponsorships
    @sponsorships.each do |sponsorship|
      sponsorship.booth_assigned = booth_assignments_param[sponsorship.id.to_s] == '1'
      sponsorship.save!(validate: false)
    end
    redirect_to conference_booth_assignment_path(@conference), notice: 'Assignment updated'
  end

  private

  def set_conference
    @conference = Conference.find_by!(slug: params[:conference_slug])
  end

  def booth_assignments_param
    params.require(:booth_assignments).permit!
  end
end
