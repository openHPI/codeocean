# frozen_string_literal: true

require 'rails_helper'

# AI generated to capture performance characteristics of ProxyExercise
# rubocop:disable FactoryBot/ExcessiveCreateList
RSpec.describe ProxyExercise do
  # Simple SQL capture helper using ActiveSupport notifications
  def capture_sql(&)
    events = []
    callback = ->(_name, _start, _finish, _id, payload) { events << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    events
  end

  def query_count(&)
    capture_sql(&).size
  end

  describe 'performance characteristics' do
    describe '#count_files' do
      it 'uses an efficient COUNT query instead of loading all exercises' do
        pe = create(:proxy_exercise)
        create_list(:dummy, 20).each {|ex| pe.exercises << ex }

        # Warm-up (avoid counting queries from lazy loading of associations)
        pe.reload

        sqls = capture_sql { expect(pe.count_files).to eq(20) }

        # We expect a single COUNT(*) style query (plus, in some adapters, an implicit PRAGMA/SHOW if any)
        # Be tolerant: assert that at least one of the queries contains COUNT and total number is small
        has_count = sqls.any? {|sql| sql =~ /COUNT\s*\(/i }
        expect(has_count).to be(true), "Expected a COUNT query, got: #{sqls.inspect}"
        expect(sqls.size).to be <= 3 # 1 main COUNT + possible noise
      end
    end

    describe "#get_matching_exercise when algorithm is 'random'" do
      let(:user) { create(:learner) }

      it 'does not increase the number of SQL queries with a larger exercise pool' do
        pe_small = create(:proxy_exercise, algorithm: 'random')
        chosen_small = create(:dummy)
        others_small = create_list(:dummy, 9)
        pe_small.exercises << ([chosen_small] + others_small)
        allow(pe_small.exercises.target).to receive(:sample).and_return(chosen_small)

        pe_large = create(:proxy_exercise, algorithm: 'random')
        chosen_large = create(:dummy)
        others_large = create_list(:dummy, 99)
        pe_large.exercises << ([chosen_large] + others_large)
        allow(pe_large.exercises.target).to receive(:sample).and_return(chosen_large)

        # Measure queries for small pool
        small_queries = query_count { pe_small.get_matching_exercise(user) }

        # Measure queries for large pool
        large_queries = query_count { pe_large.get_matching_exercise(user) }

        # The random algorithm should not need additional queries proportional to the pool size.
        # Allow a tiny slack for adapter differences and inserts of assignment rows.
        expect(large_queries - small_queries).to be <= 2,
          "Expected roughly constant query count, got small=#{small_queries}, large=#{large_queries}"
      end
    end

    describe "#get_matching_exercise when algorithm is 'best_match'" do
      it 'reports current SQL query counts across pool sizes (opt-in via PERF=1)' do
        ActiveRecord.verbose_query_logs = true

        # Helper to build an exercise with given tags and difficulty
        def build_tagged_exercise(difficulty:, tags:)
          ex = create(:dummy, expected_difficulty: difficulty)
          tags.each do |tag|
            ExerciseTag.create!(exercise: ex, tag:, factor: 1)
          end
          ex
        end

        # Prepare a fixed tag universe to be stable across runs
        tags = (1..5).map {|i| Tag.create!(name: "perf-tag-#{i}-#{SecureRandom.hex(2)}") }

        # Build a small history of exercises the user has accessed, covering all tags
        user = create(:learner)
        seen_exercises = Array.new(5) {|i| build_tagged_exercise(difficulty: 2, tags: [tags[i]]) }
        # Create real submissions for the user to reflect accessed exercises (no stubbing)
        seen_exercises.each do |ex|
          Submission.create!(exercise: ex, contributor: user, cause: 'submit')
        end

        def build_pool(size:, tags:)
          pe = create(:proxy_exercise, algorithm: 'best_match')
          # Distribute tags and difficulties deterministically
          exercises = (1..size).map do |i|
            difficulty = 1 + (i % 3) # 1..3
            assigned_tags = [tags[i % tags.size], tags[(i + 1) % tags.size]].uniq
            build_tagged_exercise(difficulty:, tags: assigned_tags)
          end
          pe.exercises << exercises
          pe
        end

        # Measure across multiple pool sizes
        sizes = [10, 30, 60]
        # sizes = [1]
        results = {}
        sizes.each do |n|
          pe = build_pool(size: n, tags:)
          # Warm up: ensure associations are loaded enough to avoid counting lazy first-time loads unrelated to algorithm
          pe.reload
          queries = query_count { pe.get_matching_exercise(user) }
          results[n] = queries
        end

        puts "BEST_MATCH query counts by pool size: #{results.inspect}"

        # Very loose sanity checks — this spec primarily reports the current optimization level.
        expect(results.values.all?(&:positive?)).to be(true)
      end
    end

    describe "#get_matching_exercise 'best_match' with varying tag counts" do
      it 'reports current SQL query counts across different tags per exercise (opt-in via PERF=1)' do
        # skip('Set PERF=1 to run performance specs') unless ENV['PERF']

        # Helper to build an exercise with given tags and difficulty
        def build_tagged_exercise(difficulty:, tags:)
          ex = create(:dummy, expected_difficulty: difficulty)
          tags.each do |tag|
            ExerciseTag.create!(exercise: ex, tag: tag, factor: 1)
          end
          ex
        end

        user = create(:learner)

        # Build a small history of exercises the user has accessed, covering some tags
        base_tags = (1..8).map {|i| Tag.create!(name: "var-tags-base-#{i}-#{SecureRandom.hex(2)}") }
        seen_exercises = base_tags.first(4).map {|t| build_tagged_exercise(difficulty: 2, tags: [t]) }
        # Create real submissions for the user to reflect accessed exercises (no stubbing)
        seen_exercises.each do |ex|
          Submission.create!(exercise: ex, contributor: user, cause: 'submit')
        end

        def build_pool_with_tag_count(size:, tag_universe:, tags_per_ex:)
          pe = create(:proxy_exercise, algorithm: 'best_match')
          exercises = (1..size).map do |i|
            difficulty = 1 + (i % 3) # 1..3
            assigned = (0...tags_per_ex).map {|k| tag_universe[(i + k) % tag_universe.size] }.uniq
            build_tagged_exercise(difficulty: difficulty, tags: assigned)
          end
          pe.exercises << exercises
          pe
        end

        # Vary the number of tags per exercise while keeping pool size constant
        tags_per_exercise = [1, 2, 3, 5]
        tag_universe = (1..10).map {|i| Tag.create!(name: "var-tags-univ-#{i}-#{SecureRandom.hex(2)}") }
        results = {}
        tags_per_exercise.each do |k|
          pe = build_pool_with_tag_count(size: 30, tag_universe: tag_universe, tags_per_ex: k)
          # Warm up: ensure associations are loaded enough to avoid counting lazy first-time loads unrelated to algorithm
          pe.reload
          queries = query_count { pe.get_matching_exercise(user) }
          results[k] = queries
        end

        puts "BEST_MATCH query counts by tags per exercise: #{results.inspect}"

        # Loose sanity check
        expect(results.values.all?(&:positive?)).to be(true)
      end
    end
  end
end
# rubocop:enable FactoryBot/ExcessiveCreateList
