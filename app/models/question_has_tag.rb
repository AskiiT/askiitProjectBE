class QuestionHasTag < ApplicationRecord
  belongs_to :question
  belongs_to :tag

  validates_uniqueness_of :question, :scope => [:tag]

  def self.tag_created(new_name)
    ta=Tag.new
    ta.tag_name=new_name.upcase
    ta.save
  end

  def self.topic_of_tag(tag)
  	g=Tag.find_by_id(tag).topic_id
  	g.to_i
  end

  def self.topic_of_question(question)
  	g=Question.find_by_id(question).topic_id
  	g.to_i
  end

  def getTopic
  	Topic.topic_in_question(question_id)
  end
  
  def self.get_from_question_and_tag( question_id, tag_id )
    where( question_has_tags: {question_id: question_id, tag_id: tag_id} )
  end

end
