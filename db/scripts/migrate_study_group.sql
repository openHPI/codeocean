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

    UPDATE community_solution_contributions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE remote_evaluation_mappings SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE authentication_tokens SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE subscriptions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;
    UPDATE submissions SET study_group_id = target_study_group WHERE study_group_id = duplicated_study_group;

    -- Preventing duplicated entries in exercises_proxy_exercises
    -- The same proxy exercise should not have two entries for the same exercise it proxies.
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
