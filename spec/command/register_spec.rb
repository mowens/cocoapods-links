require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Register do
    describe 'CLAide' do
      it 'registers itself' do
        Command.parse(['register']).should.be.instance_of Command::Register
      end
    end

    before do
      @command = Pod::Command::Register.new CLAide::ARGV.new []
    end
  end
end
