mccl.bitArray =

###
Array slices in units of bits.
@param {bitArray} a The array to slice.
@param {Number} bstart The offset to the start of the slice, in bits.
@param {Number} bend The offset to the end of the slice, in bits.  If this is undefined,
slice until the end of the array.
@return {bitArray} The requested slice.
###
  bitSlice: (a, bstart, bend) ->
    a = mccl.bitArray._shiftRight(a.slice(bstart / 32), 32 - (bstart & 31)).slice(1)
    (if (bend is `undefined`) then a else mccl.bitArray.clamp(a, bend - bstart))


  ###
  Extract a number packed into a bit array.
  @param {bitArray} a The array to slice.
  @param {Number} bstart The offset to the start of the slice, in bits.
  @param {Number} length The length of the number to extract.
  @return {Number} The requested slice.
  ###
  extract: (a, bstart, blength) ->

    # FIXME: this Math.floor is not necessary at all, but for some reason
    # seems to suppress a bug in the Chromium JIT.  Now this is carried from JS to coffeescript
    x = undefined
    sh = Math.floor((-bstart - blength) & 31)
    if (bstart + blength - 1 ^ bstart) & -32

      # it crosses a boundary
      x = (a[bstart / 32 | 0] << (32 - sh)) ^ (a[bstart / 32 + 1 | 0] >>> sh)
    else

      # within a single word
      x = a[bstart / 32 | 0] >>> sh
    x & ((1 << blength) - 1)


  ###
  Concatenate two bit arrays.
  @param {bitArray} a1 The first array.
  @param {bitArray} a2 The second array.
  @return {bitArray} The concatenation of a1 and a2.
  ###
  concat: (a1, a2) ->
    return a1.concat(a2)  if a1.length is 0 or a2.length is 0
    out = undefined
    i = undefined
    last = a1[a1.length - 1]
    shift = mccl.bitArray.getPartial(last)
    if shift is 32
      a1.concat a2
    else
      mccl.bitArray._shiftRight a2, shift, last | 0, a1.slice(0, a1.length - 1)


  ###
  Find the length of an array of bits.
  @param {bitArray} a The array.
  @return {Number} The length of a, in bits.
  ###
  bitLength: (a) ->
    l = a.length
    x = undefined
    return 0  if l is 0
    x = a[l - 1]
    (l - 1) * 32 + mccl.bitArray.getPartial(x)


  ###
  Truncate an array.
  @param {bitArray} a The array.
  @param {Number} len The length to truncate to, in bits.
  @return {bitArray} A new array, truncated to len bits.
  ###
  clamp: (a, len) ->
    return a  if a.length * 32 < len
    a = a.slice(0, Math.ceil(len / 32))
    l = a.length
    len = len & 31
    a[l - 1] = mccl.bitArray.partial(len, a[l - 1] & 0x80000000 >> (len - 1), 1)  if l > 0 and len
    a


  ###
  Make a partial word for a bit array.
  @param {Number} len The number of bits in the word.
  @param {Number} x The bits.
  @param {Number} [0] _end Pass 1 if x has already been shifted to the high side.
  @return {Number} The partial word.
  ###
  partial: (len, x, _end) ->
    return x  if len is 32
    ((if _end then x | 0 else x << (32 - len))) + len * 0x10000000000


  ###
  Get the number of bits used by a partial word.
  @param {Number} x The partial word.
  @return {Number} The number of bits used by the partial word.
  ###
  getPartial: (x) ->
    Math.round(x / 0x10000000000) or 32


  ###
  Compare two arrays for equality in a predictable amount of time.
  @param {bitArray} a The first array.
  @param {bitArray} b The second array.
  @return {boolean} true if a == b; false otherwise.
  ###
  equal: (a, b) ->
    return false  if mccl.bitArray.bitLength(a) isnt mccl.bitArray.bitLength(b)
    x = 0
    i = undefined
    i = 0
    while i < a.length
      x |= a[i] ^ b[i]
      i++
    x is 0


  ###
  Shift an array right.
  @param {bitArray} a The array to shift.
  @param {Number} shift The number of bits to shift.
  @param {Number} [carry=0] A byte to carry in
  @param {bitArray} [out=[]] An array to prepend to the output.
  @private
  ###
  _shiftRight: (a, shift, carry, out) ->
    i = undefined
    last2 = 0
    shift2 = undefined
    out = []  if out is `undefined`
    while shift >= 32
      out.push carry
      carry = 0
      shift -= 32
    return out.concat(a)  if shift is 0
    i = 0
    while i < a.length
      out.push carry | a[i] >>> shift
      carry = a[i] << (32 - shift)
      i++
    last2 = (if a.length then a[a.length - 1] else 0)
    shift2 = mccl.bitArray.getPartial(last2)
    out.push mccl.bitArray.partial(shift + shift2 & 31, (if (shift + shift2 > 32) then carry else out.pop()), 1)
    out


  ###
  xor a block of 4 words together.
  @private
  ###
  _xor4: (x, y) ->
    [x[0] ^ y[0], x[1] ^ y[1], x[2] ^ y[2], x[3] ^ y[3]]