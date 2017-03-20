class Question < ApplicationRecord
  belongs_to :user
  belongs_to :topic
  has_many :question_attachments
end
