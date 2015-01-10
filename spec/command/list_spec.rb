require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::List::Links do
    describe 'CLAide' do
      it 'registers itself' do
        Command.parse(%w(list links)).should.be.instance_of Command::List::Links
      end
    end

    before do
      @command = Pod::Command::List::Links.new CLAide::ARGV.new []
    end
  end
end
