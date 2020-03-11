require 'tildeconfig'

describe Tildeconfig::TildeMod do
    it "exists, and has basic methods" do
        x = Tildeconfig::TildeMod.new
        x.install do
            print "no-op"
        end
        x.uninstall do
            print "no-op"
        end
        x.update do
            print "no-op"
        end
    end
    it "allows both types of file invocations" do
        x = Tildeconfig::TildeMod.new
        x.file "source"
        x.file "source2" "destination2"
    end
end
