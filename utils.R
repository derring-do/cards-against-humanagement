nsfw <- "love hammer|porn|\\<bsex\\b|\\bass\\b|God|white people|black people|brown people|\\blaid\\b|poop|shit|fuck|up all night|abortion|boob|breast|Viagra|Roofies|boner|Smegma|genital|placenta|handicap|foreskin|hormone|blowjob|handjob|dick|humps|\\bAIDS\\b|fart|penis|sperm|vagina|make love|whipping it out|\\bKKK\\b|seppuku|preteens|balls|bukkake|taking off your shirt|homosexual agenda|bible|nipple|hardworking mexican|asian|testic|holocaust|underwear|\\bbra\\b|boxers|virgin|pedophile|bitch|dead parent|stephen hawking|auschwitz|jews|jewish|lumberjack fantasies|transvestites|fetus|midget|mongoloid|golden showers|butt|thigh|erotica|dead babies|copping a feel|condom|naked|homoerotic|male enhancement|balls deep|erect|panties|wet dream|assault rifle|prostitute|in her pants|in his pants|orgasm|deflower|just the tip|scrotum|larry king|slave|panty|leather daddy|lube|autism|fetal alcohol|double penetration|scrotal|homeless|gang-banged|reverse cowgirl|black male|circumcis|three-fifth|of his mouth|\\banus\\b|female satisfaction|homosex|mexican|stuff a child|the swim team|my first period|suicid|\\banal\\b|deez nuts|September 11|ejacul|\\bcum\\b|cancer|such a big boy|pussy|virgin|masturb|sex|jizz|titty|titties|kiss|gay|blackface|barack obama|milk out of a yak|meaningful relationships|muslim|gender|bazongas|cucumber|manbaby|social justice|cock|cute boy|until he dies|male gaze|chest|casualt|pube|blowing|spectacular abs|mick jagger|daddy|shaft|growing a pair|clitor|incest|dead son|peeing|blood|rehab|safe word|jerking|vomit|have a good time|menstrua|black man|urethral|muhammed|night of passion|oprah|my last relationship|licking|puberty|\\bpee\\b|\\bass|mormon|terrorist|tribe|pregnan|mating display|rehab|pants|first kill|africa|scandinavian|herpes|wifely|martin luther|road head|intimacy|seconds of happiness|lobotomy|sausage|crucifi|strangling|hot people|Incest|man meat|blackula|fisting|legs up to|native american|latino|lover|romantic|black woman|corpse|getting shot|romance|alcoholism|single ladies|interracial|morphine|dinner for two|beating your wives|fat and stupid|neck down|bingeing and purging|child protective|dubai|seagal|albino|dying|japan|tom selleck|estrogen|ethnic|eugenic|rosie|fingering|nudity|friends with benefits|drive-by shot|girls that always|gloryholes|ketamine|hutus|black colleges|hillary clinton|hospice|i drink to forget|mrs. chen|country club|jackie chan|kanye|hannah montana|italians|james is a lonely boy|lactation|kamikaze|leprosy|american indians|hitler|obama|michael jackson|wounds|manservant|necrophilia|obesity|brutality|patient presents with|poor people|queef|quivering|old lady|smallpox|seduc|blind date|suffering|iraqi child|Japanese|mixing of the races|childbirth|third base|in the hole|manslaughter|marriage|orgy|afghan|kung pao|old people|jesus|rape|moses|suffrage|so fat she|pylons|bearded lady|tongue|uncontrollable gas|girl's best friend|drinking|prince ali|hetero|orgasm|Obama|trail of tears"

import_deck <- function(dir, black_file="black.md.txt", white_file="white.md.txt") {
  b <- readLines(file.path(dir, black_file), encoding="UTF-8", warn=FALSE)
  w <- readLines(file.path(dir, white_file), encoding="UTF-8", warn=FALSE)
  black <- data.frame(Label = "Black", prompt = b, src = dir, stringsAsFactors = FALSE)
  white <- data.frame(Label = "White", response = w, src = dir, stringsAsFactors = FALSE)
  deck <- bind_rows(black, white) %>% mutate(
    prompt = gsub("\\\\n", " ", prompt),
    response =  gsub("\\\\n", " ", response)
    # text = as.character(ifelse(!is.na(prompt), prompt, response))
  )
  return(deck)
}


# Text characteristics of card text
describe_deck <- function(deck_df, censor_regex=NULL) { 
  # deck_df <- decks[[1]]
  deck_df$remove = NA
  deck_df$text = as.character(ifelse(!is.na(deck_df$prompt), deck_df$prompt, deck_df$response)) # for easier censoring later
  deck_df$whiteIsSingular[deck_df$Label=="White"] <- grepl("\\<The\\b|\\<A\\b|\\<An\\b", deck_df %>% filter(Label=="White") %>% pull(response))
  deck_df$whiteIsGerund[deck_df$Label=="White"] <- grepl("^[[:alpha:]]+?ing\\b", deck_df %>% filter(Label=="White") %>% pull(response))
  deck_df$blackBlankCount[deck_df$Label=="Black"] <- str_count(deck_df %>% filter(Label=="Black") %>% pull(prompt), "_")
  dd <- dummy_cols(deck_df, "blackBlankCount") # make sure NAs stay for white cards
  
  if(!is.null(censor_regex)) {
    # censor_regex = "the"
    dd <- dd %>% mutate(remove = ifelse(grepl(censor_regex, text, ignore.case=TRUE), TRUE, FALSE))
  }
  
  return(dd)
}
# describe_deck(decks[[1]]) 
# describe_deck(decks[[1]], censor_regex = "the") 

# Make quick df to see random prompts/responses side by side
sample_deck <- function(df, size=10) {
  data.frame(
    a=df %>% filter(Label=="Black") %>% pull(prompt) %>% sample(., size),
    b=df %>% filter(Label=="White") %>% pull(response) %>% sample(., size)
  )
}
# sample_deck(decks[[1]])

# Aggregate stats for a deck
benchmark_deck <- function(df, return=c("df", "benchmark"), filter_df=TRUE, ...) {
  # df <- decks[[1]]
  # df expects cols Label = Black|White, prompt, response
  deckname = deparse(substitute(df))
  df <- describe_deck(df, ...) 
  
  if(filter_df==TRUE) {
    df <- df %>% filter(remove!=TRUE | is.na(remove)) # where to put this so you still get the score???
  }
  
  # df <- describe_deck(df) %>% filter(remove!=TRUE | is.na(remove)) 
  bd1 <- df %>% 
    summarise(
      deck = deckname,
      n = nrow(.),
      n_black = sum(grepl("Black", Label)),
      n_white = sum(grepl("White", Label)),
      pct_black = n_black/(n_black+n_white),
      pct_white = n_white/(n_black+n_white),
      pct_white_singular = mean(whiteIsSingular, na.rm=TRUE),
      pct_white_gerund = mean(whiteIsGerund, na.rm=TRUE)
    ) 
  bd2 <- df %>% summarise_at(vars(matches("BlankCount_")), mean, na.rm=TRUE)
  bd <- cbind(bd1, bd2) %>% mutate_if(.<1, percent, accuracy=1)
  # attr(df, "benchmarks") <- bd
  
  switch(return, df = return(df), benchmark = return(bd))
}

# benchmark_deck(decks[["Base"]], "df")
# benchmark_deck(decks[["Base"]], "benchmark")
# lapply(decks, benchmark_deck, "benchmark") %>% bind_rows %>% {.$deck <- names(decks); .}

