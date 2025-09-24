class RemoveCompletedColumnFromAnswers < ActiveRecord::Migration[7.1]
  def change
    remove_column :answers, :completed, :boolean
  end
end
