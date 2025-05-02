CREATE OR REPLACE FUNCTION migrate_external_user(target_user int, duplicated_user int)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE

BEGIN
    IF target_user = duplicated_user THEN
        RETURN;
    END IF;

    IF EXISTS(SELECT 1
              FROM programming_group_memberships a
                       JOIN programming_group_memberships b ON a.programming_group_id = b.programming_group_id AND a.user_id != b.user_id
              WHERE (a.user_id = target_user AND b.user_id = duplicated_user)
                 OR (a.user_id = duplicated_user AND b.user_id = target_user)) THEN
        RAISE NOTICE 'User % is already in the same programming group as user %', target_user, duplicated_user;
        RETURN;
    END IF;

    WITH existing_anomaly_notifications AS (SELECT CONCAT(exercise_id, '_', exercise_collection_id) as existing
        FROM anomaly_notifications
        WHERE contributor_id = target_user AND contributor_type = 'ExternalUser')
    DELETE FROM anomaly_notifications WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser'
      AND CONCAT(exercise_id, '_', exercise_collection_id) IN (SELECT existing FROM existing_anomaly_notifications);

    UPDATE anomaly_notifications SET contributor_id = target_user WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser';
    UPDATE authentication_tokens SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    WITH existing_codeharbor_link AS (SELECT TRUE as existing
        FROM codeharbor_links
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM codeharbor_links
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND TRUE IN (SELECT existing FROM existing_codeharbor_link);

    UPDATE codeharbor_links SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE comments SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE community_solution_contributions SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE community_solution_locks SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE events SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE events_synchronized_editor SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE execution_environments SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE exercise_collections SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE exercises SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE file_types SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    WITH existing_lti_parameters AS (SELECT CONCAT(exercise_id, '_', study_group_id) as existing
        FROM lti_parameters
        WHERE external_user_id = target_user)
    DELETE FROM lti_parameters
    WHERE external_user_id = duplicated_user
      AND CONCAT(exercise_id, '_', study_group_id) IN (SELECT existing FROM existing_lti_parameters);

    UPDATE lti_parameters SET external_user_id = target_user WHERE external_user_id = duplicated_user;

    WITH existing_pair_programming_exercise_feedbacks AS (SELECT CONCAT(exercise_id, '_', study_group_id, '_', programming_group_id) as existing
        FROM pair_programming_exercise_feedbacks
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM pair_programming_exercise_feedbacks
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND CONCAT(exercise_id, '_', study_group_id, '_', programming_group_id) IN
          (SELECT existing FROM existing_pair_programming_exercise_feedbacks);

    UPDATE pair_programming_exercise_feedbacks SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    WITH existing_pair_programming_waiting_users AS (SELECT exercise_id as existing
        FROM pair_programming_waiting_users
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM pair_programming_waiting_users
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND exercise_id IN (SELECT existing FROM existing_pair_programming_waiting_users);

    UPDATE pair_programming_waiting_users SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE programming_group_memberships SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE proxy_exercises SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE remote_evaluation_mappings SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE request_for_comments SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    WITH existing_runners AS (SELECT execution_environment_id as existing
        FROM runners
        WHERE contributor_id = target_user AND contributor_type = 'ExternalUser')
    DELETE
    FROM runners
    WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser'
      AND execution_environment_id IN (SELECT existing FROM existing_runners);

    UPDATE runners SET contributor_id = target_user WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser';
    UPDATE searches SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    WITH existing_study_group_memberships AS (SELECT study_group_id as existing
        FROM study_group_memberships
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM study_group_memberships
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND study_group_id IN (SELECT existing FROM existing_study_group_memberships);

    UPDATE study_group_memberships SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE submissions SET contributor_id = target_user WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser';

    WITH existing_subscriptions AS (SELECT request_for_comment_id as existing
        FROM subscriptions
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM subscriptions
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND request_for_comment_id IN (SELECT existing FROM existing_subscriptions);

    -- We don't care about the subscription_type nor deleted flag here.
    UPDATE subscriptions SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE testruns SET user_id = target_user WHERE user_id = duplicated_user;
    UPDATE tips SET user_id = target_user WHERE user_id = duplicated_user;

    WITH existing_user_exercise_feedbacks AS (SELECT exercise_id as existing
        FROM user_exercise_feedbacks
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM user_exercise_feedbacks
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND exercise_id IN (SELECT existing FROM existing_user_exercise_feedbacks);

    UPDATE user_exercise_feedbacks SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';
    UPDATE user_exercise_interventions SET contributor_id = target_user WHERE contributor_id = duplicated_user AND contributor_type = 'ExternalUser';

    WITH existing_user_proxy_exercise_exercises AS (SELECT proxy_exercise_id as existing
        FROM user_proxy_exercise_exercises
        WHERE user_id = target_user AND user_type = 'ExternalUser')
    DELETE FROM user_proxy_exercise_exercises
    WHERE user_id = duplicated_user AND user_type = 'ExternalUser'
      AND proxy_exercise_id IN (SELECT existing FROM existing_user_proxy_exercise_exercises);

    UPDATE user_proxy_exercise_exercises SET user_id = target_user WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    -- Passkeys need to be set up again.
    DELETE FROM webauthn_credentials WHERE user_id = duplicated_user AND user_type = 'ExternalUser';

    DELETE FROM external_users WHERE ID = duplicated_user;
END;
$$;

/* Execute migration
do $$
begin
    perform migrate_external_user(target_user := 63783, duplicated_user := 63784);
end
$$;
*/
