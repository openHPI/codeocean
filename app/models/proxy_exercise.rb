class ProxyExercise < ActiveRecord::Base

    after_initialize :generate_token

    has_and_belongs_to_many :exercises
    has_many :user_proxy_exercise_exercises

    def count_files
        exercises.count
    end

    def generate_token
      self.token ||= SecureRandom.hex(4)
    end
    private :generate_token

    def duplicate(attributes = {})
      proxy_exercise = dup
      proxy_exercise.attributes = attributes
      proxy_exercise
    end

    def to_s
      title
    end

    def selectMatchingExercise(user)
      assigned_user_proxy_exercise = user_proxy_exercise_exercises.where(user: user).first
      recommendedExercise =
        if (assigned_user_proxy_exercise)
          Rails.logger.info("retrieved assigned exercise for user #{user.id}: Exercise #{assigned_user_proxy_exercise.exercise}" )
          assigned_user_proxy_exercise.exercise
        else
          Rails.logger.info("find new matching exercise for user #{user.id}" )
          matchingExercise = findMatchingExercise(user)
          user.user_proxy_exercise_exercises << UserProxyExerciseExercise.create(user: user, exercise: matchingExercise, proxy_exercise: self)
          matchingExercise
        end
      recommendedExercise
    end

    def findMatchingExercise(user)
      exercises.shuffle.first
    end

    # [score][quantile]
    def scoring_matrix
      [
          [0  ,0  ,0  ,0  ,0  ],
          [0.2,0.2,0.2,0.2,0.1],
          [0.5,0.5,0.4,0.4,0.3],
          [0.6,0.6,0.5,0.5,0.4],
          [1  ,1  ,0.9,0.8,0.7],
      ]
    end

    def scoring_matrix_quantiles
      [0.2,0.4,0.6,0.8]
    end

    def score(user, ex)
      points_ratio =  ex.maximum_score(user) / ex.maximum_score.to_f
      if points_ratio == 0.0
        Rails.logger.debug("scoring user #{user.id} for exercise #{ex.id}: points_ratio=#{points_ratio} score: 0" )
        return 0.0
      end
      points_ratio_index = ((scoring_matrix.size - 1)  * points_ratio).to_i
      working_time_user = Time.parse(ex.average_working_time_for_only(user.id) || "00:00:00").seconds_since_midnight
      quantiles_working_time = ex.getQuantiles(scoring_matrix_quantiles)
      quantile_index = quantiles_working_time.size
      quantiles_working_time.each_with_index do |quantile_time, i|
        if working_time_user <= quantile_time
          quantile_index = i
          break
        end
      end
      Rails.logger.debug(
          "scoring user #{user.id} exercise #{ex.id}: worktime #{working_time_user}, points: #{points_ratio}" \
          "(index #{points_ratio_index}) quantiles #{quantiles_working_time} placed into quantile index #{quantile_index} " \
          "score: #{scoring_matrix[points_ratio_index][quantile_index]}")
      scoring_matrix[points_ratio_index][quantile_index]
    end

    def getRelativeKnowledgeLoss(user, exercises)
      # initialize knowledge for each tag with 0
      all_used_tags = exercises.inject(Set.new){|tagset, ex| tagset.merge(ex.tags)}
      topic_knowledge_loss_user = all_used_tags.map{|t| [t, 0]}.to_h
      topic_knowledge_max = all_used_tags.map{|t| [t, 0]}.to_h
      exercises.each do |ex|
        user_score_factor = score(user, ex)
        ex.tags.each do |t|
          tag_ratio = ex.exercise_tags.where(tag: t).first.factor / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }
          topic_knowledge = ex.expected_difficulty * tag_ratio
          topic_knowledge_loss_user[t] += (1 - user_score_factor) * topic_knowledge
          topic_knowledge_max[t] += topic_knowledge
        end
      end
      relative_loss = {}
      puts all_used_tags.size
      all_used_tags.each do |t|
        relative_loss[t] = topic_knowledge_loss_user[t] / topic_knowledge_max[t]
      end
      relative_loss
    end

end