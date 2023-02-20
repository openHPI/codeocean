# frozen_string_literal: true

require 'rails_helper'

describe RequestForCommentPolicy do
  subject(:policy) { described_class }

  context 'when the RfC visibility is not considered' do
    let(:submission) { create(:submission, study_group: create(:study_group)) }
    let(:rfc) { create(:rfc, submission:, user: submission.user) }

    %i[destroy? edit?].each do |action|
      permissions(action) do
        it 'grants access to admins only' do
          expect(policy).to permit(build(:admin), rfc)
          %i[external_user teacher].each do |factory_name|
            expect(policy).not_to permit(create(factory_name), rfc)
          end
        end
      end
    end

    %i[create? index? my_comment_requests? rfcs_with_my_comments?].each do |action|
      permissions(action) do
        it 'grants access to everyone' do
          %i[external_user teacher admin].each do |factory_name|
            expect(policy).to permit(create(factory_name), rfc)
          end
        end
      end
    end

    permissions(:clear_question?) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), rfc)
      end

      it 'grants access to teachers in study group' do
        teacher = create(:teacher, study_groups: [rfc.submission.study_group])
        expect(policy).to permit(teacher, rfc)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), rfc)
        end
      end
    end
  end

  context 'when the RfC visibility is considered' do
    let(:user) { create(:learner, consumer:) }

    let(:rfc_other_consumer) do
      rfc = create(:rfc, user:)
      rfc.user.update(consumer: create(:consumer, name: 'Other Consumer'))
      rfc
    end

    let(:rfc_other_study_group) do
      rfc = create(:rfc, user:)
      rfc.user.update(consumer: user.consumer)
      rfc.submission.update(study_group: create(:study_group))
      rfc
    end

    let(:rfc_peer) do
      rfc = create(:rfc, user:)
      rfc.user.update(consumer: user.consumer)
      rfc.submission.update(study_group: user.study_groups.first)
      rfc
    end

    let(:all_rfcs) { [rfc_other_consumer, rfc_other_study_group, rfc_peer] }
    let(:same_consumer_rfcs) { [rfc_other_study_group, rfc_peer] }
    let(:other_study_groups_rfcs) { [rfc_other_consumer, rfc_other_study_group] }

    context 'when rfc_visibility is set to all' do
      let(:consumer) { create(:consumer, rfc_visibility: 'all') }

      permissions(:show?) do
        it 'grants access to everyone' do
          %i[external_user teacher admin].each do |factory_name|
            all_rfcs.each do |specific_rfc|
              expect(policy).to permit(create(factory_name, consumer:), specific_rfc)
            end
          end
        end
      end

      %i[mark_as_solved? set_thank_you_note?].each do |action|
        permissions(action) do
          it 'grants access to admins' do
            all_rfcs.each do |specific_rfc|
              expect(policy).to permit(create(:admin, consumer:), specific_rfc)
            end
          end

          it 'grants access to authors' do
            all_rfcs.each do |specific_rfc|
              expect(policy).to permit(specific_rfc.author, specific_rfc)
            end
          end

          it 'does not grant access to all other users' do
            %i[external_user teacher].each do |factory_name|
              all_rfcs.each do |specific_rfc|
                expect(policy).not_to permit(create(factory_name, consumer:), specific_rfc)
              end
            end
          end
        end
      end
    end

    context 'when rfc_visibility is set to consumer' do
      let(:consumer) { create(:consumer, rfc_visibility: 'consumer') }

      permissions(:show?) do
        it 'grants access to admins' do
          all_rfcs.each do |specific_rfc|
            expect(policy).to permit(create(:admin, consumer:), specific_rfc)
          end
        end

        it 'grants access to users from the same consumer' do
          %i[external_user teacher].each do |factory_name|
            same_consumer_rfcs.each do |specific_rfc|
              expect(policy).to permit(create(factory_name, consumer:), specific_rfc)
            end
          end
        end

        it 'does not grant access to users from other consumers' do
          %i[external_user teacher].each do |factory_name|
            expect(policy).not_to permit(create(factory_name, consumer:), rfc_other_consumer)
          end
        end
      end

      # Testing `mark_as_solved?` and `set_thank_you_note?` is not necessary here,
      # because an author of an RfC can only be a user from the same consumer.
    end

    context 'when rfc_visibility is set to study_group' do
      let(:consumer) { create(:consumer, rfc_visibility: 'study_group') }

      permissions(:show?) do
        it 'grants access to admins' do
          all_rfcs.each do |specific_rfc|
            expect(policy).to permit(create(:admin, consumer:), specific_rfc)
          end
        end

        it 'grants access to users from the same study group' do
          %i[external_user teacher].each do |factory_name|
            expect(policy).to permit(create(factory_name, consumer:, study_groups: [rfc_peer.submission.study_group]), rfc_peer)
          end
        end

        it 'does not grant access to users from other consumers' do
          %i[external_user teacher].each do |factory_name|
            other_study_groups_rfcs.each do |specific_rfc|
              expect(policy).not_to permit(create(factory_name, consumer:), specific_rfc)
            end
          end
        end
      end

      %i[mark_as_solved? set_thank_you_note?].each do |action|
        permissions(action) do
          it 'grants access to admins' do
            all_rfcs.each do |specific_rfc|
              expect(policy).to permit(create(:admin, consumer:), specific_rfc)
            end
          end

          # Testing `mark_as_solved?` and `set_thank_you_note?` with another consumer is not
          # necessary here, because an author of an RfC can only be a user from the same consumer.

          it 'grants access to authors of the same primary study group' do
            rfc_peer.author.update(study_groups: [rfc_peer.submission.study_group])
            expect(policy).to permit(rfc_peer.author, rfc_peer)
          end

          it 'does not grant access to authors of another primary study groups' do
            rfc_other_study_group.author.update(study_groups: [create(:study_group)])
            expect(policy).not_to permit(rfc_other_study_group.author, rfc_other_study_group)
          end

          it 'does not grant access to all other users' do
            %i[external_user teacher].each do |factory_name|
              all_rfcs.each do |specific_rfc|
                expect(policy).not_to permit(create(factory_name, consumer:), specific_rfc)
              end
            end
          end
        end
      end
    end
  end
end
