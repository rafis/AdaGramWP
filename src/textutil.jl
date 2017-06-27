function adagram_isblank(c::Char)
  return c == ' ' || c == '\t'
end

function adagram_isblank(s::AbstractString)
  return all((c->begin
            c == ' ' || c == '\t'
        end),s)
end

function word_iterator(f::IO, end_pos::Int64=-1)
  function producer()
    while (end_pos < 0 || position(f) < end_pos) && !eof(f)
      w = readuntil(f, ' ')
      if length(w) < 1 break end
      w = w[1:end-1]
      if !adagram_isblank(w)
        produce(w)
      end
    end
  end

  return Task(producer)
end

# Modified: produces arrays where first item is a word and all other
#           items are its context words
function looped_word_iterator(f::IO, start_pos::Int64, end_pos::Int64)
  function producer()
    line = readline(f) # ignores possibly truncated line if parallel processing
    start_pos = position(f) # for subsequent epochs, it knows where to start
    line = readline(f) # first certainly complete sentence
    words = split(line)
    sentenceNbr = parse(Int32, words[1]) # input should be formatted accordingly
    newSentenceNbr = sentenceNbr
    while true
      posToWords = Dict()
      context = Dict()
      while newSentenceNbr == sentenceNbr
        push!(posToWords, words[2] => words[3]) # maps word positions to words
        push!(posToWords, words[4] => words[5])
        # creates entry in context dict for words appearing first time in sentence
        if !haskey(context, words[2]) push!(context, words[2] => []) end
        if !haskey(context, words[4]) push!(context, words[4] => []) end
        push!(context[words[2]], words[5]) # adds context to each word in line
        push!(context[words[4]], words[3])

        line = readline(f)
        words = split(line)
        newSentenceNbr = parse(Int32, words[1])
        if position(f) >= end_pos seek(f, start_pos) end
      end
      sentenceNbr = newSentenceNbr

      # adds key word to beginning of context and produces context entry
      for pos in context
        word = posToWords[pos[1]]
        unshift!(context[pos[1]], word)
        produce(context[pos[1]])
      end
    end
  end

  return Task(producer)
end

function count_words(f::IOStream, min_freq::Int=5)
  counts = Dict{AbstractString, Int64}()

  for word in word_iterator(f)
    if get(counts, word, 0) == 0
      counts[word] = 1
    else
      counts[word] += 1
    end
  end

  for word in [keys(counts)...]
    if counts[word] < min_freq
      delete!(counts, word)
    end
  end

  V = length(counts)
  id2word = Array(AbstractString, V)
  freqs = zeros(Int64, V)
  i = 1
  for (word, count) in counts
    id2word[i] = word
    freqs[i] = count
    i += 1
  end

  return freqs, id2word
end

function align(f::IO)
  while !adagram_isblank(read(f, Char))
    continue
  end

  while adagram_isblank(read(f, Char))
    continue
  end

  seek(f, position(f)-1)
end

function read_words(f::IO,
    dict::Dictionary, doc::DenseArray{Int32},
    batch::Int, last_pos::Int)
  words = word_iterator(f, last_pos)
  i = 1
  for j in 1:batch
    word = consume(words)
    id = get(dict.word2id, word, -1)
    if id == -1
      continue
    end

    doc[i] = id
    i += 1
  end

  return view(doc, 1:i-1)
end

function read_words(str::AbstractString,
    dict::Dictionary, doc::DenseArray{Int32},
    batch::Int, last_pos::Int)
  i = 1
  for word in split(str, ' ')
    id = get(dict.word2id, word, -1)
    if id == -1
      continue
    end

    doc[i] = id
    i += 1
  end

  return view(doc, 1:i-1)
end

# Modified to produce a doc where each line has a word followed by
# its context words
function read_words(f::IOStream, start_pos::Int64, end_pos::Int64,
    #dict::Dictionary, doc::DenseArray{Int32},
    dict::Dictionary, batch::Int,
    freqs::DenseArray{Int64}, threshold::Float64,
    words_read::DenseArray{Int64}, total_words::Float64)
  doc = Any[]
  contexts = looped_word_iterator(f, start_pos, end_pos)
  i = 1
  #while i <= length(doc) && words_read[1] < total_words
  while i <= batch && words_read[1] < total_words
    contextLine = consume(contexts)
    #println(contextLine)
    id = get(dict.word2id, contextLine[1], -1)
    if id == -1
      continue
    elseif rand() < 1. - sqrt(threshold / (freqs[id] / total_words))
      words_read[1] += 1
      continue
    end

    idContextLine = [id]
    
    for iContext in 2:length(contextLine)
      idContext = get(dict.word2id, contextLine[iContext], -1)
      if idContext == -1 continue end
      push!(idContextLine, idContext)
    end
    #println(idContextLine, " index: ", i)

    if length(idContextLine) > 1
      push!(doc, idContextLine)
      i += 1
    end
    #println("doc last line ", doc[i])
  end

  return view(doc, 1:i-1)
end
