class RemoveUpdatedAtFromAnswers < ActiveRecord::Migration[7.1]
  def change
    remove_column :answers, :updated_at, :datetime
  end
end
