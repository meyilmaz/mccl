###
@fileOverview Coffeescript cryptography implementation.


@author M. E. Yilmaz
###
"use strict"

#jslint indent: 2, bitwise: false, nomen: false, plusplus: false, white: false, regexp: false 

#global document, window, escape, unescape 

###
@namespace The Stanford Javascript Crypto Library, top-level namespace.
###
mccl =
  
  ###
  @namespace Symmetric ciphers.
  ###
  cipher: {}
  
  ###
  @namespace Hash functions.  Right now only SHA256 is implemented.
  ###
  hash: {}
  
  ###
  @namespace Key exchange functions.  Right now only SRP is implemented.
  ###
  keyexchange: {}
  
  ###
  @namespace Block cipher modes of operation.
  ###
  mode: {}
  
  ###
  @namespace Miscellaneous.  HMAC and PBKDF2.
  ###
  misc: {}
  
  ###
  @namespace Bit array encoders and decoders.
  
  @description
  The members of this namespace are functions which translate between
  SJCL's bitArrays and other objects (usually strings).  Because it
  isn't always clear which direction is encoding and which is decoding,
  the method names are "fromBits" and "toBits".
  ###
  codec: {}
  
  ###
  @namespace Exceptions.
  ###
  exception:
    
    ###
    @constructor Ciphertext is corrupt.
    ###
    corrupt: (message) ->
      @toString = ->
        "CORRUPT: " + @message

      @message = message

    
    ###
    @constructor Invalid parameter.
    ###
    invalid: (message) ->
      @toString = ->
        "INVALID: " + @message

      @message = message

    
    ###
    @constructor Bug or missing feature in MCCL. @constructor
    ###
    bug: (message) ->
      @toString = ->
        "BUG: " + @message

      @message = message

    
    ###
    @constructor Something isn't ready.
    ###
    notReady: (message) ->
      @toString = ->
        "NOT READY: " + @message

      @message = message

module.exports = mccl  if typeof module isnt "undefined" and module.exports
