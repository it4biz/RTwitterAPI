library(RCurl);
library(digest);
library(base64enc);

# calculates the signature for the request as described in the docs:
# https://dev.twitter.com/docs/auth/creating-signature

#' Generates OAuth1 signature needed to authorize API request
#'
#' @param method f.x. "HMAC-SHA1"
#' @param url f.x. "https://api.twitter.com/1.1/friends/ids.json"
#' @param api f.x. c(cursor=-1, screen_name="hrw", count=10)
#' @param params named vector needed for generating oauth1 signature
#' @return signature string
oauth1_signature <- function(method, url, api, params) {
  
  secrets <- params[c("consumer_secret","oauth_token_secret")];
  
  # exclude *_secret
  params <- params[! names(params) %in% c("consumer_secret","oauth_token_secret")]
  
  params <- c(api, params);
  params <- params[sort(names(params))];
  params <- sapply(params, curlEscape);
  pstr <- paste(paste(names(params),"=",params,sep=""),collapse="&");
  
  # it is important to use curlEscape instead of URLencode because the latter encodes
  # using lower case letters but we need upper case letters. Otherwise the resulting
  # signature will be different from what Twitter/OAuth expects/calculates.
  final <- sprintf("%s&%s&%s",toupper(method), curlEscape(url), curlEscape(pstr));
  
  sig <- sprintf("%s&%s",curlEscape(secrets["consumer_secret"]),curlEscape(secrets["oauth_token_secret"]));
  
  signature <- base64encode(hmac(sig,final,algo="sha1",raw=TRUE));
  
  return(curlEscape(signature));
}
