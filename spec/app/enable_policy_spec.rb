# -*- encoding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../src/ruby/app'

describe "commands to change a policy's 'enabled' flag" do
  include Razor::Test::Commands

  let(:app) { Razor::App }
  before :each do
    authorize 'fred', 'dead'
  end

  context "/api/commands/create-policy" do
    before :each do
      use_task_fixtures
      header 'content-type', 'application/json'
    end

    let(:policy)   { Fabricate(:policy) }
    let(:command_hash) { { "name" => policy.name } }

    describe Razor::Command::EnablePolicy do
      it_behaves_like "a command"
    end

    describe Razor::Command::DisablePolicy do
      it_behaves_like "a command"
    end

    ["enable", "disable"].each do |verb|
      other_verb = verb == "enable" ? "disable" : "enable"

      it "returns 422 when no name is provided (#{verb})" do
        post "/api/commands/#{verb}-policy", { "noname" => "nothing" }.to_json
        last_response.status.should == 422
      end

      it "returns 404 when no policy with that name exists (#{verb})" do
        post "/api/commands/#{verb}-policy", { "name" => "nothing" }.to_json
        last_response.status.should == 404
      end

      it "#{verb}s a #{other_verb}d policy" do
        policy.enabled = verb == "disable"
        policy.save

        command "#{verb}-policy", { "name" => policy.name }

        last_response.status.should == 202
        last_response.json?.should be_true
        last_response.json.keys.should =~ %w[result]
        last_response.json["result"].should =~ /#{verb}d$/

        policy.reload
        if verb == "enable"
          policy.enabled.should be_true
        else
          policy.enabled.should be_false
        end
      end
    end
  end
end
