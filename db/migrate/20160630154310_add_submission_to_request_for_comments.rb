# frozen_string_literal: true

class AddSubmissionToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_reference :request_for_comments, :submission

    up_only do
      execute <<-SQL.squish
        UPDATE request_for_comments
        SET submission_id = sub.submission_id_external
        FROM
        (SELECT s.id AS submission_id_external,
                        rfc.id AS rfc_id,
                                  s.created_at AS submission_created_at,
                                                  rfc.created_at AS rfc_crea
        FROM submissions s,
                         request_for_comments rfc
        WHERE s.user_id = rfc.user_id
        AND s.exercise_id = rfc.exercise_id
        AND rfc.created_at + interval '2 hours' > s.created_at
        AND s.created_at =
                (SELECT MAX(created_at)
                FROM submissions
                WHERE exercise_id = s.exercise_id
                AND user_id = s.user_id
                AND rfc.created_at + interval '2 hours' > created_at
                GROUP BY s.exercise_id,
                         s.user_id)) as sub
        WHERE id = sub.rfc_id
        AND submission_id IS NULL;
      SQL
    end
  end
end
