class CoursePlace < ApplicationRecord
  belongs_to :course
  belongs_to :place

  validates :position, presence: true
end
