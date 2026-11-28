require "test_helper"

class PrunePositionsJobTest < ActiveJob::TestCase
  test "the job deletes every recorded position" do
    Position.create!(latitude: 1, longitude: 2)
    Position.create!(latitude: 3, longitude: 4)

    PrunePositionsJob.perform_now

    assert_empty Position.all
  end
end
