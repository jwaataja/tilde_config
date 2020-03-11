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
    it "can define custom methods" do
        # surely a smarter way to do this?
        dummy = double('dummy')
        # this expectation just ensures our new function is called exactly once
        expect(dummy).to receive(:method1)

        Tildeconfig::TildeMod.def_cmd :my_method do |m, arg1, arg2|
            expect(arg1).to eq(1)
            expect(arg2).to eq(42)
            dummy.method1
        end

        m = Tildeconfig::TildeMod.new
        m.my_method 1, 42
    end
    it "Custom methods can use further methods" do
        Tildeconfig::TildeMod.def_cmd :my_method do |m|
            m.install do
                print "no-op"
            end
        end

        m = Tildeconfig::TildeMod.new
        expect(m).to receive(:install)
        m.my_method
    end
end
