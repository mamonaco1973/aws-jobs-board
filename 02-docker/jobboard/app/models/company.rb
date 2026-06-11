class Company < ApplicationRecord
  belongs_to :user
  has_many :jobs, dependent: :destroy

  validates :name, presence: true
  validates :location, presence: true
end
