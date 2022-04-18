# frozen_string_literal: true

class AwsStudy
  def self.get_for(exercise)
    java20_collection = ExerciseCollection.find_by(name: 'java2020', id: 11)
    java20_bonus_collection = ExerciseCollection.find_by(name: 'java2020-bonusexercise', id: 12)

    exercise.exercise_collections.any? {|ec| [java20_collection, java20_bonus_collection].include?(ec) }
  end

  def self.get_execution_environment(user, exercise)
    # Poseidon is disabled and thus no AWS support available
    return exercise.execution_environment unless Runner::Strategy::Poseidon == Runner.strategy_class

    java20_exercise = get_for(exercise)
    # Exercise is not part of the experiment
    return exercise.execution_environment unless java20_exercise

    user_group = UserGroupSeparator.get_aws_group(user.id)
    case user_group
      when :use_aws
        # AWS functions are currently identified with their name
        aws_function = ExecutionEnvironment.find_by(docker_image: 'java11Exec')
        # Fallback to the default execution environment if no AWS function is found
        aws_function || exercise.execution_environment
      else # :no_aws
        exercise.execution_environment
    end
  end
end
