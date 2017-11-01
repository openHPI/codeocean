class ProxyExercise < ActiveRecord::Base

    after_initialize :generate_token
    after_initialize :set_reason

    has_and_belongs_to_many :exercises
    has_many :user_proxy_exercise_exercises

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
          Rails.logger.debug("retrieved assigned exercise for user #{user.id}: Exercise #{assigned_user_proxy_exercise.exercise}" )
          assigned_user_proxy_exercise.exercise
        else
          Rails.logger.debug("find new matching exercise for user #{user.id}" )
          matching_exercise =
              begin
                find_matching_exercise(user)
              rescue => e #fallback
                Rails.logger.error("finding matching exercise failed. Fall back to random exercise! Error: #{$!}" )
                @reason[:reason] = "fallback because of error"
                @reason[:error] = "#{$!}:\n\t#{e.backtrace.join("\n\t")}"
                exercises.where("expected_difficulty > 1").shuffle.first # difficulty should be > 1 to prevent dummy exercise from being chosen.
              end
          user.user_proxy_exercise_exercises << UserProxyExerciseExercise.create(user: user, exercise: matching_exercise, proxy_exercise: self, reason: @reason.to_json)
          matching_exercise
        end
      recommended_exercise
    end

    def find_matching_exercise(user)
      user_group = UserGroupSeparator.getProxyExerciseGroup(user)
      case user_group
        when :dummy_assigment
          rec_ex = select_easiest_exercise(exercises)
          @reason[:reason] = "dummy group"
          Rails.logger.debug("assigned user to dummy group, and gave him exercise: #{rec_ex.title}")
          rec_ex
        when :random_assigment
          @reason[:reason] = "random group"
          ex = exercises.where("expected_difficulty > 1").shuffle.first
          Rails.logger.debug("assigned user to random group, and gave him exercise: #{ex.title}")
          ex
        when :recommended_assignment
          exercises_user_has_accessed = user.submissions.where("cause IN ('submit','assess')").map{|s| s.exercise}.uniq.compact
          tags_user_has_seen = exercises_user_has_accessed.map{|ex| ex.tags}.uniq.flatten
          Rails.logger.debug("exercises_user_has_accessed #{exercises_user_has_accessed.map{|e|e.id}.join(",")}")

          # find exercises
          potential_recommended_exercises = []
          exercises.where("expected_difficulty >= 1").each do |ex|
            ## find exercises which have only tags the user has already seen
            if (ex.tags - tags_user_has_seen).empty?
              potential_recommended_exercises << ex
            end
          end
          Rails.logger.debug("potential_recommended_exercises: #{potential_recommended_exercises.map{|e|e.id}}")
          # if all exercises contain tags which the user has never seen, recommend easiest exercise
          if potential_recommended_exercises.empty?
            Rails.logger.debug("matched easiest exercise in pool")
            @reason[:reason] = "easiest exercise in pool. empty potential exercises"
            select_easiest_exercise(exercises)
          else
            select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
          end
      end

    end
    private :find_matching_exercise

    def select_best_matching_exercise(user, exercises_user_has_accessed, potential_recommended_exercises)
      topic_knowledge_user_and_max = get_user_knowledge_and_max_knowledge(user, exercises_user_has_accessed)
      Rails.logger.debug("topic_knowledge_user_and_max: #{topic_knowledge_user_and_max}")
      Rails.logger.debug("potential_recommended_exercises: #{potential_recommended_exercises.size}: #{potential_recommended_exercises.map{|p| p.id}}")
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
        Rails.logger.debug("review potential exercise #{potex.id}")
        tags.each do |tag|
          tag_ratio = potex.exercise_tags.where(tag: tag).first.factor.to_f / potex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          max_topic_knowledge_ratio = potex.expected_difficulty * tag_ratio
          old_relative_loss_tag = topic_knowledge_user[tag] / topic_knowledge_max[tag]
          new_relative_loss_tag = topic_knowledge_user[tag] / (topic_knowledge_max[tag] + max_topic_knowledge_ratio)
          Rails.logger.debug("tag #{tag} old_relative_loss_tag #{old_relative_loss_tag}, new_relative_loss_tag #{new_relative_loss_tag}, tag_ratio #{tag_ratio}")
          relative_knowledge_improvement[potex] += old_relative_loss_tag - new_relative_loss_tag
        end
      end

      highest_difficulty_user_has_accessed =  exercises_user_has_accessed.map{|e| e.expected_difficulty}.sort.last || 0
      best_matching_exercise = find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
      @reason[:reason] = "best matching exercise"
      @reason[:highest_difficulty_user_has_accessed] = highest_difficulty_user_has_accessed
      @reason[:current_users_knowledge_lack] = current_users_knowledge_lack
      @reason[:relative_knowledge_improvement] = relative_knowledge_improvement

      Rails.logger.debug("current users knowledge loss: " + current_users_knowledge_lack.map{|k,v| "#{k} => #{v}"}.to_s)
      Rails.logger.debug("relative improvements #{relative_knowledge_improvement.map{|k,v| k.id.to_s + ':' + v.to_s}}")
      best_matching_exercise
    end
    private :select_best_matching_exercise

    def find_best_exercise(relative_knowledge_improvement, highest_difficulty_user_has_accessed)
      Rails.logger.debug("select most appropiate exercise for user. his highest difficulty was #{highest_difficulty_user_has_accessed}")
      sorted_exercises = relative_knowledge_improvement.sort_by{|k,v| v}.reverse

      sorted_exercises.each do |ex,diff|
        Rails.logger.debug("review exercise #{ex.id} diff: #{ex.expected_difficulty}")
        if (ex.expected_difficulty - highest_difficulty_user_has_accessed) <= 1
          Rails.logger.debug("matched exercise #{ex.id}")
          return ex
        else
          Rails.logger.debug("exercise #{ex.id} is too difficult")
        end
      end
      easiest_exercise = sorted_exercises.min_by{|k,v| v}.first
      Rails.logger.debug("no match, select easiest exercise as fallback #{easiest_exercise.id}")
      easiest_exercise
    end
    private :find_best_exercise

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
    private :scoring_matrix_quantiles

    def score(user, ex)
      max_score = ex.maximum_score.to_f
      if max_score <= 0
        Rails.logger.debug("scoring user #{user.id} for exercise #{ex.id}:  score: 0" )
        return 0.0
      end
      points_ratio = ex.maximum_score(user) / max_score
      if points_ratio == 0.0
        Rails.logger.debug("scoring user #{user.id} for exercise #{ex.id}: points_ratio=#{points_ratio} score: 0" )
        return 0.0
      end
      points_ratio_index = ((scoring_matrix.size - 1)  * points_ratio).to_i
      working_time_user = ex.accumulated_working_time_for_only(user)
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
      tags_counter = all_used_tags_with_count.keys.map{|tag| [tag,0]}.to_h
      topic_knowledge_loss_user = all_used_tags_with_count.keys.map{|t| [t, 0]}.to_h
      topic_knowledge_max = all_used_tags_with_count.keys.map{|t| [t, 0]}.to_h
      exercises_sorted = exercises.sort_by { |ex| ex.time_maximum_score(user)}
      exercises_sorted.each do |ex|
        Rails.logger.debug("exercise: #{ex.id}: #{ex}")
        user_score_factor = score(user, ex)
        ex.tags.each do |t|
          tags_counter[t] += 1
          tag_diminishing_return_factor = tag_diminishing_return_function(tags_counter[t], all_used_tags_with_count[t])
          tag_ratio = ex.exercise_tags.where(tag: t).first.factor.to_f / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          Rails.logger.debug("tag: #{t}, factor: #{ex.exercise_tags.where(tag: t).first.factor}, sumall: #{ex.exercise_tags.inject(0){|sum, et| sum += et.factor }}")
          Rails.logger.debug("tag #{t}, count #{tags_counter[t]}, max: #{all_used_tags_with_count[t]}, factor: #{tag_diminishing_return_factor}")
          Rails.logger.debug("tag_ratio #{tag_ratio}")
          topic_knowledge_ratio = ex.expected_difficulty * tag_ratio
          Rails.logger.debug("topic_knowledge_ratio #{topic_knowledge_ratio}")
          topic_knowledge_loss_user[t] += (1 - user_score_factor) * topic_knowledge_ratio * tag_diminishing_return_factor
          topic_knowledge_max[t] += topic_knowledge_ratio * tag_diminishing_return_factor
        end
      end
      {user_topic_knowledge: topic_knowledge_loss_user, max_topic_knowledge: topic_knowledge_max}
    end
    private :get_user_knowledge_and_max_knowledge

    def tag_diminishing_return_function(count_tag, total_count_tag)
      total_count_tag += 1 # bonus exercise comes on top
      return 1/(1+(Math::E**(-3/(0.5*total_count_tag)*(count_tag-0.5*total_count_tag))))
    end

    def select_easiest_exercise(exercises)
      exercises.order(:expected_difficulty).first
    end

end
