class Job < ApplicationRecord
  belongs_to :company
  has_many :job_applications, dependent: :destroy

  validates :title, :description, :location, presence: true
  validates :salary_min, :salary_max, numericality: { greater_than: 0 }, allow_nil: true

  scope :recent,      -> { order(created_at: :desc) }
  scope :by_location, ->(loc) { where(location: loc) if loc.present? }
  scope :by_keyword,  ->(q)   { where("title ILIKE ? OR description ILIKE ?", "%#{q}%", "%#{q}%") if q.present? }

  def salary_range
    return "Not specified" unless salary_min || salary_max
    parts = [salary_min && "$#{salary_min.to_i / 1000}k", salary_max && "$#{salary_max.to_i / 1000}k"]
    parts.compact.join(" – ")
  end
end
