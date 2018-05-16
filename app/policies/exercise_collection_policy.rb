class ExerciseCollectionPolicy < AdminOnlyPolicy

  def statistics?
    admin?
  end

end
