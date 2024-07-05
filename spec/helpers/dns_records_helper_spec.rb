require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the DnsRecordsHelper. For example:
#
# describe DnsRecordsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe DnsRecordsHelper, type: :helper do
  it 'checks if a DNS record exists' do
    expect(DnsRecordsHelper.resolve_dns_record('google.com')).to be_truthy
  end
end
