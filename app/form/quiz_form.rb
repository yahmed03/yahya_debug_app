# QuizForm represents a form object for handling quiz answers and related data.
#
# It includes ActiveModel::Model for providing model-like behavior without an actual database table,
# and QuizConstantsHelper for accessing constants related to quizzes.
#
# Attributes:
# - answer_1 to answer_5: String attributes representing answers to quiz questions.
# - current_step: Integer representing the current step/page of the quiz.
# - current_user_id: Integer representing the ID of the current user taking the quiz.
# - answer: Array containing all answer attributes.
#
# Validations:
# - validate_answers: Custom validation to ensure all answers are present.
#
# Public Methods:
# - update_answers: Updates or creates a new answer record based on quiz start time.
# - previous_step: Returns the previous step number.
# - current_page_range: Returns the range of current quiz pages.
# - current_question_range: Returns a hash of questions for the current quiz page.
# - total_steps: Returns the total number of quiz steps.
# - previous_answers: Returns the last attempted quiz answers by the current user.
# - assign_attributes(attributes): Mass assigns attributes to the quiz form.
# - attributes: Returns a hash of the quiz form's attributes.
#
# Private Methods:
# - current_user: Retrieves the current user object based on current_user_id.
# - check_if_quiz_started_today: Checks if the quiz was started today by the current user.
# - question_name: Returns the name of the current quiz question page.
# - build_answer_object: Builds an answer object for saving quiz answers.
# - save_answers: Saves the quiz answers to the database.
# - create_new_answer: Creates a new quiz answer record.
# - answer_valid?: Checks if the quiz answer is valid.
#
class QuizForm
  include ActiveModel::Model
  include QuizConstantsHelper

  attr_accessor :answer_1, :answer_2, :answer_3, :answer_4, :answer_5, :current_step, :current_user_id, :answer

  validate :validate_answers

  # Initializes a new QuizForm instance with given parameters.
  def initialize(params = {})
    @current_step = params[:current_step].to_i
    @current_user_id = params[:current_user_id]
    @answer_1 = params[:answer_1]
    @answer_2 = params[:answer_2]
    @answer_3 = params[:answer_3]
    @answer_4 = params[:answer_4]
    @answer_5 = params[:answer_5]
    @answer = [@answer_1, @answer_2, @answer_3, @answer_4, @answer_5]
  end

  # Custom validation method to ensure all answers are present.
  def validate_answers
    answers = [@answer_1, @answer_2, @answer_3, @answer_4, @answer_5]
    answers.each_with_index do |answer, index|
      next if answer.present?

      errors.add("answer_#{index + 1}", I18n.t('quiz_form.errors.blank_answer'))
    end
  end

  # Updates or creates a new answer record based on quiz start time.
  def update_answers
    if check_if_quiz_started_today
      save_answers
    else
      create_new_answer
    end
  end

  # Returns the previous step number.
  def previous_step
    answer ? current_step - 1 : current_step
  end

  # Returns the range of current quiz pages.
  def current_page_range
    I18n.t('quiz_form.current_page_range', start_page: current_step)
  end

  # Returns a hash of questions for the current quiz page.
  def current_question_range
    question_number_range = (1..QUESTIONS_PER_PAGE)
    questions = {}
    question_number_range.each do |x|
      questions["question_#{x}"] = I18n.t("quiz_form.question_page_#{current_step}.question_#{x}")
    end
    questions
  end

  # Returns the total number of quiz steps.
  def total_steps
    NUMBER_OF_PAGES
  end

  # Returns the last attempted quiz answers by the current user.
  def previous_answers
    current_user.answers.last if current_user.present?
  end

  # Mass assigns attributes to the quiz form.
  def assign_attributes(attributes)
    attributes.each do |key, value|
      send(:"#{key}=", value) if respond_to?(:"#{key}=")
    end
  end

  # Returns a hash of the quiz form's attributes.
  def attributes
    {
      answer_1: @answer_1,
      answer_2: @answer_2,
      answer_3: @answer_3,
      answer_4: @answer_4,
      answer_5: @answer_5,
      current_step: @current_step,
      current_user_id: @current_user_id
    }
  end

  private

  # Retrieves the current user object based on current_user_id.
  def current_user
    @current_user ||= User.find_by(id: current_user_id)
  end

  # Checks if the quiz was started today by the current user.
  def check_if_quiz_started_today
    current_user&.answers&.last&.date_attempted == Time.zone.today && !current_user.answers.last.completed
  end

  # Returns the name of the current quiz question page.
  def question_name
    :"question_page_#{current_step}"
  end

  # Builds an answer object for saving quiz answers.
  def build_answer_object
    { question_name => [@answer_1, @answer_2, @answer_3, @answer_4, @answer_5] }
  end

  # Saves the quiz answers to the database.
  def save_answers
    current_user.answers.last.update(answer: current_user.answers.last.answer.merge(build_answer_object))
  end

  # Creates a new quiz answer record.
  def create_new_answer
    answer = Answer.new(user: current_user, answer: build_answer_object, date_attempted: Time.zone.today,
                        completed: false)
    if answer.valid?
      answer.save!
    else
      answer.errors.each do |attribute, message|
        errors.add(attribute, message)
      end
    end
    @current_user.reload
  end

  # Checks if the quiz answer is valid.
  def answer_valid?
    answer = Answer.new(answer: build_answer_object)
    answer.valid?
  end
end
