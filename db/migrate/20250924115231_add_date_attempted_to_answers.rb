class AddDateAttemptedToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :answers, :date_attempted, :datetime
  end
end
