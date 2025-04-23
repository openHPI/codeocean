# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestForCommentPolicy do
  subject(:policy) { described_class }

  context 'when the RfC visibility is not considered' do
    let(:submission) { create(:submission, study_group: create(:study_group)) }
    let(:rfc) { create(:rfc, submission:, user: submission.contributor) }

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
    shared_examples 'grants access to everyone' do
      it 'grants access to everyone' do
        %i[external_user teacher admin].each do |factory_name|
          expect(policy).to permit(create(factory_name, consumer: viewer_consumer, study_groups: viewer_study_groups), rfc)
        end
      end

      it 'grants access to authors' do
        expect(policy).to permit(rfc.author, rfc)
      end

      it 'grant access to other authors of the programming group' do
        rfc.submission.update(contributor: programming_group)
        expect(policy).to permit(viewer_other_group_member, rfc)
      end
    end

    shared_examples 'grants access to admins and authors only' do
      it 'grants access to admins' do
        expect(policy).to permit(create(:admin, consumer: viewer_consumer, study_groups: viewer_study_groups), rfc)
      end

      it 'grants access to authors' do
        expect(policy).to permit(rfc.author, rfc)
      end

      it 'grant access to other authors of the programming group' do
        rfc.submission.update(contributor: programming_group)
        expect(policy).to permit(viewer_other_group_member, rfc)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name, consumer: viewer_consumer, study_groups: viewer_study_groups), rfc)
        end
      end
    end

    let(:rfc_author) { create(:learner, consumer: author_consumer, study_groups: author_study_groups) }
    let(:author_study_groups) { create_list(:study_group, 1, consumer: author_consumer) }
    let(:rfc) { create(:rfc, user: rfc_author) }

    let(:viewer_other_group_member) { create(:external_user, consumer: viewer_consumer) }
    let(:programming_group) { create(:programming_group, exercise: rfc.submission.exercise, users: [rfc.author, viewer_other_group_member]) }

    context "when the author's rfc_visibility is set to all" do
      let(:author_consumer) { create(:consumer, rfc_visibility: 'all') }

      context 'when the viewer is from another consumer' do
        context "when the viewer's rfc_visibility is set to all" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'all') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to consumer" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'consumer') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to study_group" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'study_group') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end

      context 'when the viewer is from the same consumer' do
        let(:viewer_consumer) { author_consumer }

        context 'when the viewer is from another study group' do
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context 'when the viewer is from the same study group' do
          let(:viewer_study_groups) { author_study_groups }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end
    end

    context "when the author's rfc_visibility is set to consumer" do
      let(:author_consumer) { create(:consumer, rfc_visibility: 'consumer') }

      context 'when the viewer is from another consumer' do
        context "when the viewer's rfc_visibility is set to all" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'all') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to consumer" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'consumer') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to study_group" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'study_group') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end

      context 'when the viewer is from the same consumer' do
        let(:viewer_consumer) { author_consumer }

        context 'when the viewer is from another study group' do
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context 'when the viewer is from the same study group' do
          let(:viewer_study_groups) { author_study_groups }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end
    end

    context "when the author's rfc_visibility is set to study_group" do
      let(:author_consumer) { create(:consumer, rfc_visibility: 'study_group') }

      context 'when the viewer is from another consumer' do
        context "when the viewer's rfc_visibility is set to all" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'all') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to consumer" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'consumer') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context "when the viewer's rfc_visibility is set to study_group" do
          let(:viewer_consumer) { create(:consumer, name: 'Other Consumer', rfc_visibility: 'study_group') }
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end

      context 'when the viewer is from the same consumer' do
        let(:viewer_consumer) { author_consumer }

        context 'when the viewer is from another study group' do
          let(:viewer_study_groups) { create_list(:study_group, 1, consumer: viewer_consumer) }

          %i[mark_as_solved? set_thank_you_note? show?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end

        context 'when the viewer is from the same study group' do
          let(:viewer_study_groups) { author_study_groups }

          permissions(:show?) do
            it_behaves_like 'grants access to everyone'
          end

          %i[mark_as_solved? set_thank_you_note?].each do |action|
            permissions(action) do
              it_behaves_like 'grants access to admins and authors only'
            end
          end
        end
      end
    end
  end
end
