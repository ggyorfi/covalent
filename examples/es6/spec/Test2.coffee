Test = require '../lib/CoffeeTest'

describe "Test", ->

  _test = null

  beforeEach ->
    _test = new Test

  describe "test()", ->

    it "returns the parameter", ->
      x.y = 10
      expect(_test.returnValue 10).to.equal 11

    it "returns the parameter", ->
      expect(_test.returnValue 11).to.equal 1
