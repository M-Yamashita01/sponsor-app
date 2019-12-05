class Conference < ApplicationRecord
  GithubRepo = Struct.new(:raw, :name, :path, :branch, keyword_init: true) do
    def to_s
      raw
    end
  end

  has_many :form_descriptions, dependent: :destroy
  has_many :plans, -> { order(rank: :asc) }, dependent: :destroy
  has_many :sponsorships, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :broadcasts, dependent: :destroy
  has_many :tickets, dependent: :destroy

  scope :application_open, -> { t = Time.now; where('application_opens_at <= ? AND (application_closes_at > ? OR application_closes_at IS NULL) AND application_opens_at IS NOT NULL', t, t) }
  scope :amendment_open, -> { t = Time.now; where('application_opens_at <= ? AND (amendment_closes_at > ? OR amendment_closes_at IS NULL) AND application_opens_at IS NOT NULL', t, t) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :contact_email_address, presence: true
  validate :validate_valid_github_repo

  before_validation :generate_slug
  before_validation :generate_reception_key

  def to_param
    slug
  end

  def application_open?
    t = Time.now
    application_opens_at && application_opens_at <= t && (!application_closes_at || t < application_closes_at)
  end

  def amendment_open?
    t = Time.now
    application_opens_at && application_opens_at <= t && (!amendment_closes_at || t < amendment_closes_at)
  end

  def distributing_ticket?
    t = Time.now
    ticket_distribution_starts_at && ticket_distribution_starts_at <= t
  end

  def form_description_for_locale
    form_descriptions.find_by(locale: I18n.locale) || form_descriptions.find_by!(locale: 'en')
  end

  def github_repo
    ghr = read_attribute(:github_repo)
    if @github_repo&.raw != ghr
      m = ghr.match(/^(.+?)(?:@(.+?))?(?::(.+?))$/)
      @github_repo = m && GithubRepo.new(
        raw: ghr,
        name: m[1],
        branch: m[2].presence,
        path: m[3].presence,
      )
    end
    @github_repo
  end

  def validate_valid_github_repo
    return unless read_attribute(:github_repo).present?
    unless github_repo && github_repo.name.present? && github_repo.path.present?
      errors.add :github_repo, :invalid
    end
  end

  private def generate_slug
    self.slug = name.remove(' ').parameterize if slug.blank?
  end

  private def generate_reception_key
    self.reception_key ||= SecureRandom.urlsafe_base64(96)
  end
end
