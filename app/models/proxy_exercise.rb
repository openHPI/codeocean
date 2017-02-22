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

    def getMatchingExercise(user)
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
      #exercises.shuffle.first
      exercisesUserHasAccessed = user.submissions.where(cause: :assess).map{|s| s.exercise}.uniq
      tagsUserHasSeen = exercisesUserHasAccessed.map{|ex| ex.tags}.uniq.flatten
      puts "exercisesUserHasAccessed #{exercisesUserHasAccessed}"


      # find execises
      potentialRecommendedExercises = []
      exercises.each do |ex|
        ## find exercises which have tags the user has already seen
        if (ex.tags - tagsUserHasSeen).empty?
          potentialRecommendedExercises << ex
        end
      end
      puts "potentialRecommendedExercises: #{potentialRecommendedExercises}"
      recommendedExercise = selectBestMatchingExercise(user, exercisesUserHasAccessed, potentialRecommendedExercises)
      recommendedExercise
    end

    def selectBestMatchingExercise(user, exercisesUserHasAccessed, potentialRecommendedExercises)
      topic_knowledge_user_and_max = getUserKnowledgeAndMaxKnowledge(user, exercisesUserHasAccessed)
      puts "topic_knowledge_user_and_max: #{topic_knowledge_user_and_max}"
      puts "potentialRecommendedExercises: #{potentialRecommendedExercises.size}"
      topic_knowledge_user = topic_knowledge_user_and_max[:user_topic_knowledge]
      topic_knowledge_max = topic_knowledge_user_and_max[:max_topic_knowledge]
      relative_knowledge_improvement = {}
      potentialRecommendedExercises.each do |potex|
        tags =  potex.tags
        relative_knowledge_improvement[potex] = 0.0
        puts "potex #{potex}"
        tags.each do |tag|
          tag_ratio = potex.exercise_tags.where(tag: tag).first.factor.to_f / potex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          max_topic_knowledge_ratio = potex.expected_difficulty * tag_ratio
          old_relative_loss_tag = topic_knowledge_user[tag] / topic_knowledge_max[tag]
          new_relative_loss_tag = topic_knowledge_user[tag] / (topic_knowledge_max[tag] + max_topic_knowledge_ratio)
          puts "tag #{tag} old_relative_loss_tag #{old_relative_loss_tag}, new_relative_loss_tag #{new_relative_loss_tag}, max_topic_knowledge_ratio #{max_topic_knowledge_ratio} tag_ratio #{tag_ratio}"
          relative_knowledge_improvement[potex] += old_relative_loss_tag - new_relative_loss_tag
        end
      end
      puts "relative improvements #{relative_knowledge_improvement}"
      exercise_with_greatest_improvements = relative_knowledge_improvement.max_by{|k,v| v}
      exercise_with_greatest_improvements.first
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
      puts points_ratio
      puts ex.maximum_score.to_f
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

    def getUserKnowledgeAndMaxKnowledge(user, exercises)
      # initialize knowledge for each tag with 0
      all_used_tags = exercises.inject(Set.new){|tagset, ex| tagset.merge(ex.tags)}
      topic_knowledge_loss_user = all_used_tags.map{|t| [t, 0]}.to_h
      topic_knowledge_max = all_used_tags.map{|t| [t, 0]}.to_h
      exercises.each do |ex|
        puts "exercise: #{ex}"
        user_score_factor = score(user, ex)
        ex.tags.each do |t|
          tag_ratio = ex.exercise_tags.where(tag: t).first.factor.to_f / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }.to_f
          puts "tag: #{t}, factor: #{ex.exercise_tags.where(tag: t).first.factor}, sumall: #{ex.exercise_tags.inject(0){|sum, et| sum += et.factor }}"
          puts "tag_ratio #{tag_ratio}"
          topic_knowledge_ratio = ex.expected_difficulty * tag_ratio
          puts "topic_knowledge_ratio #{topic_knowledge_ratio}"
          topic_knowledge_loss_user[t] += (1 - user_score_factor) * topic_knowledge_ratio
          topic_knowledge_max[t] += topic_knowledge_ratio
        end
      end
      {user_topic_knowledge: topic_knowledge_loss_user, max_topic_knowledge: topic_knowledge_max}
    end

end