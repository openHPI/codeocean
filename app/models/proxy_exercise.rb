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

    def score(user, ex)
      1
    end

    def getRelativeKnowledgeLoss(user, execises)
      # initialize knowledge for each tag with 0
      topic_knowledge_loss_user = Tag.all.map{|t| [t, 0]}.to_h
      topic_knowledge_max = Tag.all.map{|t| [t, 0]}.to_h
      execises.each do |ex|
        score = score(user, ex)
        ex.tags.each do |t|
          tag_ratio = ex.exercise_tags.where(tag: t).factor / ex.exercise_tags.inject(0){|sum, et| sum += et.factor }
          topic_knowledge = ex.expected_difficulty * tag_ratio
          topic_knowledge_loss_user[t] += (1-score) * topic_knowledge
          topic_knowledge_max[t] += topic_knowledge
        end
      end
      relative_loss = {}
      topic_knowledge_max.keys.each do |t|
        relative_loss[t] = topic_knowledge_loss_user[t] / topic_knowledge_max[t]
      end
      relative_loss
    end

end