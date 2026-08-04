require "test_helper"

module SyncableInterfaceTest
  extend ActiveSupport::Testing::Declarative
  include ActiveJob::TestHelper

  test "can sync later" do
    assert_difference "@syncable.syncs.count", 1 do
      assert_enqueued_with job: SyncJob do
        @syncable.sync_later
      end
    end
  end

  test "can perform sync" do
    mock_sync = mock
    @syncable.class.any_instance.expects(:perform_sync).with(mock_sync).once
    @syncable.perform_sync(mock_sync)
  end

  test "second sync request does not create a new sync" do
    first_sync = @syncable.sync_later

    assert_no_difference "@syncable.syncs.count" do
      @syncable.sync_later
    end
  end

  test "needs sync when data is not synced through today" do
    @syncable.update!(data_synced_through: Date.current)
    assert_not @syncable.needs_sync?

    @syncable.update!(data_synced_through: 1.day.ago.to_date)
    assert @syncable.needs_sync?
  end
end
