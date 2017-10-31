# This script takes a file in the wordPairs format
# and generates a file with unique word counts
# ASuMa 2017

#push!(LOAD_PATH, "./src/")

using ArgParse

s = ArgParseSettings()

@add_arg_table s begin
  "wordPairsFile"
    help = "File with wordPairs data"
    arg_type = AbstractString
    required = true
  "realDictFile"
    help = "File to output dictionary"
    arg_type = AbstractString
    required = true
  "--initSentence"
    help = "Number of the first sentence"
    arg_type = Int64
    default = 1
end

args = parse_args(ARGS, s)

fi = open(args["wordPairsFile"], "r")
currentSentence = args["initSentence"]
posToWords = Dict() # stores words in same sentence
realDict = Dict() # stores the full dictionary
while !eof(fi)
    line = split(readline(fi))
    sentenceNum = parse(Int32, line[1])
    # when the line changes, update realDict, reset posToWords
    if sentenceNum != currentSentence
        currentSentence = sentenceNum
        for value in values(posToWords)
            if !haskey(realDict, value) realDict[value] = 0 end
            realDict[value] += 1
        end
        posToWords = Dict()
    end
    # fill line into posToWords
    if !haskey(posToWords, line[2]) push!(posToWords, line[2] => line[3]) end
    if !haskey(posToWords, line[4]) push!(posToWords, line[4] => line[5]) end
end
# include last sentence
for value in values(posToWords)
    if !haskey(realDict, value) realDict[value] = 0 end
    realDict[value] += 1
end
close(fi)

fo = open(args["realDictFile"], "w")
for (key, value) in realDict
    @printf(fo, "%s %d\n", key, value)
end
close(fo)
