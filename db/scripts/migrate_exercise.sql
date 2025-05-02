CREATE OR REPLACE FUNCTION migrate_exercise(target_exercise int, duplicated_exercise int)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE

BEGIN
    IF target_exercise = duplicated_exercise THEN
        RETURN;
    END IF;

    IF EXISTS(SELECT 1
              FROM exercise_tips
              WHERE exercise_id = duplicated_exercise) THEN
        RAISE NOTICE 'Exercise % has tips. Please migrate tips manually and try again', duplicated_exercise;
        RETURN;
    END IF;

    IF EXISTS(SELECT 1
              FROM community_solutions
              WHERE exercise_id = duplicated_exercise) THEN
        RAISE NOTICE 'Exercise % has a community solution. Please migrate the community solution and their contribution (locks) manually and try again', duplicated_exercise;
        RETURN;
    END IF;

    IF EXISTS(SELECT 1
              FROM programming_groups a, programming_groups b
              WHERE (a.exercise_id = target_exercise AND b.exercise_id = duplicated_exercise)
              OR (a.exercise_id = duplicated_exercise AND b.exercise_id = target_exercise)) THEN
        RAISE NOTICE 'Both, exercise % and % have programming groups. Please re-consider the effects (and change the script).', target_exercise, duplicated_exercise;
        RETURN;
    END IF;

    UPDATE programming_groups SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;
    UPDATE submissions SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;
    UPDATE request_for_comments SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;

    WITH rename_candidates AS (
        SELECT target.name, target.id AS target_id, duplicated.id AS duplicated_id
        FROM files AS target
                 INNER JOIN files AS duplicated ON target.name = duplicated.name
        WHERE target.context_id = target_exercise
          AND target.context_type = 'Exercise'
          AND target.read_only = FALSE
          AND duplicated.context_id = duplicated_exercise
          AND duplicated.context_type = 'Exercise'
          AND duplicated.read_only = FALSE
    ),
         files_mapping AS (
             SELECT files.id, rename_candidates.target_id
             FROM files
                      INNER JOIN rename_candidates ON file_id = duplicated_id)
    UPDATE files
    SET file_id = files_mapping.target_id
    FROM files_mapping
    WHERE files.id = files_mapping.id;

    UPDATE events SET exercise_id = target_exercise where exercise_id = duplicated_exercise;
    UPDATE searches SET exercise_id = target_exercise where exercise_id = duplicated_exercise;
    UPDATE user_exercise_interventions SET exercise_id = target_exercise where exercise_id = duplicated_exercise;

    WITH existing_user_proxy_exercise_exercises AS (SELECT CONCAT(user_type, '_', user_id, '_', proxy_exercise_id) as existing
        FROM user_proxy_exercise_exercises
        WHERE exercise_id = target_exercise)
    DELETE FROM user_proxy_exercise_exercises
    WHERE exercise_id = duplicated_exercise
      AND CONCAT(user_type, '_', user_id, '_', proxy_exercise_id) IN (SELECT existing FROM existing_user_proxy_exercise_exercises);

    UPDATE user_proxy_exercise_exercises SET exercise_id = target_exercise where exercise_id = duplicated_exercise;

    WITH existing_anomaly_notifications AS (SELECT CONCAT(contributor_type, '_', contributor_id, '_', exercise_collection_id) as existing
        FROM anomaly_notifications
        WHERE exercise_id = target_exercise)
    DELETE FROM anomaly_notifications WHERE exercise_id = duplicated_exercise
      AND CONCAT(contributor_type, '_', contributor_id, '_', exercise_collection_id) IN (SELECT existing FROM existing_anomaly_notifications);

    UPDATE anomaly_notifications SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;

    WITH existing_exercise_tags AS (SELECT tag_id as existing
        FROM exercise_tags
        WHERE exercise_id = tag_id)
    DELETE FROM exercise_tags
    WHERE tag_id = duplicated_exercise
      AND tag_id IN (SELECT existing FROM existing_exercise_tags);

    UPDATE exercise_tags SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;

    WITH existing_lti_parameters AS (SELECT CONCAT(external_user_id, '_', study_group_id) as existing
                                     FROM lti_parameters
                                     WHERE exercise_id = target_exercise)
    DELETE FROM lti_parameters
    WHERE exercise_id = duplicated_exercise
      AND CONCAT(external_user_id, '_', study_group_id) IN (SELECT existing FROM existing_lti_parameters);

    UPDATE lti_parameters SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;

    WITH existing_pair_programming_exercise_feedbacks
    AS (SELECT CONCAT(user_type, '_', user_id, '_', study_group_id, '_', programming_group_id) as existing
        FROM pair_programming_exercise_feedbacks
        WHERE exercise_id = target_exercise)
    DELETE FROM pair_programming_exercise_feedbacks
    WHERE exercise_id = duplicated_exercise
      AND CONCAT(user_type, '_', user_id, '_', study_group_id, '_', programming_group_id) IN
          (SELECT existing FROM existing_pair_programming_exercise_feedbacks);

    UPDATE pair_programming_exercise_feedbacks SET exercise_id = target_exercise WHERE user_id = duplicated_exercise;

    WITH existing_pair_programming_waiting_users AS (SELECT CONCAT(user_type, '_', user_id) as existing
        FROM pair_programming_waiting_users
        WHERE exercise_id = target_exercise)
    DELETE FROM pair_programming_waiting_users
    WHERE exercise_id = duplicated_exercise
      AND CONCAT(user_type, '_', user_id) IN (SELECT existing FROM existing_pair_programming_waiting_users);

    UPDATE pair_programming_waiting_users SET exercise_id = target_exercise WHERE exercise_id = duplicated_exercise;

    -- We need to invalidate the remove evaluation mappings for the duplicated exercise, since the local file mapping (within the `.co` file) is broken otherwise.
    DELETE FROM remote_evaluation_mappings WHERE exercise_id = duplicated_exercise;

    -- Preventing duplicated entries in exercise_collection_items
    -- An exercise should not be present twice in an exercise collection.
    DELETE
    FROM exercise_collection_items
    WHERE id IN (SELECT duplicated.id
                 FROM exercise_collection_items AS target,
                      exercise_collection_items AS duplicated
                 WHERE target.exercise_id = target_exercise
                   AND duplicated.exercise_id = duplicated_exercise
                   AND target.exercise_collection_id = duplicated.exercise_collection_id);
    UPDATE exercise_collection_items SET exercise_id = target_exercise where exercise_id = duplicated_exercise;

    -- Preventing duplicated entries in exercises_proxy_exercises
    -- The same proxy exercise should not have two entries for the same exercise it proxies.
    DELETE
    FROM exercises_proxy_exercises
    WHERE exercise_id = duplicated_exercise
      AND proxy_exercise_id IN (SELECT duplicated.proxy_exercise_id
                                FROM exercises_proxy_exercises AS target,
                                     exercises_proxy_exercises AS duplicated
                                WHERE target.exercise_id = target_exercise
                                  AND duplicated.exercise_id = duplicated_exercise
                                  AND target.proxy_exercise_id = duplicated.proxy_exercise_id);
    UPDATE exercises_proxy_exercises SET exercise_id = target_exercise where exercise_id = duplicated_exercise;

    -- Preventing duplicated entries in user_exercise_feedbacks
    -- An exercise should not have two feedbacks from the same user.
    DELETE
    FROM user_exercise_feedbacks
    WHERE id IN (SELECT target.id
                 FROM user_exercise_feedbacks AS target,
                      user_exercise_feedbacks AS duplicated
                 WHERE target.exercise_id = target_exercise
                   AND duplicated.exercise_id = duplicated_exercise
                   AND target.user_id = duplicated.user_id
                   AND target.user_type = duplicated.user_type);
    UPDATE user_exercise_feedbacks SET exercise_id = target_exercise where exercise_id = duplicated_exercise;

    DELETE FROM files WHERE context_id = duplicated_exercise and context_type = 'Exercise';
    DELETE FROM exercises WHERE id = duplicated_exercise;

END;
$$;

/* Execute migration
do $$
begin
    perform migrate_exercise(target_exercise := 237, duplicated_exercise := 695);
end
$$;
*/
