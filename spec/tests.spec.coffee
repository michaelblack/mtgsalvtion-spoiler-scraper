## jasmine tests
s = (require '../scraper.js').testing
$ = require 'jquery'
fs = require 'fs'

spoilers = $ (fs.readFileSync __dirname + '/test.html').toString()
db = 



describe 'Helper Functions', () ->
    describe 'unique', () ->
        it 'handles nonsensical cases', () ->
            expect( s.unique [] ).toEqual []
            expect( s.unique [1] ).toEqual [1] 
        it 'strips multiples', () ->
            expect( s.unique [1,1] ).toEqual [1]
        it 'keeps unique elements', () ->
            expect( s.unique [1,2] ).toEqual [1,2]
    describe 'find', () ->
        it 'returns undefined on a failure', () ->
            expect( s.find [], (x) -> x is 1 ).toBeUndefined()
            expect( s.find [1], (x) -> x is 2 ).toBeUndefined()
        it 'finds the first element that tests true', () ->
            expect( s.find [1], (x) -> x is 1 ).toBe 1
            x = {test: 1}
            y = {test: 1}
            expect( s.find [x, 1, y], (z) -> z.test is 1 ).toBe x
    describe 'log', () ->
        it 'acts as an identity function', () ->
            expect( (s.log '') 1 ).toBe 1
        it 'logs the message', () ->
            spyOn console, 'log'
            (s.log 'test') 1
            expect( console.log ).toHaveBeenCalledWith 'test'

describe 'Card Parsing Functions', () ->
    results = s.parseDoc {setName: 'MST', setLongName : 'My Set'}, spoilers
    cards = {}
    results.cards.forEach (card) ->
        name = card.name[0]
        cards[name] = card
    
    it 'should parse set names correctly', () ->
        expect( results.set.name[0] ).toBe 'MST'
        expect( results.set.longname[0] ).toBe 'My Set'
        expect( cards['Bear'].set[0]['_'] ).toBe 'MST'
    it 'should parse card names correctly', () ->
        expect( Object.keys cards ).toEqual ['Bear', 'Wings', 'Bob the Awakened', 'Tapped Land']
    it 'should parse mana costs correctly', () ->
        expect( cards['Bear'].manacost[0] ).toBe '1G'
        expect( cards['Wings'].manacost[0] ).toBe 'UU'
        expect( cards['Bob the Awakened'].manacost[0] ).toBe '1WR'
        expect( cards['Tapped Land'].manacost[0] ).toBe ''
    it 'should parse colors correctly', () ->
        expect( cards['Wings'].color.map (x) -> x['_'] ).toEqual ['U']
        expect( cards['Bob the Awakened'].color.map (x) -> x['_'] ).toEqual ['W', 'R']
        expect( cards['Tapped Land'].color ).toBeUndefined()
    it 'should parse the correct images', () ->
        expect( cards['Bear'].set[0]['$'].picURL ).toBe 'test.jpg'
    it 'should parse PT and loyalty correctly', () ->
        expect( cards['Bear'].pt[0] ).toBe '2/2'
        expect( cards['Bob the Awakened'].loyalty[0] ).toBe '4'
    it 'should parse types correctly', () ->
        expect( cards['Bear'].type[0] ).toBe 'Creature - Bear'
    it 'should parse ability text correctly', () ->
        expect( cards['Wings'].text[0] ).toBe 'Kicker {U}'
    it 'should parse cipt correctly', () ->
        expect( cards['Tapped Land'].cipt[0] ).toBe '1'
    it 'should parse tablerows correctly', () ->
        expect( cards['Bear'].tablerow[0] ).toBe '2'
        expect( cards['Wings'].tablerow[0] ).toBe '3'
        expect( cards['Bob the Awakened'].tablerow[0] ).toBe '1'
        expect( cards['Tapped Land'].tablerow[0] ).toBe '0'
