# Process document into SQLite Database
library(tm)
library(RSQLite)
source('utility.R')

twitter <- readTextFile('./data/en_US/en_US.twitter.txt',"UTF-8")
blogs <- readTextFile('./data/en_US/en_US.blogs.txt',"UTF-8" )
news <- readTextFile('./data/en_US/en_US.news.txt', "UTF-8")

twitter.s <- sampleTextData(twitter, .0013)
blogs.s <- sampleTextData(blogs, .0013)
news.s <- sampleTextData(news, .0013)

rm(list=c('twitter','blogs','news'))

save( twitter.s, blogs.s, news.s, file = 'smalldata.RData')

#twitter <- samplefile('../data/en_US/en_US.twitter.txt', .013)
#blogs <- samplefile('../data/en_US/en_US.blogs.txt', .013)
#news <- samplefile('../data/en_US/en_US.news.txt', .013)

tCorp <- getCorpus2(twitter.s)
bCorp <- getCorpus2(blogs.s)
nCorp <- getCorpus2(news.s)

tdm_2 <- TermDocumentMatrix(c(tCorp, bCorp, nCorp), control = list(tokenize = BigramTokenizer)) 
tdm_3 <- TermDocumentMatrix(c(tCorp, bCorp, nCorp), control = list(tokenize = TrigramTokenizer))
tdm_4 <- TermDocumentMatrix(c(tCorp, bCorp, nCorp), control = list(tokenize = QuadgramTokenizer))
tdm_5 <- TermDocumentMatrix(c(tCorp, bCorp, nCorp), control = list(tokenize = PentagramTokenizer))

rm(tCorp,bCorp,nCorp)

db <- dbConnect(SQLite(), dbname="train.db")
dbSendQuery(conn=db,
            "CREATE TABLE NGram
            (pre TEXT,
            word TEXT,
            freq INTEGER,
            n INTEGER)")  # ROWID automatically created with SQLite dialect

# Get word frequencies
freq_5 <- tdmToFreq(tdm_5)
freq_4 <- tdmToFreq(tdm_4)
freq_3 <- tdmToFreq(tdm_3)
freq_2 <- tdmToFreq(tdm_2)

# Process with pre and current word
processGram(freq_5)
processGram(freq_4)
processGram(freq_3)
processGram(freq_2)

# Insert into SQLite database
sql_5 <- "INSERT INTO NGram VALUES ($pre, $cur, $freq, 5)"
bulk_insert(sql_5, freq_5)
sql_4 <- "INSERT INTO NGram VALUES ($pre, $cur, $freq, 4)"
bulk_insert(sql_4, freq_4)
sql_3 <- "INSERT INTO NGram VALUES ($pre, $cur, $freq, 3)"
bulk_insert(sql_3, freq_3)
sql_2 <- "INSERT INTO NGram VALUES ($pre, $cur, $freq, 2)"
bulk_insert(sql_2, freq_2)

dbDisconnect(db)