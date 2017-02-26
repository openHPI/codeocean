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

    def get_matching_exercise(user)
      assigned_user_proxy_exercise = user_proxy_exercise_exercises.where(user: user).first
      recommended_exercise =
        if (assigned_user_proxy_exercise)
          Rails.logger.info("retrieved assigned exercise for user #{user.id}: Exercise #{assigned_user_proxy_exercise.exercise}" )
          assigned_user_proxy_exercise.exercise
        else
          Rails.logger.info("find new matching exercise for user #{user.id}" )
          matching_exercise = find_matching_exercise(user)
          user.user_proxy_exercise_exercises << UserProxyExerciseExercise.create(user: user, exercise: matching_exercise, proxy_exercise: self)
          matching_exercise
        end
      recommended_exercise
    end

    def find_matching_exercise(user)
      exercises_user_has_accessed = user.submissions.where("cause IN ('submit','assess')").map{|s| s.exercise}.uniq
      tags_user_has_seen = exercises_user_has_accessed.map{|ex| ex.tags}.uniq.flatten
      Rails.logger.info("exercises_user_has_accessed #{exercises_user_has_accessed.map{|e|e.id}.join(",")}")

      # find execises
      potential_recommended_exercises = []
      exercises.each do |ex|
        ## find exercises which have only tags the user has already seen
        if (ex.tags - tags_user_has_seen).empty?
          potential_recommended_exercises << ex
        end
      end
      Rails.logger.info("potential_recommended_exercises: #{potential_recommended_exercises.map{|e|e.id}}")
      # if all exercises contain tags which the user has never seen, recommend easiest exercise
      if potential_recommended_exercises.empty?
        select_easiest_exercise(exercises)
      else
        recommended_exercise = select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
        recommended_exercise
      end
    end

    def select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
      topic_knowledge_user_and_max = get_user_knowledge_and_max_knowledge(user, exercises_user_has_accessed)
      puts "topic_knowledge_user_and_max: #{topic_knowledge_user_and_max}"
      puts "potential_recommended_exercises: #{potential_recommended_exercises.size}: #{potential_recommended_exercises.map{|p| p.id}}"
      topic_knowledge_user = topic_knowledge_user_and_max[:user_topic_knowledge]
      topic_knowledge_max = topic_knowledge_user_and_max[:max_topic_knowledge]
      current_users_knowledge_lack = {}
      topic_knowledge_max.keys.each do |tag|
        current_users_knowledge_lack[tag] = topic_knowledge_user[tag] /  topic_knowledge_max[tag]
      end

      relative_knowledge_improvement = {}
      potential_recommended_exercises.each do |potex|
        tags =  potex.tags
        relative_knowledge_improvement[potex] = 0.0
        Rails.logger.info("review potential exercise #{potex.id}")
        tags.each do |tag|
          tag_ratio = potex.exercise_tags.where(tag: tag).first.factor.to_f / potex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          max_topic_knowledge_ratio = potex.expected_difficulty * tag_ratio
          old_relative_loss_tag = topic_knowledge_user[tag] / topic_knowledge_max[tag]
          new_relative_loss_tag = topic_knowledge_user[tag] / (topic_knowledge_max[tag] + max_topic_knowledge_ratio)
          puts "tag #{tag} old_relative_loss_tag #{old_relative_loss_tag}, new_relative_loss_tag #{new_relative_loss_tag}, tag_ratio #{tag_ratio}"
          relative_knowledge_improvement[potex] += old_relative_loss_tag - new_relative_loss_tag
        end
      end
      highest_difficulty_user_has_accessed =  exercises_user_has_accessed.map{|e| e.expected_difficulty}.sort.last || 0
      best_matching_exercise = find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
      Rails.logger.info("current users knowledge loss: " + current_users_knowledge_lack.map{|k,v| "#{k} => #{v}"}.to_s)
      Rails.logger.info("relative improvements #{relative_knowledge_improvement.map{|k,v| k.id.to_s + ':' + v.to_s}}")
      best_matching_exercise
    end

    def find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
      Rails.logger.info("select most appropiate exercise for user. his highest difficulty was #{highest_difficulty_user_has_accessed}")
      sorted_exercises = relative_knowledge_improvement.sort_by{|k,v| v}.reverse

      sorted_exercises.each do |ex,diff|
        Rails.logger.info("review exercise #{ex.id} diff: #{ex.expected_difficulty}")
        if (ex.expected_difficulty - highest_difficulty_user_has_accessed) <= 1
          Rails.logger.info("matched #{ex.id}")
          return ex
        else
          Rails.logger.info("ex #{ex.id} is too difficult")
        end
      end
      easiest_exercise = sorted_exercises.min_by{|k,v| v}.first
      Rails.logger.info("no match, select easiest exercise as fallback #{easiest_exercise.id}")
      easiest_exercise
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
      quantiles_working_time = ex.get_quantiles(scoring_matrix_quantiles)
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

    def get_relative_knowledge_loss(user, exercises)
      # initialize knowledge for each tag with 0
      all_used_tags = exercises.inject(Set.new){|tagset, ex| tagset.merge(ex.tags)}
      topic_knowledge_loss_user = all_used_tags.map{|t| [t, 0]}.to_h
      topic_knowledge_max = all_used_tags.map{|t| [t, 0]}.to_h
      exercises.each do |ex|
        user_score_factor = score(user, ex)
        ex.tags.each do |t|
          tag_ratio = ex.exercise_tags.where(tag: t).first.factor / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }
          max_topic_knowledge_ratio = ex.expected_difficulty * tag_ratio
          topic_knowledge_loss_user[t] += (1 - user_score_factor) * max_topic_knowledge_ratio
          topic_knowledge_max[t] += max_topic_knowledge_ratio
        end
      end
      relative_loss = {}
      all_used_tags.each do |t|
        relative_loss[t] = topic_knowledge_loss_user[t] / topic_knowledge_max[t]
      end
      relative_loss
    end

    def get_user_knowledge_and_max_knowledge(user, exercises)
      # initialize knowledge for each tag with 0
      all_used_tags = exercises.inject(Set.new){|tagset, ex| tagset.merge(ex.tags)}
      topic_knowledge_loss_user = all_used_tags.map{|t| [t, 0]}.to_h
      topic_knowledge_max = all_used_tags.map{|t| [t, 0]}.to_h
      exercises.each do |ex|
        Rails.logger.info("exercise: #{ex.id}: #{ex}")
        user_score_factor = score(user, ex)
        ex.tags.each do |t|
          tag_ratio = ex.exercise_tags.where(tag: t).first.factor.to_f / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          Rails.logger.info("tag: #{t}, factor: #{ex.exercise_tags.where(tag: t).first.factor}, sumall: #{ex.exercise_tags.inject(0){|sum, et| sum += et.factor }}")
          Rails.logger.info("tag_ratio #{tag_ratio}")
          topic_knowledge_ratio = ex.expected_difficulty * tag_ratio
          Rails.logger.info("topic_knowledge_ratio #{topic_knowledge_ratio}")
          topic_knowledge_loss_user[t] += (1 - user_score_factor) * topic_knowledge_ratio
          topic_knowledge_max[t] += topic_knowledge_ratio
        end
      end
      {user_topic_knowledge: topic_knowledge_loss_user, max_topic_knowledge: topic_knowledge_max}
    end

    def select_easiest_exercise(exercises)
      exercises.order(:expected_difficulty).first
    end

end