require "rails_helper"

RSpec.describe DeliveryState, type: :model do
  subject(:delivery_state) { DeliveryState.instance }

  before do
    delivery_state.instance_variable_set(:@requests, Concurrent::Hash.new)
    delivery_state.instance_variable_set(:@driver, Concurrent::Hash.new)
    delivery_state.set_driver_working(false)
  end

  describe "singleton pattern" do
    it "returns the same instance" do
      instance1 = DeliveryState.instance
      instance2 = DeliveryState.instance

      expect(instance1).to be(instance2)
    end

    it "initializes with empty state" do
      fresh_state = DeliveryState.instance
      fresh_state.instance_variable_set(:@requests, Concurrent::Hash.new)
      fresh_state.instance_variable_set(:@driver, Concurrent::Hash.new)
      fresh_state.set_driver_working(false)

      expect(fresh_state.all_requests).to be_empty
      expect(fresh_state.driver_working?).to be false
      expect(fresh_state.driver_location).to be_nil
    end
  end

  describe "request management" do
    let(:request_data) do
      {
        id: "test-123",
        name: "John Doe",
        address: "Test Address",
        lat: -23.5505,
        long: -46.6333,
        status: "pending",
        requested_at: Time.current
      }
    end

    describe "#add_request" do
      it "adds a request to the state" do
        delivery_state.add_request("test-123", request_data)

        expect(delivery_state.get_request("test-123")).to eq(request_data)
      end

      it "increases the total request count" do
        expect {
          delivery_state.add_request("test-123", request_data)
        }.to change { delivery_state.all_requests.count }.by(1)
      end
    end

    describe "#get_request" do
      before do
        delivery_state.add_request("test-123", request_data)
      end

      it "retrieves a request by id" do
        request = delivery_state.get_request("test-123")

        expect(request).to eq(request_data)
      end

      it "returns nil for non-existent request" do
        request = delivery_state.get_request("non-existent")

        expect(request).to be_nil
      end
    end

    describe "#all_requests" do
      it "returns all requests" do
        request1 = request_data.merge(id: "req1")
        request2 = request_data.merge(id: "req2")

        delivery_state.add_request("req1", request1)
        delivery_state.add_request("req2", request2)

        all_requests = delivery_state.all_requests
        expect(all_requests).to include(request1, request2)
        expect(all_requests.count).to eq(2)
      end

      it "returns empty array when no requests" do
        expect(delivery_state.all_requests).to eq([])
      end
    end

    describe "#update_request_status" do
      before do
        delivery_state.add_request("test-123", request_data)
      end

      it "updates request status" do
        updated_request = delivery_state.update_request_status("test-123", "accepted")

        expect(updated_request[:status]).to eq("accepted")
        expect(delivery_state.get_request("test-123")[:status]).to eq("accepted")
      end

      it "returns nil for non-existent request" do
        result = delivery_state.update_request_status("non-existent", "accepted")

        expect(result).to be_nil
      end
    end

    describe "#remove_request" do
      before do
        delivery_state.add_request("test-123", request_data)
      end

      it "removes a request" do
        delivery_state.remove_request("test-123")

        expect(delivery_state.get_request("test-123")).to be_nil
      end

      it "decreases the total request count" do
        expect {
          delivery_state.remove_request("test-123")
        }.to change { delivery_state.all_requests.count }.by(-1)
      end
    end

    describe "#pending_requests" do
      before do
        delivery_state.add_request("pending1", request_data.merge(id: "pending1", status: "pending"))
        delivery_state.add_request("pending2", request_data.merge(id: "pending2", status: "pending"))
        delivery_state.add_request("accepted1", request_data.merge(id: "accepted1", status: "accepted"))
      end

      it "returns only pending requests" do
        pending = delivery_state.pending_requests

        expect(pending.count).to eq(2)
        expect(pending.all? { |req| req[:status] == "pending" }).to be true
      end

      it "returns empty array when no pending requests" do
        delivery_state.clear_all_pending_requests

        expect(delivery_state.pending_requests).to eq([])
      end
    end

    describe "#clear_all_pending_requests" do
      before do
        delivery_state.add_request("pending1", request_data.merge(id: "pending1", status: "pending"))
        delivery_state.add_request("pending2", request_data.merge(id: "pending2", status: "pending"))
        delivery_state.add_request("accepted1", request_data.merge(id: "accepted1", status: "accepted"))
      end

      it "removes all pending requests" do
        cleared_ids = delivery_state.clear_all_pending_requests

        expect(cleared_ids).to contain_exactly("pending1", "pending2")
        expect(delivery_state.pending_requests).to be_empty
      end

      it "keeps accepted requests" do
        delivery_state.clear_all_pending_requests

        expect(delivery_state.get_request("accepted1")).not_to be_nil
      end
    end
  end

  describe "driver management" do
    describe "#set_driver_working" do
      it "sets driver working status" do
        delivery_state.set_driver_working(true)

        expect(delivery_state.driver_working?).to be true
      end

      it "updates timestamp" do
        time_before = Time.current
        delivery_state.set_driver_working(true)
        time_after = Time.current

        updated_at = delivery_state.instance_variable_get(:@driver)[:updated_at]
        expect(updated_at).to be_between(time_before, time_after)
      end
    end

    describe "#driver_working?" do
      it "returns current working status" do
        delivery_state.set_driver_working(false)
        expect(delivery_state.driver_working?).to be false

        delivery_state.set_driver_working(true)
        expect(delivery_state.driver_working?).to be true
      end
    end

    describe "#set_driver_location" do
      it "sets driver location with coordinates" do
        delivery_state.set_driver_location(-23.5505, -46.6333)
        location = delivery_state.driver_location

        expect(location[:lat]).to eq(-23.5505)
        expect(location[:long]).to eq(-46.6333)
        expect(location[:updated_at]).to be_within(1.second).of Time.current
      end

      it "updates existing location" do
        delivery_state.set_driver_location(-23.5505, -46.6333)
        delivery_state.set_driver_location(-23.5600, -46.6400)

        location = delivery_state.driver_location
        expect(location[:lat]).to eq(-23.5600)
        expect(location[:long]).to eq(-46.6400)
      end
    end

    describe "#driver_location" do
      it "returns nil when no location set" do
        expect(delivery_state.driver_location).to be_nil
      end

      it "returns location when set" do
        delivery_state.set_driver_location(-23.5505, -46.6333)
        location = delivery_state.driver_location

        expect(location).to include(
          lat: -23.5505,
          long: -46.6333
        )
        expect(location[:updated_at]).to be_present
      end
    end
  end

  describe "thread safety" do
    let(:test_request_data) do
      {
        id: "test-123",
        name: "John Doe",
        address: "Test Address",
        lat: -23.5505,
        long: -46.6333,
        status: "pending",
        requested_at: Time.current
      }
    end

    it "handles concurrent request additions safely" do
      threads = []

      10.times do |i|
        threads << Thread.new do
          delivery_state.add_request("req#{i}", test_request_data.merge(id: "req#{i}"))
        end
      end

      threads.each(&:join)

      expect(delivery_state.all_requests.count).to eq(10)
    end

    it "handles concurrent status updates safely" do
      delivery_state.add_request("test", test_request_data)

      threads = []
      statuses = %w[pending accepted delivered]

      10.times do
        threads << Thread.new do
          status = statuses.sample
          delivery_state.update_request_status("test", status)
        end
      end

      threads.each(&:join)

      final_request = delivery_state.get_request("test")
      expect(statuses).to include(final_request[:status])
    end
  end

  describe "edge cases" do
    context "memory management" do
      it "handles large numbers of requests without memory leaks" do
        initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

        1000.times do |i|
          delivery_state.add_request("memory-test-#{i}", {
            id: "memory-test-#{i}",
            name: "Memory Test User #{i}",
            address: "Memory Test Address #{i}" * 10,
            status: "pending",
            requested_at: Time.current
          })
        end

        1000.times do |i|
          delivery_state.remove_request("memory-test-#{i}")
        end

        GC.start

        final_memory = `ps -o rss= -p #{Process.pid}`.to_i
        memory_increase = final_memory - initial_memory

        expect(memory_increase).to be < 50_000
      end

      it "handles request data with large strings" do
        large_string = "A" * 100_000

        expect {
          delivery_state.add_request("large-data", {
            id: "large-data",
            name: large_string,
            address: large_string,
            notes: large_string,
            status: "pending"
          })
        }.not_to raise_error

        request = delivery_state.get_request("large-data")
        expect(request[:name].length).to eq(100_000)
      end
    end

    context "thread safety edge cases" do
      it "handles rapid concurrent modifications" do
        threads = []
        results = []
        mutex = Mutex.new

        5.times do |i|
          threads << Thread.new do
            begin
              5.times do |j|
                request_id = "thread-#{i}-#{j}"

                delivery_state.add_request(request_id, {
                  id: request_id,
                  name: "Thread #{i} User #{j}",
                  status: "pending"
                })

                delivery_state.update_request_status(request_id, "accepted")

                delivery_state.remove_request(request_id)
              end
              mutex.synchronize { results << :success }
            rescue => e
              mutex.synchronize { results << e }
            end
          end
        end

        threads.each(&:join)

        expect(results.all? { |r| r == :success }).to be true
        expect(results.length).to eq(5)
      end

      it "maintains data consistency during concurrent access" do
        threads = []

        5.times do |i|
          delivery_state.add_request("consistency-#{i}", {
            id: "consistency-#{i}",
            status: "pending"
          })
        end

        threads << Thread.new do
          10.times do |i|
            delivery_state.add_request("add-#{i}", {
              id: "add-#{i}",
              status: "pending"
            })
            sleep 0.01
          end
        end

        threads << Thread.new do
          20.times do
            delivery_state.all_requests
            delivery_state.pending_requests
            sleep 0.005
          end
        end

        threads.each(&:join)

        all_requests = delivery_state.all_requests
        expect(all_requests).to be_a(Array)

        all_requests.each do |request|
          expect(request).to have_key(:id)
          expect(request).to have_key(:status)
        end
      end
    end

    context "data integrity" do
      it "handles duplicate request IDs" do
        delivery_state.add_request("duplicate", {
          id: "duplicate",
          name: "First User",
          status: "pending"
        })

        delivery_state.add_request("duplicate", {
          id: "duplicate",
          name: "Second User",
          status: "accepted"
        })

        request = delivery_state.get_request("duplicate")
        expect(request[:name]).to eq("Second User")
        expect(request[:status]).to eq("accepted")
      end

      it "handles nil and empty request data" do
        expect {
          delivery_state.add_request("nil-data", nil)
        }.not_to raise_error

        expect {
          delivery_state.add_request("empty-data", {})
        }.not_to raise_error

        nil_request = delivery_state.get_request("nil-data")
        empty_request = delivery_state.get_request("empty-data")

        expect(nil_request).to be_nil
        expect(empty_request).to eq({})
      end

      it "maintains request count consistency" do
        initial_count = delivery_state.all_requests.length

        5.times do |i|
          delivery_state.add_request("count-#{i}", {
            id: "count-#{i}",
            status: "pending"
          })
        end

        expect(delivery_state.all_requests.length).to eq(initial_count + 5)

        3.times do |i|
          delivery_state.remove_request("count-#{i}")
        end

        expect(delivery_state.all_requests.length).to eq(initial_count + 2)

        delivery_state.clear_all_pending_requests

        final_count = delivery_state.all_requests.length
        expect(final_count).to eq(initial_count)  # Should remove the 2 remaining pending requests
      end
    end

    context "driver state edge cases" do
      it "handles driver location with extreme precision" do
        precise_lat = Math::PI
        precise_long = Math::E

        delivery_state.set_driver_location(precise_lat, precise_long)

        location = delivery_state.driver_location
        expect(location[:lat]).to be_within(1e-15).of(precise_lat)
        expect(location[:long]).to be_within(1e-15).of(precise_long)
      end

      it "handles rapid driver state changes" do
        expect {
          100.times do
            delivery_state.set_driver_working(true)
            delivery_state.set_driver_working(false)
          end
        }.not_to raise_error

        expect(delivery_state.driver_working?).to be false
      end

      it "preserves driver location when going offline" do
        delivery_state.set_driver_working(true)
        delivery_state.set_driver_location(-23.5505, -46.6333)

        original_location = delivery_state.driver_location

        delivery_state.set_driver_working(false)

        expect(delivery_state.driver_location).to eq(original_location)
      end
    end

    context "singleton pattern edge cases" do
      it "maintains singleton across threads" do
        instances = []
        threads = []

        10.times do
          threads << Thread.new do
            instances << DeliveryState.instance
          end
        end

        threads.each(&:join)

        expect(instances.uniq.length).to eq(1)
        expect(instances.all? { |i| i == delivery_state }).to be true
      end

      it "survives garbage collection attempts" do
        original_instance = DeliveryState.instance

        10.times { GC.start }

        new_instance = DeliveryState.instance
        expect(new_instance).to be(original_instance)
      end
    end
  end
end
