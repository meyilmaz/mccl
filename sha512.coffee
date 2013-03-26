###
Hash a string or an array of words.
@static
@param {bitArray|String} data the data to hash.
@return {bitArray} The hash value, an array of 16 big-endian words.
###
class mccl.hash.sha512 
  constructor: (hash) ->
    @_precompute()  unless @_key[0]
    if hash
      @_h = hash._h.slice(0)
      @_buffer = hash._buffer.slice(0)
      @_length = hash._length
    else
      @reset()
  hash: (data) -> (new mccl.hash.sha512()).update(data).finalize()
  blockSize: 1024
  reset: () ->
    @_h = @_init.slice(0)
    @_buffer = []
    @_length = 0
    return this
  update: (data) ->
    if typeof data == "string"
      data = mccl.codec.utf8String.toBits(data);
    b = @_buffer = mccl.bitArray.concat(@_buffer, data)
    ol = @_length
    nl = @_length = ol + mccl.bitArray.bitLength(data)
    i = 1024 + ol & -1024
    while i <= nl
      @_block b.splice(0, 32)
      i += 1024
    return this;
  finalize: ()->
    i = @_buffer
    b = @_h
    b = mccl.bitArray.concat(b, [mccl.bitArray.partial(1,1)])
    i = b.length + 4
    while i & 31
      b.push(0)
      i++
    b.push(0)
    b.push(0)
    b.push(Math.floor(@_length/ 0x100000000))
    while b.length
      @_block(b.splice(0,32) )
    @reset()
    return this
  _init:[]
  _initr:[ 0xbcc908, 0xcaa73b, 0x94f82b, 0x1d36f1, 0xe682d1, 0x3e6c1f, 0x41bd6b, 0x7e2179 ]
  _key:[]
  _keyr: [0x28ae22, 0xef65cd, 0x4d3b2f, 0x89dbbc, 0x48b538, 0x05d019, 0x194f9b, 0x6d8118,
   0x030242, 0x706fbe, 0xe4b28c, 0xffb4e2, 0x7b896f, 0x1696b1, 0xc71235, 0x692694,
   0xf14ad2, 0x4f25e3, 0x8cd5b5, 0xac9c65, 0x2b0275, 0xa6e483, 0x41fbd4, 0x1153b5,
   0x66dfab, 0xb43210, 0xfb213f, 0xef0ee4, 0xa88fc2, 0x0aa725, 0x03826f, 0x0e6e70,
   0xd22ffc, 0x26c926, 0xc42aed, 0x95b3df, 0xaf63de, 0x77b2a8, 0xedaee6, 0x82353b,
   0xf10364, 0x423001, 0xf89791, 0x54be30, 0xef5218, 0x65a910, 0x71202a, 0xbbd1b8,
   0xd2d0c8, 0x41ab53, 0x8eeb99, 0x9b48a8, 0xc95a63, 0x418acb, 0x63e373, 0xb2b8a3,
   0xefb2fc, 0x172f60, 0xf0ab72, 0x6439ec, 0x631e28, 0x82bde9, 0xc67915, 0x72532b,
   0x26619c, 0xc0c207, 0xe0eb1e, 0x6ed178, 0x176fba, 0xc898a6, 0xf90dae, 0x1c471b,
   0x047d84, 0xc72493, 0xc9bebc, 0x100d4c, 0x3e42b6, 0x657e2a, 0xd6faec, 0x475817]
  _precompute: () ->
    i = 0
    factor = 2
    frac(x) ->  ( x - Math.floor(x) )* 0x100000000 | 0
    frac2(x) -> ( x - Math.floor(x) ) * 0x10000000000 & 0xff
    primes_to_eighty = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79]
    for prime in primes_to_eighty
      if i < 8
        @_init[i*2] = frac( Math.pow(prime, 1/2) )
        @_init[i*2+1] = (frac2( Math.pow(prime, 1/2) ) << 24 ) | @_initr[i];
      @_key[i*2] = frac( Math.pow(prime, 1/3) )
      @_key[ i*2+1] = (frac2( Math.pow(prime, 1/3) ) << 24) | @_keyr[i]
      i++
      
  _block: (words) ->
     i = undefined
    wrh = undefined
    wrl = undefined
    w = words.slice(0)
    h = @_h
    k = @_key
    h0h = h[0]
    h0l = h[1]
    h1h = h[2]
    h1l = h[3]
    h2h = h[4]
    h2l = h[5]
    h3h = h[6]
    h3l = h[7]
    h4h = h[8]
    h4l = h[9]
    h5h = h[10]
    h5l = h[11]
    h6h = h[12]
    h6l = h[13]
    h7h = h[14]
    h7l = h[15]
    # Working variables
    ah = h0h
    al = h0l
    bh = h1h
    bl = h1l
    ch = h2h
    cl = h2l
    dh = h3h
    dl = h3l
    eh = h4h
    el = h4l
    fh = h5h
    fl = h5l
    gh = h6h
    gl = h6l
    hh = h7h
    hl = h7l
    i = 0
    while i < 80
      # load up the input word for this round
      if i < 16
        wrh = w[i * 2]
        wrl = w[i * 2 + 1]
      else      
        # Gamma0
        gamma0xh = w[(i - 15) * 2]
        gamma0xl = w[(i - 15) * 2 + 1]
        gamma0h = ((gamma0xl << 31) | (gamma0xh >>> 1)) ^ ((gamma0xl << 24) | (gamma0xh >>> 8)) ^ (gamma0xh >>> 7)
        gamma0l = ((gamma0xh << 31) | (gamma0xl >>> 1)) ^ ((gamma0xh << 24) | (gamma0xl >>> 8)) ^ ((gamma0xh << 25) | (gamma0xl >>> 7))
      
        # Gamma1
        gamma1xh = w[(i - 2) * 2]
        gamma1xl = w[(i - 2) * 2 + 1]
        gamma1h = ((gamma1xl << 13) | (gamma1xh >>> 19)) ^ ((gamma1xh << 3) | (gamma1xl >>> 29)) ^ (gamma1xh >>> 6)
        gamma1l = ((gamma1xh << 13) | (gamma1xl >>> 19)) ^ ((gamma1xl << 3) | (gamma1xh >>> 29)) ^ ((gamma1xh << 26) | (gamma1xl >>> 6))
      
        # Shortcuts
        wr7h = w[(i - 7) * 2]
        wr7l = w[(i - 7) * 2 + 1]
        wr16h = w[(i - 16) * 2]
        wr16l = w[(i - 16) * 2 + 1]
      
        # W(round) = gamma0 + W(round - 7) + gamma1 + W(round - 16)
        wrl = gamma0l + wr7l
        wrh = gamma0h + wr7h + ((if (wrl >>> 0) < (gamma0l >>> 0) then 1 else 0))
        wrl += gamma1l
        wrh += gamma1h + ((if (wrl >>> 0) < (gamma1l >>> 0) then 1 else 0))
        wrl += wr16l
        wrh += wr16h + ((if (wrl >>> 0) < (wr16l >>> 0) then 1 else 0))
      
      w[i * 2] = wrh |= 0
      w[i * 2 + 1] = wrl |= 0
    
      # Ch
      chh = (eh & fh) ^ (~eh & gh)
      chl = (el & fl) ^ (~el & gl)
    
      # Maj
      majh = (ah & bh) ^ (ah & ch) ^ (bh & ch)
      majl = (al & bl) ^ (al & cl) ^ (bl & cl)
    
      # Sigma0
      sigma0h = ((al << 4) | (ah >>> 28)) ^ ((ah << 30) | (al >>> 2)) ^ ((ah << 25) | (al >>> 7))
      sigma0l = ((ah << 4) | (al >>> 28)) ^ ((al << 30) | (ah >>> 2)) ^ ((al << 25) | (ah >>> 7))
    
      # Sigma1
      sigma1h = ((el << 18) | (eh >>> 14)) ^ ((el << 14) | (eh >>> 18)) ^ ((eh << 23) | (el >>> 9))
      sigma1l = ((eh << 18) | (el >>> 14)) ^ ((eh << 14) | (el >>> 18)) ^ ((el << 23) | (eh >>> 9))
    
      # K(round)
      krh = k[i * 2]
      krl = k[i * 2 + 1]
    
      # t1 = h + sigma1 + ch + K(round) + W(round)
      t1l = hl + sigma1l
      t1h = hh + sigma1h + ((if (t1l >>> 0) < (hl >>> 0) then 1 else 0))
      t1l += chl
      t1h += chh + ((if (t1l >>> 0) < (chl >>> 0) then 1 else 0))
      t1l += krl
      t1h += krh + ((if (t1l >>> 0) < (krl >>> 0) then 1 else 0))
      t1l += wrl
      t1h += wrh + ((if (t1l >>> 0) < (wrl >>> 0) then 1 else 0))
      
      # t2 = sigma0 + maj
      t2l = sigma0l + majl
      t2h = sigma0h + majh + ((if (t2l >>> 0) < (sigma0l >>> 0) then 1 else 0))
      
      # Update working variables
      hh = gh
      hl = gl
      gh = fh
      gl = fl
      fh = eh
      fl = el
      el = (dl + t1l) | 0
      eh = (dh + t1h + ((if (el >>> 0) < (dl >>> 0) then 1 else 0))) | 0
      dh = ch
      dl = cl
      ch = bh
      cl = bl
      bh = ah
      bl = al
      al = (t1l + t2l) | 0
      ah = (t1h + t2h + ((if (al >>> 0) < (t1l >>> 0) then 1 else 0))) | 0
      i++
    
    # Intermediate hash
    h0l = h[1] = (h0l + al) | 0
    h[0] = (h0h + ah + ((if (h0l >>> 0) < (al >>> 0) then 1 else 0))) | 0
    h1l = h[3] = (h1l + bl) | 0
    h[2] = (h1h + bh + ((if (h1l >>> 0) < (bl >>> 0) then 1 else 0))) | 0
    h2l = h[5] = (h2l + cl) | 0
    h[4] = (h2h + ch + ((if (h2l >>> 0) < (cl >>> 0) then 1 else 0))) | 0
    h3l = h[7] = (h3l + dl) | 0
    h[6] = (h3h + dh + ((if (h3l >>> 0) < (dl >>> 0) then 1 else 0))) | 0
    h4l = h[9] = (h4l + el) | 0
    h[8] = (h4h + eh + ((if (h4l >>> 0) < (el >>> 0) then 1 else 0))) | 0
    h5l = h[11] = (h5l + fl) | 0
    h[10] = (h5h + fh + ((if (h5l >>> 0) < (fl >>> 0) then 1 else 0))) | 0
    h6l = h[13] = (h6l + gl) | 0
    h[12] = (h6h + gh + ((if (h6l >>> 0) < (gl >>> 0) then 1 else 0))) | 0
    h7l = h[15] = (h7l + hl) | 0
    h[14] = (h7h + hh + ((if (h7l >>> 0) < (hl >>> 0) then 1 else 0))) | 0      
