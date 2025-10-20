require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it "requires a user" do
      session = Session.new(user: nil)
      expect(session).not_to be_valid
      expect(session.errors[:user]).to include("must exist")
    end
  end

  describe "session creation" do
    let(:user) { create(:user) }

    it "creates a session with a user" do
      session = Session.create!(user: user)

      expect(session.user).to eq(user)
      expect(session.persisted?).to be true
    end

    it "generates an id automatically" do
      session = Session.create!(user: user)

      expect(session.id).to be_present
    end
  end

  describe "session lookup" do
    let(:user) { create(:user) }

    let(:session) { create(:session, user: user) }

    it "can find session by id" do
      found_session = Session.find(session.id)

      expect(found_session).to eq(session)
      expect(found_session.user).to eq(user)
    end
  end

  describe "edge cases" do
    context "ID generation edge cases" do
      it "generates unique IDs for multiple sessions" do
        user = create(:user)
        session_ids = []

        5.times do
          session = create(:session, user: user)
          session_ids << session.id
        end

        expect(session_ids.length).to eq(5)
        expect(session_ids.compact.length).to eq(5)
        expect(session_ids.uniq.length).to eq(session_ids.length)
        expect(session_ids.all? { |id| id.is_a?(Integer) }).to be true
      end

      it "handles ID collision gracefully" do
        user = create(:user)

        session1 = create(:session, user: user)

        session2 = create(:session, user: user)

        expect(session1.id).not_to eq(session2.id)
      end
    end

    context "association edge cases" do
      it "handles user deletion during session access" do
        user = create(:user)
        session = create(:session, user: user)

        user.destroy

        expect(Session.find_by(id: session.id)).to be_nil
      end

      it "handles sessions with non-existent user IDs in queries" do
        sessions = Session.joins(:user).where(users: { id: 99999 })
        expect(sessions.to_a).to be_empty
      end
    end

    context "validation edge cases" do
      it "requires user association" do
        session = build(:session, user: nil)
        expect(session).not_to be_valid
        expect(session.errors[:user]).to include("must exist")
      end

      it "handles sessions with invalid user references" do
        session = Session.new(user_id: 99999)
        expect(session).not_to be_valid
      end
    end
  end
end
