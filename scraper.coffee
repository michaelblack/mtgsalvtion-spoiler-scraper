#====== Imports and Setup ======
$            = require 'jquery'
http         = require 'http'
xml2js       = require 'xml2js'
entities     = require 'entities'
fs           = require 'fs'
q            = require 'q'

parser       = new xml2js.Parser({trim: true})
builder      = new xml2js.Builder()
#===============================

#====== Exports ======

#=====================

#====== CLI Args ======
###
    that.setName     = process.argv[2]
    that.setLongName = process.argv[3]
    that.spoilerUrl  = process.argv[4]
    that.cardsPath   = process.argv[5]
###
#======================


#====== Utility Functions ======
# unique : Array -> Array
# returns a new array that filters out all duplicates
unique = (array) ->
    arr =  []
    array.forEach (item) ->  arr.push item if (arr.indexOf item) < 0
    arr

# find : Array x (any -> Bool) -> any
# returns the first element of an array for which the tester function returns true
find = (array, tester) ->
    for item in array
        return item if tester item

# log : any0 -> any1 -> any0
# takes a message and returns an identity function that logs the messages when it runs
log = (message) -> (data) ->
    console.log message
    data
#===============================


#========== Card Functions =============
# parseDoc : element -> {set : <set info>, cards : [<card-info>]}
# parses the mtgsalvation spoiler page dom to get the cards from it
parseDoc = (setInfo, html) ->
    set : {name : [setInfo.setName], longname : [setInfo.setLongName]}
    cards : $(html).find('.t-spoiler').map(() -> parseSpoiler setInfo, this).toArray()

# parseCost, parseType, parsePT, parseText, parsePicUrl : Element -> String
# Rather straight-forward. Parses the cost, type, text, picture url or power/toughness of a spoilered card
# Note that parsePT is used to fetch loyalty counters on planeswalkers as well
parseCost   = (elem) -> $(elem).find('.t-spoiler-mana > li > span').text()
parseType   = (elem) -> $(elem).find('.t-spoiler-type').text()
parsePT     = (elem) -> $(elem).find('.t-spoiler-stat').text()
parsePicUrl = (elem) -> $(elem).find('a.spoiler-image-link').attr('href')
parseText   = (elem) ->
    $(elem)
        .find '.t-spoiler-ability'
            .find '.mana-icon'
                .replaceWith () -> '{' + $(this).text() + '}'
            .end()
        .text()
        .split('\n')
        .map (str) -> str.trim()
        .filter (str) -> not str.match /^$/ 
        .join('\n')

# costToColors : String -> [String]
# takes a mana cost and returns the colors in it as an unique element'd Array of 'W','U','B','R', and 'G'
costToColors = (cost) -> unique cost.split('').filter( (elem) -> (/[WUBRG]/).test elem )

# parseSpoiler : Element -> <card-object>
# parses and entire spoilered card into the appropriate object for the xml builder
parseSpoiler = (setInfo, elem) ->
    name   = elem.id
    cost   = parseCost elem
    colors = costToColors(cost).map (color) ->  '_' : color
    type   = parseType elem
    text   = parseText elem
    picURL = parsePicUrl elem
    result = {}
    
    result.name = [name]
    result.set = [{ '_' : setInfo.setName}]
    result.set[0]['$'] = {picURL : picURL} if picURL?
    result.color = colors if colors.length > 0
    result.manacost = [cost]
    result.type = [type]
    if type.match /Planeswalker/
        result.tablerow = ['1']
        result.loyalty = [(parsePT elem).split('/')[1]]
    else if type.match /Land/
        result.tablerow = ['0']
    else if type.match /(Instant)|(Sorcery)/
        result.tablerow = ['3']
    else if type.match /Creature/
        result.tablerow = ['2']
        result.pt = [parsePT elem]
    else
        result.tablerow = ['1']

    if text.match (new RegExp(name + ' enters the battlefield tapped'))
        result.cipt = ['1']

    result.text = [text]
    result
#=================================================================


# mergeSpoilers : <Spoiler Object> x <Database XML Object> -> String
# mergeSpoilers takes a spoilers object as taken from parseDoc, a parsed cockatrice xml database,
# and returns a new xml database as a string 
mergeSpoilers = (spoilers, database) ->
        db_cards = database.cockatrice_carddatabase.cards[0].card
        db_sets  = database.cockatrice_carddatabase.sets[0].set

        db_sets.push spoilers.set unless find db_sets, (set) -> set.name[0] is spoilers.set.name[0]
        
        toAdd = spoilers.cards.filter (card) ->
            found = find db_cards, (found_card) -> card.name[0] is found_card.name[0]
            if found
                found.set.push card.set[0] unless find found.set, (set) -> set['_'] == spoilers.set.name[0]
                false
            else
                true
                
        Array.prototype.push.apply db_cards, toAdd
        builder.buildObject database

#====== Promise Functions ======
# loadFile : String -> Promise
# loads the file from the given path and feeds out the data            
loadFile = (path) ->
    def = q.defer()
    fs.readFile path, (err, data) -> if err then def.reject err else def.resolve data
    def.promise
    
# parseXML : String -> Promise
# parses the xml string and feeds out the parsed javascript object
parseXML = (xml) ->
    def = q.defer()
    parser.parseString xml, (err, data) -> if err then def.reject err else def.resolve data
    def.promise
            

# getWithRedirect : String -> Promise
# Fetches the data from a given url, but follows redirects
getWithRedirect = (url) ->
    def = q.defer()
    http.get url, (resp) ->
        if resp.statusCode is 302
            getWithRedirect resp.headers['location']
            .then (gotten) -> def.resolve gotten
            .catch (err)   -> def.reject  err
        else
            result = ''
            resp.on   'data'  , (data) -> result += data
            resp.once 'end'   , ()     -> def.resolve result
            resp.once 'error' , (err)  -> def.reject err
    def.promise
#===============================

#====== Main ======
fetchSpoilers = (setInfo) ->
    getWithRedirect setInfo.spoilerUrl
    .then log '* Fetched ' + spoilerUrl + ' ...'
    .then (data) -> parseDoc setInfo, data
    .then log '* Generated card information from the website ...'

loadDatabase = (cardsPath) ->
    loadFile cardsPath
    .then log '* Loaded ' + cardsPath + ' ...'
    .then parseXML
    .then log '* Parsed the card database ...'

main = (setInfo, cardsPath) -> 
    q.all [fetchSpoilers setInfo, loadDatabase cardsPath]
    .spread mergeSpoilers
    .then log '* Merged the fetched cards into the database ...'
    .then (data) -> fs.writeFileSync cardsPath, data
    .then log '* Wrote the file to disk ...'
    .fail console.log
    .done () ->
        console.log '* Done!'
        process.exit()

setInfo = setName: process.argv[2]
          setLongName: process.argv[3]
          spoilerUrl: process.argv[4]

main(setInfo, process.argv[5])

module.exports = testing :
    unique : unique
    find   : find
    log    : log
    parseDoc : parseDoc
    
