# calculates the signature for the request as described in the docs:
# https://dev.twitter.com/docs/auth/creating-signature

#' Generates OAuth1 signature needed to authorize API request
#'
#' @param method f.x. "HMAC-SHA1"
#' @param url f.x. "https://api.twitter.com/1.1/friends/ids.json"
#' @param api f.x. c(cursor=-1, screen_name="hrw", count=10)
#' @param params named vector needed for generating oauth1 signature
#' @return signature string
oauth1_signature <- function(method, url, api, params, test=FALSE) {
  library(RCurl);
  library(digest);
  library(base64enc);
  
  # http://oauth.net/core/1.0/#encoding_parameters
  
  if(curlEscape(".") == ".") {
    # that's how we want it!
  } else if(curlEscape(".") == "%2E") {
    curlEscape <- function(str) {
      esc <- RCurl::curlEscape(str)
      esc <- gsub("%2E",".",esc)
      esc <- gsub("%2D","-",esc)
      esc <- gsub("%5F","_",esc)
      esc <- gsub("%7E","~",esc)
    }
  } else {
    stop("curlEscape('.') is supposed to be either '.' or '%2E'")
  }
    
  secrets <- params[c("consumer_secret","oauth_token_secret")];
  
  # exclude *_secret
  params <- params[! names(params) %in% c("consumer_secret","oauth_token_secret")]
  
  params <- c(api, params);
  params_sorted <- params[sort(names(params))];
  params_escaped <- sapply(params_sorted, curlEscape);
  pstr <- paste(paste(names(params_escaped),"=",params_escaped,sep=""),collapse="&");
  
  # it is important to use curlEscape instead of URLencode because the latter encodes
  # using lower case letters but we need upper case letters. Otherwise the resulting
  # signature will be different from what Twitter/OAuth expects/calculates.
  final <- sprintf("%s&%s&%s",toupper(method), curlEscape(url), curlEscape(pstr));
  
  sig <- sprintf("%s&%s",curlEscape(secrets["consumer_secret"]),curlEscape(secrets["oauth_token_secret"]));
  
  hmac <- hmac(sig,final,algo="sha1",raw=TRUE)
  signature <- base64encode(hmac);
  signature_escaped <- curlEscape(signature);
  
  if(test) {
    return(
      list(
        params_escaped = params_escaped,
        pstr = pstr,
        final = final,
        sig = sig,
        hmac = hmac,
        signature = signature,
        signature_escaped = signature_escaped
      )
    )
  }
  
  return(signature_escaped);
}

