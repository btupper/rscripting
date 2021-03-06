# Argument.R

#' ArgumentRefClass to manage one argument
#'
#' @field name the name of the argument - typically the name provided in the argument string
#' @field flag the characater string used to search for the argument.  By default
#'    the name, prepended by \code{--} or \code{-}.  Allowing name and flag to be different
#'    is to allow the user to specify a name like 'bosworth' for an argumeent flagged as '-b'
#' @field value the parsed argument value as a list.
#' @field choices a list of allowable argument values (like having a dropdown list)
#' @field nargs the number of expected arguments, by default 1
#' @field required logical - must the user provide a value? 
#' @field type charcater specifies the type of argument.  Allowed values are 
#'    \describe{
#'       \item{logical}{Explicitly set TRUE/FALSE arguments}
#'       \item{set_true}{For arguments set by presence ala --plot}
#'       \item{set_false}{For argument set by presence ala --no-plot}
#'       \item{character}{For character arguments}
#'       \item{numeric}{For numeric arguments ala integers and doubles}
#'       \item{integer}{For explictly integer numerics}
#'       \item{double}{For explictly double precision numerics}
#'    }
#' @field action the name of a function to call with the argument
#' @field default the optional default value
#' @field help a character vector of help text
ArgumentRefClass <- setRefClass("ArgumentRefClass",
   fields = list(
      name = 'character',
      flag = 'character',
      value = 'list',
      choices = 'list',
      nargs = 'numeric',
      required = 'logical', # by default FALSE
      type = 'character', #logical, character, integer, double, numeric, set_true, set_false
      action = 'ANY',
      default = 'list',
      help = 'character')
   )

#' Parse the argument list selecting the one of interest
#'
#' @family Argument
#' @name ArgumentRefClass_parse_argument
#' @param x character argument list
#' @return logical indicating success
NULL
ArgumentRefClass$methods(
   parse_argument = function(x){
      parseArgument(.self, x)
   })

#' Print information about the object
#'
#' @family Argument
#' @name ArgumentRefClass_show
NULL
ArgumentRefClass$methods(
   show = function(){
      cat(" Reference Class:", classLabel(class(.self)), "\n")
      cat("    name:", .self$name, "\n")
      cat("    flag:", .self$flag, "\n")
      cat("    type:", .self$type, "\n")
      cat("    value:", .self$value[[1]], "\n")
      cat("    choices:", .self$choices[[1]], "\n")
      cat("    nargs:", .self$nargs, "\n")
      cat("    action:", .self$action, "\n")
      cat("    help:", .self$help, "\n")
   })

#' Print usage help
#'
#' @family Argument
#' @name ArgumentRefClass_print_help
NULL
ArgumentRefClass$methods(
   print_help = function(){
      if (.self$required){
          txt <- sprintf("--%s (required, type '%s')", .self$flag, .self$type)
      } else {
          txt <- sprintf("--%s (type '%s')", .self$flag, .self$type)
      }
      cat(txt,"\n")
      if ((length(.self$help) > 0) && (nchar(.self$help) > 0) ) cat(sprintf("    %s", .self$help),"\n")
      if (length(.self$default) > 0) {
         cat(sprintf("    %s", "default: "))
         if (length(.self$default) == 1) {
            cat(.self$default[[1]], "\n")
         } else {
            print(.self$default)
         }
      }
   })

#' Get usage string
#'
#' @family Argument
#' @name ArgumentRefClass_get_usage
NULL
ArgumentRefClass$methods(
   get_usage = function(){
      sprintf("[--%s %s]", .self$flag, .self$type)
   })
   
#' Run the 'action' function
#' 
#' @family Argument
#' @name ArgumentRefClass_getAction
#' @param ... unspecified arguments
#' @return the value of the argument (type varies)
NULL
ArgumentRefClass$methods(
   getAction = function(...){
      if (!is.null(.self$action) && nchar(.self$action) > 0){
         do.call(.self$action, list(x=.self, ...))      
      } else {
         return(.self$value[[1]])
      }
   })


#' Get the value(s) of an argument
#' 
#' @family Argument
#' @name ArgumentRefClass_get   
#' @param ... unspecified arguments for the Argument$getAction() method
#' @return the value of the argument (type varies)
NULL
ArgumentRefClass$methods(
   get = function(...){
      .self$getAction(...)
   })


######
#     methods above, functions below
######

#' Create an Argument class object
#'
#' @family Argument
#' @export
#' @param name character name of the argument (required)
#' @param flag character the pattern used to search the argument list, by default name
#' @param choices a vector of the choices if limited to a listing
#' @param default the default value if none provided
#' @param required logical, set to TRUE is required otherwise it is optional
#' @param nargs the number of arguments (maximum)
#' @param action a function name or NULL
#' @param type character, one of the following \code{logical, character, integer, double,
#'    numeric, set_true, set_false}  \code{set_true} and \code{set_false} are logicals 
#'    based upon presence/abscence such as --plot or --no-plot  Alternatively,
#'    use 'logical' for "-plot  TRUE" or "-plot  FALSE" style booleans.
#' @param help character vector of helpful hints
#' @return an ArgumentRefClass object
Argument <- function(name, 
   flag = NULL,
   choices = NULL,
   default = NULL,
   required = FALSE,
   nargs = 1,
   action = '', 
   type = 'character',
   help = character()){
   
   x <- ArgumentRefClass$new() 
   if (missing(name)) stop("name is required")
   x$field("name", name[1])
   if (is.null(flag)) flag = x$name
   # be sure to strip any leading dashes
   x$field("flag", gsub("^-+", "", flag))
   x$field("choices", list(choices))
   x$field("default", list(default))
   x$field("value", list(x$default[[1]]))
   x$field("required", required)
   x$field("nargs", nargs)
   x$field("action", action)
   x$field("type", type)
   x$field("help", help)
   x
}


#' Parse the argument character for this Argument's value(s)
#'
#' @family Argument
#' @export
#' @param X the ArgumentRefClass object
#' @param x the argument character vector to mine for flagged value
#' @return logical indicating success/failure
parseArgument <- function(X, x){

   # if flag not present and required then throw a hissy
   flag <- paste0("-+",X$flag)
   ix <- grep(flag, x)
   if ( (length(ix) == 0) && X$required ) { 
      cat(paste("parseArgument: flag not found but is required", X$name), "\n")
      return(FALSE)
   }
   # not provided? then use the default
   if (length(ix) == 0) {
      return(TRUE)
   }
   # set_true, set_false means the argument flag is the value such as 
   # --plot --no-plot which have no trailing value
   # while others will have X$nargs trailing arguments such as 
   # --outfile 'myplot.pdf' which has nargs=1 trailing value
   if (grepl("set_", X$type)){
      arg <- x[ix[1]]
   } else {
      if (X$nargs < 0){
         # if nargs must be guessed at then we guess the next possible flag
         # NOTE we assume flags start with at least '-'
         k <- grep("^-", x)
         j <- k[k > ix[1]]
         if (length(j) == 0) {
            # if there are no further flags then we take the remainder
            iy <- length(x)
         } else {
            # if there are further flags then we go up to but exclude that flag
            iy <- j-1
         }
         index <- seq(from = ix[1]+1, to = iy)
      } else {
         # if nargs are known it is easy (unless the user messed up)
         index <- seq(from = ix[1]+1, to = ix[1]+X$nargs )
      }
      arg <- x[index]
   }
   
   #logical, character, integer, double, numeric, set_true, set_false
   value <- switch(X$type,
       "logical" = (toupper(arg) %in% c("TRUE", "YES", "T", "Y")) ,
       "set_true" =  TRUE,
       "set_false" = FALSE,
       "character" = arg,
       "numeric" = as.numeric(arg),
       "integer" = as.integer(arg),
       "double" = as.double(arg),
       NULL)
   if (is.null(value)) {
      cat(paste("parseArgument: Error converting the value to type -", X$type))
      return(FALSE)
   }
   if (!is.null(X$choices[[1]])) {
      ix <- value %in% X$choices[[1]]
      if (!any(ix)) {
         cat(paste("parseArgument: value not found in choices - value=", value))
         cat(paste("parseArgument: value not found in choices - choices=", 
            paste(X$choices[[1]], collapse = " ") ))
         return(FALSE)
      }
   }

   X$value <- list(value)
   return(TRUE)
}
