import Test from '../lib/Test';

describe("Test", function () {

    var _test;

    beforeEach(function () {
        _test = new Test();
    });

    describe("test()", function () {

        it("returns the parameter", function () {
            // expect(_test.returnValue(10)).to.equal(10);
        });

        it("returns the parameter", function () {
            expect(_test.returnValue(10)).to.equal(10);
        });

    });

});
