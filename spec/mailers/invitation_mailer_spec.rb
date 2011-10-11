require "spec_helper"

describe InvitationMailer do
  describe "invite" do
    let(:mail) { InvitationMailer.invite }

    it "renders the headers" do
      mail.subject.should eq("Invite")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
