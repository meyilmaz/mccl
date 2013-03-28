###
@constructor
Constructs a new bignum from another bignum, a number or a hex string.
###
mccl.bn = (it) ->
  @initWith it

mccl.bn:: =
  radix: 24
  maxMul: 8
  _class: mccl.bn
  copy: ->
    new @_class(this)


  ###
  Initializes this with it, either as a bn, a number, or a hex string.
  ###
  initWith: (it) ->
    i = 0
    k = undefined
    n = undefined
    l = undefined
    switch typeof it
      when "object"
        @limbs = it.limbs.slice(0)
      when "number"
        @limbs = [it]
        @normalize()
      when "string"
        it = it.replace(/^0x/, "")
        @limbs = []

        # hack
        k = @radix / 4
        i = 0
        while i < it.length
          @limbs.push parseInt(it.substring(Math.max(it.length - i - k, 0), it.length - i), 16)
          i += k
      else
        @limbs = [0]
    this


  ###
  Returns true if "this" and "that" are equal.  Calls fullReduce().
  Equality test is in constant time.
  ###
  equals: (that) ->
    that = new @_class(that)  if typeof that is "number"
    difference = 0
    i = undefined
    @fullReduce()
    that.fullReduce()
    i = 0
    while i < @limbs.length or i < that.limbs.length
      difference |= @getLimb(i) ^ that.getLimb(i)
      i++
    difference is 0


  ###
  Get the i'th limb of this, zero if i is too large.
  ###
  getLimb: (i) ->
    (if (i >= @limbs.length) then 0 else @limbs[i])


  ###
  Constant time comparison function.
  Returns 1 if this >= that, or zero otherwise.
  ###
  greaterEquals: (that) ->
    that = new @_class(that)  if typeof that is "number"
    less = 0
    greater = 0
    i = undefined
    a = undefined
    b = undefined
    i = Math.max(@limbs.length, that.limbs.length) - 1
    while i >= 0
      a = @getLimb(i)
      b = that.getLimb(i)
      greater |= (b - a) & ~less
      less |= (a - b) & ~greater
      i--
    (greater | ~less) >>> 31


  ###
  Convert to a hex string.
  ###
  toString: ->
    @fullReduce()
    out = ""
    i = undefined
    s = undefined
    l = @limbs
    i = 0
    while i < @limbs.length
      s = l[i].toString(16)
      s = "0" + s  while i < @limbs.length - 1 and s.length < 6
      out = s + out
      i++
    "0x" + out


  ###
  this += that.  Does not normalize.
  ###
  addM: (that) ->
    that = new @_class(that)  if typeof (that) isnt "object"
    i = undefined
    l = @limbs
    ll = that.limbs
    i = l.length
    while i < ll.length
      l[i] = 0
      i++
    i = 0
    while i < ll.length
      l[i] += ll[i]
      i++
    this


  ###
  this *= 2.  Requires normalized; ends up normalized.
  ###
  doubleM: ->
    i = undefined
    carry = 0
    tmp = undefined
    r = @radix
    m = @radixMask
    l = @limbs
    i = 0
    while i < l.length
      tmp = l[i]
      tmp = tmp + tmp + carry
      l[i] = tmp & m
      carry = tmp >> r
      i++
    l.push carry  if carry
    this


  ###
  this /= 2, rounded down.  Requires normalized; ends up normalized.
  ###
  halveM: ->
    i = undefined
    carry = 0
    tmp = undefined
    r = @radix
    l = @limbs
    i = l.length - 1
    while i >= 0
      tmp = l[i]
      l[i] = (tmp + carry) >> 1
      carry = (tmp & 1) << r
      i--
    l.pop()  unless l[l.length - 1]
    this


  ###
  this -= that.  Does not normalize.
  ###
  subM: (that) ->
    that = new @_class(that)  if typeof (that) isnt "object"
    i = undefined
    l = @limbs
    ll = that.limbs
    i = l.length
    while i < ll.length
      l[i] = 0
      i++
    i = 0
    while i < ll.length
      l[i] -= ll[i]
      i++
    this

  mod: (that) ->
    neg = not @greaterEquals(new mccl.bn(0))
    that = new mccl.bn(that).normalize() # copy before we begin
    out = new mccl.bn(this).normalize()
    ci = 0
    out = (new mccl.bn(0)).subM(out).normalize()  if neg
    while out.greaterEquals(that)
      that.doubleM()
      ci++
    out = that.sub(out).normalize()  if neg
    while ci > 0
      that.halveM()
      out.subM(that).normalize()  if out.greaterEquals(that)
      ci--
    out.trim()


  ###
  return inverse mod prime p.  p must be odd. Binary extended Euclidean algorithm mod p.
  ###
  inverseMod: (p) ->
    a = new mccl.bn(1)
    b = new mccl.bn(0)
    x = new mccl.bn(this)
    y = new mccl.bn(p)
    tmp = undefined
    i = undefined
    nz = 1
    throw (new mccl.exception.invalid("inverseMod: p must be odd"))  unless p.limbs[0] & 1

    # invariant: y is odd
    loop
      if x.limbs[0] & 1
        unless x.greaterEquals(y)

          # x < y; swap everything
          tmp = x
          x = y
          y = tmp
          tmp = a
          a = b
          b = tmp
        x.subM y
        x.normalize()
        a.addM p  unless a.greaterEquals(b)
        a.subM b

      # cut everything in half
      x.halveM()
      a.addM p  if a.limbs[0] & 1
      a.normalize()
      a.halveM()

      # check for termination: x ?= 0
      i = nz = 0
      while i < x.limbs.length
        nz |= x.limbs[i]
        i++
      break unless nz
    throw (new mccl.exception.invalid("inverseMod: p and x must be relatively prime"))  unless y.equals(1)
    b


  ###
  this + that.  Does not normalize.
  ###
  add: (that) ->
    @copy().addM that


  ###
  this - that.  Does not normalize.
  ###
  sub: (that) ->
    @copy().subM that


  ###
  this * that.  Normalizes and reduces.
  ###
  mul: (that) ->
    that = new @_class(that)  if typeof (that) is "number"
    i = undefined
    j = undefined
    a = @limbs
    b = that.limbs
    al = a.length
    bl = b.length
    out = new @_class()
    c = out.limbs
    ai = undefined
    ii = @maxMul
    i = 0
    while i < @limbs.length + that.limbs.length + 1
      c[i] = 0
      i++
    i = 0
    while i < al
      ai = a[i]
      j = 0
      while j < bl
        c[i + j] += ai * b[j]
        j++
      unless --ii
        ii = @maxMul
        out.cnormalize()
      i++
    out.cnormalize().reduce()


  ###
  this ^ 2.  Normalizes and reduces.
  ###
  square: ->
    @mul this


  ###
  this ^ n.  Uses square-and-multiply.  Normalizes and reduces.
  ###
  power: (l) ->
    if typeof (l) is "number"
      l = [l]
    else l = l.normalize().limbs  if l.limbs isnt `undefined`
    i = undefined
    j = undefined
    out = new @_class(1)
    pow = this
    i = 0
    while i < l.length
      j = 0
      while j < @radix
        out = out.mul(pow)  if l[i] & (1 << j)
        pow = pow.square()
        j++
      i++
    out


  ###
  this * that mod N
  ###
  mulmod: (that, N) ->
    @mod(N).mul(that.mod(N)).mod N


  ###
  this ^ x mod N
  ###
  powermod: (x, N) ->
    result = new mccl.bn(1)
    a = new mccl.bn(this)
    k = new mccl.bn(x)
    loop
      result = result.mulmod(a, N)  if k.limbs[0] & 1
      k.halveM()
      break  if k.equals(0)
      a = a.mulmod(a, N)
    result.normalize().reduce()

  trim: ->
    l = @limbs
    p = undefined
    loop
      p = l.pop()
      break unless l.length and p is 0
    l.push p
    this


  ###
  Reduce mod a modulus.  Stubbed for subclassing.
  ###
  reduce: ->
    this


  ###
  Reduce and normalize.
  ###
  fullReduce: ->
    @normalize()


  ###
  Propagate carries.
  ###
  normalize: ->
    carry = 0
    i = undefined
    pv = @placeVal
    ipv = @ipv
    l = undefined
    m = undefined
    limbs = @limbs
    ll = limbs.length
    mask = @radixMask
    i = 0
    while i < ll or (carry isnt 0 and carry isnt -1)
      l = (limbs[i] or 0) + carry
      m = limbs[i] = l & mask
      carry = (l - m) * ipv
      i++
    limbs[i - 1] -= @placeVal  if carry is -1
    this


  ###
  Constant-time normalize. Does not allocate additional space.
  ###
  cnormalize: ->
    carry = 0
    i = undefined
    ipv = @ipv
    l = undefined
    m = undefined
    limbs = @limbs
    ll = limbs.length
    mask = @radixMask
    i = 0
    while i < ll - 1
      l = limbs[i] + carry
      m = limbs[i] = l & mask
      carry = (l - m) * ipv
      i++
    limbs[i] += carry
    this


  ###
  Serialize to a bit array
  ###
  toBits: (len) ->
    @fullReduce()
    len = len or @exponent or @bitLength()
    i = Math.floor((len - 1) / 24)
    w = mccl.bitArray
    e = (len + 7 & -8) % @radix or @radix
    out = [w.partial(e, @getLimb(i))]
    i--
    while i >= 0
      out = w.concat(out, [w.partial(Math.min(@radix, len), @getLimb(i))])
      len -= @radix
      i--
    out


  ###
  Return the length in bits, rounded up to the nearest byte.
  ###
  bitLength: ->
    @fullReduce()
    out = @radix * (@limbs.length - 1)
    b = @limbs[@limbs.length - 1]
    while b
      out++
      b >>>= 1
    out + 7 & -8


###
@this { mccl.bn }
###
mccl.bn.fromBits = (bits) ->
  Class = this
  out = new Class()
  words = []
  w = mccl.bitArray
  t = @::
  l = Math.min(@bitLength or 0x100000000, w.bitLength(bits))
  e = l % t.radix or t.radix
  words[0] = w.extract(bits, 0, e)
  while e < l
    words.unshift w.extract(bits, e, t.radix)
    e += t.radix
  out.limbs = words
  out

mccl.bn::ipv = 1 / (mccl.bn::placeVal = Math.pow(2, mccl.bn::radix))
mccl.bn::radixMask = (1 << mccl.bn::radix) - 1

###
Creates a new subclass of bn, based on reduction modulo a pseudo-Mersenne prime,
i.e. a prime of the form 2^e + sum(a * 2^b),where the sum is negative and sparse.
###
mccl.bn.pseudoMersennePrime = (exponent, coeff) ->

  ###
  @constructor
  ###
  p = (it) ->
    @initWith it

  #if (this.limbs[this.modOffset]) {
  #      this.reduce();
  #    }
  ppr = p:: = new mccl.bn()
  i = undefined
  tmp = undefined
  mo = undefined
  mo = ppr.modOffset = Math.ceil(tmp = exponent / ppr.radix)
  ppr.exponent = exponent
  ppr.offset = []
  ppr.factor = []
  ppr.minOffset = mo
  ppr.fullMask = 0
  ppr.fullOffset = []
  ppr.fullFactor = []
  ppr.modulus = p.modulus = new mccl.bn(Math.pow(2, exponent))
  ppr.fullMask = 0 | -Math.pow(2, exponent % ppr.radix)
  i = 0
  while i < coeff.length
    ppr.offset[i] = Math.floor(coeff[i][0] / ppr.radix - tmp)
    ppr.fullOffset[i] = Math.ceil(coeff[i][0] / ppr.radix - tmp)
    ppr.factor[i] = coeff[i][1] * Math.pow(1 / 2, exponent - coeff[i][0] + ppr.offset[i] * ppr.radix)
    ppr.fullFactor[i] = coeff[i][1] * Math.pow(1 / 2, exponent - coeff[i][0] + ppr.fullOffset[i] * ppr.radix)
    ppr.modulus.addM new mccl.bn(Math.pow(2, coeff[i][0]) * coeff[i][1])
    ppr.minOffset = Math.min(ppr.minOffset, -ppr.offset[i]) # conservative
    i++
  ppr._class = p
  ppr.modulus.cnormalize()

  ###
  Approximate reduction mod p.  May leave a number which is negative or slightly larger than p.
  @this {mccl.bn}
  ###
  ppr.reduce = ->
    i = undefined
    k = undefined
    l = undefined
    mo = @modOffset
    limbs = @limbs
    aff = undefined
    off_ = @offset
    ol = @offset.length
    fac = @factor
    ll = undefined
    i = @minOffset
    while limbs.length > mo
      l = limbs.pop()
      ll = limbs.length
      k = 0
      while k < ol
        limbs[ll + off_[k]] -= fac[k] * l
        k++
      i--
      unless i
        limbs.push 0
        @cnormalize()
        i = @minOffset
    @cnormalize()
    this


  ###
  @this {mccl.bn}
  ###
  ppr._strongReduce = (if (ppr.fullMask is -1) then ppr.reduce else ->
    limbs = @limbs
    i = limbs.length - 1
    k = undefined
    l = undefined
    @reduce()
    if i is @modOffset - 1
      l = limbs[i] & @fullMask
      limbs[i] -= l
      k = 0
      while k < @fullOffset.length
        limbs[i + @fullOffset[k]] -= @fullFactor[k] * l
        k++
      @normalize()
  )

  ###
  mostly constant-time, very expensive full reduction.
  @this {mccl.bn}
  ###
  ppr.fullReduce = ->
    greater = undefined
    i = undefined

    # massively above the modulus, may be negative
    @_strongReduce()

    # less than twice the modulus, may be negative
    @addM @modulus
    @addM @modulus
    @normalize()

    # probably 2-3x the modulus
    @_strongReduce()

    # less than the power of 2.  still may be more than
    # the modulus

    # HACK: pad out to this length
    i = @limbs.length
    while i < @modOffset
      @limbs[i] = 0
      i++

    # constant-time subtract modulus
    greater = @greaterEquals(@modulus)
    i = 0
    while i < @limbs.length
      @limbs[i] -= @modulus.limbs[i] * greater
      i++
    @cnormalize()
    this


  ###
  @this {mccl.bn}
  ###
  ppr.inverse = ->
    @power @modulus.sub(2)

  p.fromBits = mccl.bn.fromBits
  p


# a small Mersenne prime
mccl.bn.prime =
  p127: mccl.bn.pseudoMersennePrime(127, [[0, -1]])

  # Bernstein's prime for Curve25519
  p25519: mccl.bn.pseudoMersennePrime(255, [[0, -19]])

  # NIST primes
  p192: mccl.bn.pseudoMersennePrime(192, [[0, -1], [64, -1]])
  p224: mccl.bn.pseudoMersennePrime(224, [[0, 1], [96, -1]])
  p256: mccl.bn.pseudoMersennePrime(256, [[0, -1], [96, 1], [192, 1], [224, -1]])
  p384: mccl.bn.pseudoMersennePrime(384, [[0, -1], [32, 1], [96, -1], [128, -1]])
  p521: mccl.bn.pseudoMersennePrime(521, [[0, -1]])

mccl.bn.random = (modulus, paranoia) ->
  modulus = new mccl.bn(modulus)  if typeof modulus isnt "object"
  words = undefined
  i = undefined
  l = modulus.limbs.length
  m = modulus.limbs[l - 1] + 1
  out = new mccl.bn()
  loop

  # get a sequence whose first digits make sense
    loop
      words = mccl.random.randomWords(l, paranoia)
      words[l - 1] += 0x100000000  if words[l - 1] < 0
      break unless Math.floor(words[l - 1] / m) is Math.floor(0x100000000 / m)
    words[l - 1] %= m

    # mask off all the limbs
    i = 0
    while i < l - 1
      words[i] &= modulus.radixMask
      i++

    # check the rest of the digitssj
    out.limbs = words
    return out  unless out.greaterEquals(modulus)