import Test from '../lib/Test';

describe("Test", function () {

    var _test;

    beforeEach(function () {
        _test = new Test();
        console.log(_test.returnValue(1033));
    });

    describe("test()", function () {

        it("returns the parameter", function () {
            console.log(_test.returnValue(99));
            expect(_test.returnValue(10)).to.equal(10);
        });

    });

});
