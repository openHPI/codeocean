CREATE OR REPLACE FUNCTION migrate_study_group(target_study_group int, duplicated_study_group int)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE

BEGIN
    IF target_study_group = duplicated_study_group THEN
        RETURN;
    END IF;

    UPDATE authentication_tokens SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE community_solution_contributions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE events SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE events_synchronized_editor SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;

    WITH existing_lti_parameters AS (SELECT CONCAT(exercise_id, '_', external_user_id) as existing
        FROM lti_parameters
        WHERE study_group_id = target_study_group)
    DELETE FROM lti_parameters
    WHERE study_group_id = duplicated_study_group
      AND CONCAT(exercise_id, '_', external_user_id) IN (SELECT existing FROM existing_lti_parameters);

    UPDATE lti_parameters SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;

    WITH existing_pair_programming_exercise_feedbacks
    AS (SELECT CONCAT(exercise_id, '_', user_type, '_', user_id, '_', programming_group_id) as existing
        FROM pair_programming_exercise_feedbacks
        WHERE study_group_id = target_study_group)
    DELETE FROM pair_programming_exercise_feedbacks
    WHERE study_group_id = duplicated_study_group
      AND CONCAT(exercise_id, '_', user_type, '_', user_id, '_', programming_group_id) IN
          (SELECT existing FROM existing_pair_programming_exercise_feedbacks);

    UPDATE pair_programming_exercise_feedbacks SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE remote_evaluation_mappings SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE submissions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;

    WITH existing_subscriptions AS (SELECT CONCAT(request_for_comment_id, '_', user_type, '_', user_id) as existing
        FROM subscriptions
        WHERE study_group_id = target_study_group)
    DELETE FROM subscriptions
    WHERE study_group_id = duplicated_study_group
      AND CONCAT(request_for_comment_id, '_', user_type, '_', user_id) IN (SELECT existing FROM existing_subscriptions);

    -- We don't care about the subscription_type nor deleted flag here.
    UPDATE subscriptions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;

    -- Preventing duplicated entries in study_group_memberships
    -- The same study group should not have two entries for the same user.
    DELETE
    FROM study_group_memberships
    WHERE study_group_id = duplicated_study_group
      AND id IN (SELECT duplicated.id
                                FROM study_group_memberships AS target,
                                     study_group_memberships AS duplicated
                                WHERE target.study_group_id = target_study_group
                                  AND duplicated.study_group_id = duplicated_study_group
                                  AND target.user_id = duplicated.user_id
                                  AND target.user_type = duplicated.user_type);
    UPDATE study_group_memberships SET study_group_id = target_study_group where study_group_id = duplicated_study_group;

    DELETE FROM study_groups WHERE id = duplicated_study_group;
END;
$$;

/* Execute migration
do $$
begin
    perform migrate_study_group(target_study_group := 237, duplicated_study_group := 695);
end
$$;
*/
