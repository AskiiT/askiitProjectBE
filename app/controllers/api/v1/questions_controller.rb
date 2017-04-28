class API::V1::QuestionsController < ApplicationController
  before_action :set_question, only: [:show, :update, :destroy]
  #before_action :authenticate_user!, only:[:create, :destroy, :update]

  def getCols(arr, query)
    parameters=['id', 'title', 'body', 'user_id', 'topic_id', 'difficulty','date_posted']
    por=arr & parameters
    cols=[]
    endjson=query
    unless por.empty?
      if por.include?('id')
        cols.push(:id)
      end
      if por.include?('title')
        cols.push(:title)
      end
      if por.include?('body')
        cols.push(:body)
      end
      if por.include?('user_id')
        cols.push(:user_id)
      end
      if por.include?('topic_id')
        cols.push(:topic_id)
      end
      if por.include?('difficulty')
        cols.push(:difficulty)
      end
      if por.include?('date_posted')
        cols.push(:date_posted)
      end
      endjson=endjson.to_json(:only => cols)
    end
    endjson
  end

  def translate(s)
    s=s.upcase
    case s
    when '-DATE'
      s=1
    when 'DATE'
      s=2
    when'-DIFFICULTY'
      s=3
    when 'DIFFICULTY'
      s=4
    when '-TOPIC'
      s=5
    when 'TOPIC'
      s=6
    when '-USER'
      s=7
    when 'USER'
      s=8
    when '-BODY'
      s=9
    when 'BODY'
      s=10
    when '-TITLE'
      s=11
    when 'TITLE'
      s=12
    when '-ID'
      s=13
    when 'ID'
      s=14
    else
      s=1
    end
  end

  # GET /questions
  def index
    #@questions = Question.all
    p = params[:page]
    s = params[:sort]
    if s.nil?
      s = 1
    else
      s = translate(s)
    end

    @questions = Question.load_questions( sort = s, page = p )
    q=params[:q]
    unless q.nil?
      @questions=@questions.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @questions=getCols(el, @questions)
    end
    if @questions.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @questions
    end
  end

  # GET /questions/1
  def show
    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @question=getCols(el, @question)
    end
    render json: @question
   
  end

  # POST /questions
  def create
    @question = Question.new(question_params)
    #@question.user_id= current_user.id
    g=params[:topic]
    if g.nil?
      render json: {data: {error: "Topic no puede estar vacio"}}
    else
      m=g.to_i
      
      if m.to_s != g.to_s
        u=Topic.topic_id_name(params[:topic])
        g=u.to_i
      end
      @question.topic_id=g

      if @question.save
        question_id=@question.id
        tags=params[:tags]
        valid=true
        unless tags.nil?
          siz=tags.size
          if siz>3
            siz=3
          end
          for j in 0...siz do
            @question_has_tag = QuestionHasTag.new
            tag_id=tags[j]
            name=tag_id
            ta_id=Tag.tag_id_name(name)

            if ta_id<0
              QuestionHasTag.tag_created(name)
              ta_id=Tag.tag_id_name(name)
            end
            @question_has_tag.tag_id=ta_id
            @question_has_tag.question_id=question_id
            @question_has_tag.save
          end
        end

        render json: @question, status: :created 


      else
        render json: @question.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /questions/1
  # def update
  #   if @question.user_id == current_user.id
  #     if @question.update(question_params)
  #       render json: @question
  #     else
  #       render json: @question.errors, status: :unprocessable_entity
  #     end
  #   else
  #     render json: 
  #       { data:
  #         {
  #           error: "Usted no puede editar esta pregunta."
  #         }
  #       }
  #   end  
  # end

  # DELETE /questions/1
  # def destroy
  #   if @question.user_id==current_user.id
  #     @question.destroy
  #   else
  #     render json: 
  #       { data:
  #         {
  #           error: "Usted no puede eliminar esta pregunta."
  #         }
  #       }
  #     end
  # end

  def destroy
    @question.destroy
  end
  
  def update
    if @question.update(question_params)
      render json: @question
    else
      render json: @question.errors, status: :unprocessable_entity
    end 
  end
  ###############################
  ###Custom methods
  ###############################

  def questions_by_title
    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end

    @questions = Question.questions_by_title(title=params[:title], sort=s).page(params[:page])
    
    if @questions.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @questions
    end
  end

  def by_tag
    g = params[:tag]
    idds=[]
    g=g.split(",")

    ps = params[:page]
    if ps.nil?
      ps=1
    end
    size=g.size;
    if size==1
      k= g[0]
      m = k.to_i
      if m.to_s != g.to_s
        u=Tag.tag_id_name(params[:tag])
        k=u.to_i
      end

      s= params[:sort]
      if s.nil?
        s=1
      else
        s=translate(s)
      end
      @questions = Question.questions_by_tag(tag=g, sort=s).page(ps)
    else
      idds=[]
      top=[]
      for j in 0...size
        k=g[j].to_i
        m = k.to_i
        titl=g[j].to_s
        if titl.size>3
          tre=titl[0,3]
          if tre=="to_"
            m=Topic.topic_id_name(titl[3,titl.size])
            unless m<1
              top.push(m)
            end
          end
        elsif m.to_s != k.to_s
          u=Tag.tag_id_name(k)
          k=u.to_i
        end
        if k>0
          idds.push(k)
        end
      end
      @questions=Question.questions_by_manytags(ids=idds, topics=top, sort=s, page=ps)
    end
    
    q=params[:q]
    unless q.nil?
      @questions=@questions.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @questions=getCols(el, @questions)
    end

    if @questions.nil?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    elsif @questions.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @questions
    end
  end

  def by_topic
    g=params[:topic]
    m=g.to_i
    
    if m.to_s != g.to_s
      u=Topic.topic_id_name(params[:topic])
      g=u.to_i
    end

    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end


    @questions = Question.questions_by_topic(topic=g, sort=s).page(params[:page])
    
    q=params[:q]
    unless q.nil?
      @questions=@questions.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @questions=getCols(el, @questions)
    end
    if @questions.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @questions
    end
  end


  def my_questions
    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end

    @question_list = Question.questions_by_user(user=params[:user_id], sort=s).page(params[:page])
    
    q=params[:q]
    unless q.nil?
      @question_list=@question_list.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @question_list=getCols(el, @question_list)
    end
    if @question_list.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
      else
        render json: @question_list
      end
  end


  def is_postulated_to
    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end
    @postulate= Question.question_postulated(user=params[:user_id], sort=s).page(params[:page])
    q=params[:q]
    unless q.nil?
      @postulate=@postulate.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @postulate=getCols(el, @postulate)
    end

    if @postulate.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @postulate
    end
  end


  def has_postulated
    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end
    @question=Question.postulated_question(sort=s).page(params[:page])
    q=params[:q]
    unless q.nil?
      @question=@question.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end

    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @question=getCols(el, @question)
    end

    if @question.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @question
    end
  end

  def has_not_postulated
    s= params[:sort]
    if s.nil?
      s=1
    else
      s=translate(s)
    end
    @question=Question.not_postulated_question(sort=s).page(params[:page])
    q=params[:q]
    unless q.nil?
      @question=@question.where("lower(questions.title) LIKE ?", "%#{q.downcase}%")
    end
    
    el=params[:select_questions]
    unless el.nil?
      el=el.split(",")
      el=el.map(&:downcase)
      @question=getCols(el, @question)
    end
    if @question.empty?
      render json: 
        { data:
          {
            error: "No more questions to show."
          }
        }
    else
      render json: @question
    end
  end

  ######
  ##Other functions
  ######

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_question
      @question = Question.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def question_params
      params.require(:question).permit(:title, :body, :date_posted, :difficulty, :user_id)
    end
end
