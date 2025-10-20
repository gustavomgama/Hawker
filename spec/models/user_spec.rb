require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { should have_secure_password }
  end

  describe "email normalization" do
    it "strips and downcases email" do
      user = User.new(email: "  TEST@EXAMPLE.COM  ", password: "password123")
      user.save!

      expect(user.email).to eq("test@example.com")
    end

    it "handles nil email gracefully" do
      user = User.new(email: nil, password: "password123")

      expect(user.email).to be_nil
    end
  end

  describe "password authentication" do
    let(:user) { create(:user, password: "password123") }

    it "authenticates with correct password" do
      expect(user.authenticate("password123")).to eq(user)
    end

    it "returns false with incorrect password" do
      expect(user.authenticate("wrong_password")).to be false
    end

    it "requires password to be present" do
      user = User.new(email: "test@example.com")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe "session management" do
    let(:user) { create(:user) }

    it "can have multiple sessions" do
      session1 = create(:session, user: user)
      session2 = create(:session, user: user)

      expect(user.sessions).to include(session1, session2)
    end

    it "destroys associated sessions when user is deleted" do
      session = create(:session, user: user)
      session_id = session.id

      user.destroy

      expect(Session.find_by(id: session_id)).to be_nil
    end
  end

  describe "edge cases" do
    context "email edge cases" do
      it "handles extremely long emails" do
        long_local = "a" * 320
        long_email = "#{long_local}@example.com"

        user = User.new(email: long_email, password: "password123")

        expect(user.email).to eq(long_email.downcase.strip)
      end

      it "handles emails with unicode characters" do
        unicode_email = "tëst@exämple.com"

        user = build(:user, email: unicode_email)
        user.valid?

        expect(user.email).to eq(unicode_email.downcase.strip)
      end

      it "handles emails with special characters" do
        special_email = "test+tag@example-domain.co.uk"

        user = build(:user, email: special_email)
        expect(user.email).to eq(special_email.downcase.strip)
      end

      it "handles malformed emails gracefully" do
        malformed_emails = [
          "not-an-email",
          "@example.com",
          "test@",
          "test@@example.com",
          "",
          nil
        ]

        malformed_emails.each do |email|
          user = build(:user, email: email)
          expect { user.valid? }.not_to raise_error
        end
      end
    end

    context "password edge cases" do
      it "handles very long passwords" do
        long_password = "password123" * 100

        user = build(:user, password: long_password)
        expect(user.authenticate(long_password)).to be_truthy
      end

      it "handles passwords with unicode characters" do
        unicode_password = "pässwörd123🔒"

        user = build(:user, password: unicode_password)
        expect(user.authenticate(unicode_password)).to be_truthy
      end

      it "handles passwords with special characters" do
        special_password = "p@$$w0rd!#$%^&*()"

        user = build(:user, password: special_password)
        expect(user.authenticate(special_password)).to be_truthy
      end

      it "securely handles empty passwords" do
        user = build(:user, password: "")
        expect(user).not_to be_valid
        expect(user.authenticate("")).to be_falsy
      end
    end

    context "session management edge cases" do
      let(:user) { create(:user) }

      it "handles creating many sessions" do
        expect {
          100.times do |i|
            create(:session, user: user)
          end
        }.not_to raise_error

        expect(user.sessions.count).to eq(100)
      end

      it "properly cascades session deletion" do
        sessions = 5.times.map { create(:session, user: user) }
        session_ids = sessions.map(&:id)

        user.destroy

        session_ids.each do |id|
          expect(Session.find_by(id: id)).to be_nil
        end
      end

      it "handles multiple session creation for same user" do
        session_ids = []

        3.times do
          session = create(:session, user: user)
          session_ids << session.id
        end

        expect(session_ids.length).to eq(3)
        expect(session_ids.compact.length).to eq(3)
        expect(session_ids.all? { |id| id.is_a?(Integer) }).to be true
        expect(user.sessions.count).to eq(3)
      end
    end

    context "data integrity" do
      it "maintains referential integrity across multiple users" do
        users = []
        5.times do |i|
          users << create(:user, email: "sequential#{i}@example.com")
        end

        users.each do |user|
          3.times { create(:session, user: user) }
        end

        users.each do |user|
          user.reload
          expect(user.sessions.count).to eq(3)

          user.sessions.each do |session|
            expect(session.user).to eq(user)
          end
        end
      end
    end
  end
end
