require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Link do
    describe 'CLAide' do
      it 'registers itself' do
        Command.parse(['link']).should.be.instance_of Command::Link
      end
    end

    before do
      @command = Pod::Command::Link.new CLAide::ARGV.new []
    end
  end
end
