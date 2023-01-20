# frozen_string_literal: true

class ProxyExercise < ApplicationRecord
  include Creation
  include DefaultValues

  enum algorithm: {
    best_match: 0,
    random: 1,
  }, _default: :write, _prefix: true

  after_initialize :generate_token
  after_initialize :set_reason
  after_initialize :set_default_values

  has_and_belongs_to_many :exercises
  has_many :user_proxy_exercise_exercises

  validates :public, inclusion: [true, false]

  def count_files
    exercises.count
  end

  def set_reason
    @reason = {}
  end

  def generate_token
    self.token ||= SecureRandom.hex(4)
  end
  private :generate_token

  def set_default_values
    set_default_values_if_present(public: false)
  end
  private :set_default_values

  def duplicate(attributes = {})
    proxy_exercise = dup
    proxy_exercise.attributes = attributes
    proxy_exercise
  end

  def to_s
    title
  end

  def get_matching_exercise(user)
    assigned_user_proxy_exercise = user_proxy_exercise_exercises.find_by(user:)
    if assigned_user_proxy_exercise
      Rails.logger.debug { "retrieved assigned exercise for user #{user.id}: Exercise #{assigned_user_proxy_exercise.exercise}" }
      assigned_user_proxy_exercise.exercise
    else
      matching_exercise =
        case algorithm
          when 'best_match'
            Rails.logger.debug { "find new matching exercise for user #{user.id}" }
            begin
              find_matching_exercise(user)
            rescue StandardError => e # fallback
              Rails.logger.error("finding matching exercise failed. Fall back to random exercise! Error: #{$ERROR_INFO}")
              @reason[:reason] = 'fallback because of error'
              @reason[:error] = "#{$ERROR_INFO}:\n\t#{e.backtrace.join("\n\t")}"
              exercises.where('expected_difficulty > 1').sample # difficulty should be > 1 to prevent dummy exercise from being chosen.
            end
          when 'random'
            @reason[:reason] = 'random exercise requested'
            exercises.sample
          else
            raise "Unknown algorithm #{algorithm}"
        end

      user.user_proxy_exercise_exercises << UserProxyExerciseExercise.create(user:,
        exercise: matching_exercise, proxy_exercise: self, reason: @reason.to_json)
      matching_exercise
    end
  end

  def find_matching_exercise(user)
    exercises_user_has_accessed = user.submissions.where("cause IN ('submit','assess')").map(&:exercise).uniq.compact
    tags_user_has_seen = exercises_user_has_accessed.map(&:tags).uniq.flatten
    Rails.logger.debug { "exercises_user_has_accessed #{exercises_user_has_accessed.map(&:id).join(',')}" }

    # find exercises
    potential_recommended_exercises = []
    exercises.where('expected_difficulty >= 1').find_each do |ex|
      ## find exercises which have only tags the user has already seen
      if (ex.tags - tags_user_has_seen).empty?
        potential_recommended_exercises << ex
      end
    end
    Rails.logger.debug { "potential_recommended_exercises: #{potential_recommended_exercises.map(&:id)}" }
    # if all exercises contain tags which the user has never seen, recommend easiest exercise
    if potential_recommended_exercises.empty?
      Rails.logger.debug('matched easiest exercise in pool')
      @reason[:reason] = 'easiest exercise in pool. empty potential exercises'
      select_easiest_exercise(exercises)
    else
      select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
    end
  end
  private :find_matching_exercise

  def select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
    topic_knowledge_user_and_max = get_user_knowledge_and_max_knowledge(user, exercises_user_has_accessed)
    Rails.logger.debug { "topic_knowledge_user_and_max: #{topic_knowledge_user_and_max}" }
    Rails.logger.debug { "potential_recommended_exercises: #{potential_recommended_exercises.size}: #{potential_recommended_exercises.map(&:id)}" }
    topic_knowledge_user = topic_knowledge_user_and_max[:user_topic_knowledge]
    topic_knowledge_max = topic_knowledge_user_and_max[:max_topic_knowledge]
    current_users_knowledge_lack = {}
    topic_knowledge_max.each_key do |tag|
      current_users_knowledge_lack[tag] = topic_knowledge_user[tag] / topic_knowledge_max[tag]
    end

    relative_knowledge_improvement = {}
    potential_recommended_exercises.each do |potex|
      tags = potex.tags
      relative_knowledge_improvement[potex] = 0.0
      Rails.logger.debug { "review potential exercise #{potex.id}" }
      tags.each do |tag|
        tag_ratio = potex.exercise_tags.find_by(tag:).factor.to_f / potex.exercise_tags.inject(0) do |sum, et|
                                                                      sum + et.factor
                                                                    end
        max_topic_knowledge_ratio = potex.expected_difficulty * tag_ratio
        old_relative_loss_tag = topic_knowledge_user[tag] / topic_knowledge_max[tag]
        new_relative_loss_tag = topic_knowledge_user[tag] / (topic_knowledge_max[tag] + max_topic_knowledge_ratio)
        Rails.logger.debug { "tag #{tag} old_relative_loss_tag #{old_relative_loss_tag}, new_relative_loss_tag #{new_relative_loss_tag}, tag_ratio #{tag_ratio}" }
        relative_knowledge_improvement[potex] += old_relative_loss_tag - new_relative_loss_tag
      end
    end

    highest_difficulty_user_has_accessed = exercises_user_has_accessed.map(&:expected_difficulty).max || 0
    best_matching_exercise = find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
    @reason[:reason] = 'best matching exercise'
    @reason[:highest_difficulty_user_has_accessed] = highest_difficulty_user_has_accessed
    @reason[:current_users_knowledge_lack] = current_users_knowledge_lack
    @reason[:relative_knowledge_improvement] = relative_knowledge_improvement

    Rails.logger.debug do
      "current users knowledge loss: #{current_users_knowledge_lack.map do |k, v|
                                         "#{k} => #{v}"
                                       end}"
    end
    Rails.logger.debug { "relative improvements #{relative_knowledge_improvement.map {|k, v| "#{k.id}:#{v}" }}" }
    best_matching_exercise
  end
  private :select_best_matching_exercise

  def find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
    Rails.logger.debug { "select most appropiate exercise for user. his highest difficulty was #{highest_difficulty_user_has_accessed}" }
    sorted_exercises = relative_knowledge_improvement.sort_by {|_k, v| v }.reverse

    sorted_exercises.each do |ex, _diff|
      Rails.logger.debug { "review exercise #{ex.id} diff: #{ex.expected_difficulty}" }
      if (ex.expected_difficulty - highest_difficulty_user_has_accessed) <= 1
        Rails.logger.debug { "matched exercise #{ex.id}" }
        return ex
      else
        Rails.logger.debug { "exercise #{ex.id} is too difficult" }
      end
    end
    easiest_exercise = sorted_exercises.min_by {|_k, v| v }.first
    Rails.logger.debug { "no match, select easiest exercise as fallback #{easiest_exercise.id}" }
    easiest_exercise
  end
  private :find_best_exercise

  # [score][quantile]
  def scoring_matrix
    [
      [0, 0, 0, 0, 0],
      [0.2, 0.2, 0.2, 0.2, 0.1],
      [0.5, 0.5, 0.4, 0.4, 0.3],
      [0.6, 0.6, 0.5, 0.5, 0.4],
      [1, 1, 0.9, 0.8, 0.7],
    ]
  end

  def scoring_matrix_quantiles
    [0.2, 0.4, 0.6, 0.8]
  end
  private :scoring_matrix_quantiles

  def score(user, exercise)
    max_score = exercise.maximum_score.to_f
    if max_score <= 0
      Rails.logger.debug { "scoring user #{user.id} for exercise #{exercise.id}:  score: 0" }
      return 0.0
    end
    points_ratio = exercise.maximum_score(user) / max_score
    if points_ratio.to_d == BigDecimal('0.0')
      Rails.logger.debug { "scoring user #{user.id} for exercise #{exercise.id}: points_ratio=#{points_ratio} score: 0" }
      return 0.0
    elsif points_ratio > 1.0
      points_ratio = 1.0 # The score of the exercise was adjusted and is now lower than it was
    end
    points_ratio_index = ((scoring_matrix.size - 1) * points_ratio).to_i
    working_time_user = exercise.accumulated_working_time_for_only(user)
    quantiles_working_time = exercise.get_quantiles(scoring_matrix_quantiles)
    quantile_index = quantiles_working_time.size
    quantiles_working_time.each_with_index do |quantile_time, i|
      if working_time_user <= quantile_time
        quantile_index = i
        break
      end
    end
    Rails.logger.debug do
      "scoring user #{user.id} exercise #{exercise.id}: worktime #{working_time_user}, points: #{points_ratio}" \
        "(index #{points_ratio_index}) quantiles #{quantiles_working_time} placed into quantile index #{quantile_index} " \
        "score: #{scoring_matrix[points_ratio_index][quantile_index]}"
    end
    scoring_matrix[points_ratio_index][quantile_index]
  end
  private :score

  def get_user_knowledge_and_max_knowledge(user, exercises)
    # initialize knowledge for each tag with 0
    all_used_tags_with_count = {}
    exercises.each do |ex|
      ex.tags.each do |t|
        all_used_tags_with_count[t] ||= 0
        all_used_tags_with_count[t] += 1
      end
    end
    tags_counter = all_used_tags_with_count.keys.index_with {|_tag| 0 }
    topic_knowledge_loss_user = all_used_tags_with_count.keys.index_with {|_t| 0 }
    topic_knowledge_max = all_used_tags_with_count.keys.index_with {|_t| 0 }
    exercises_sorted = exercises.sort_by {|ex| ex.time_maximum_score(user) }
    exercises_sorted.each do |ex|
      Rails.logger.debug { "exercise: #{ex.id}: #{ex}" }
      user_score_factor = score(user, ex)
      ex.tags.each do |t|
        tags_counter[t] += 1
        tag_diminishing_return_factor = tag_diminishing_return_function(tags_counter[t], all_used_tags_with_count[t])
        tag_ratio = ex.exercise_tags.find_by(tag: t).factor.to_f / ex.exercise_tags.inject(0) do |sum, et|
                                                                     sum + et.factor
                                                                   end
        Rails.logger.debug do
          "tag: #{t}, factor: #{ex.exercise_tags.find_by(tag: t).factor}, sumall: #{ex.exercise_tags.inject(0) do |sum, et|
                                                                                      sum + et.factor
                                                                                    end }"
        end
        Rails.logger.debug { "tag #{t}, count #{tags_counter[t]}, max: #{all_used_tags_with_count[t]}, factor: #{tag_diminishing_return_factor}" }
        Rails.logger.debug { "tag_ratio #{tag_ratio}" }
        topic_knowledge_ratio = ex.expected_difficulty * tag_ratio
        Rails.logger.debug { "topic_knowledge_ratio #{topic_knowledge_ratio}" }
        topic_knowledge_loss_user[t] += (1 - user_score_factor) * topic_knowledge_ratio * tag_diminishing_return_factor
        topic_knowledge_max[t] += topic_knowledge_ratio * tag_diminishing_return_factor
      end
    end
    {user_topic_knowledge: topic_knowledge_loss_user, max_topic_knowledge: topic_knowledge_max}
  end

  def tag_diminishing_return_function(count_tag, total_count_tag)
    total_count_tag += 1 # bonus exercise comes on top
    1 / ((Math::E**(-3 / (total_count_tag * 0.5) * (count_tag - (total_count_tag * 0.5)))) + 1)
  end

  def select_easiest_exercise(exercises)
    exercises.order(:expected_difficulty).first
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title]
  end
end
