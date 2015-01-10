require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Unlink do
    describe 'CLAide' do
      it 'registers itself' do
        Command.parse(['unlink']).should.be.instance_of Command::Unlink
      end
    end

    before do
      @command = Pod::Command::Unlink.new CLAide::ARGV.new []
    end
  end
end
