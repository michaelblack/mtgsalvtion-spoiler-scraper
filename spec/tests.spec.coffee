s = (require '../scraper.js').testing

describe 'Helper Functions', () ->
    describe 'unique', () ->
        it 'handles empties', () ->
            expect( s.unique [] ).toEqual []
        it 'handles arrays of one', () ->
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

