################################################################################
#
#  Additional predicate
#
################################################################################

@doc raw"""
    is_absolute(F::FqField)

Return whether the base field of $F$ is a prime field.
"""
is_absolute(F::FqField) = F.isabsolute

################################################################################
#
#  Base field
#
################################################################################

@doc raw"""
    base_field(F::FqField)

Return the base field of `F`.
"""
function base_field(F::FqField)
  # if it is relative, then the base_field will be set
  # otherwise, it is the prime field
  if !isdefined(F, :base_field)
    F.base_field = prime_field(F)
  end

  return F.base_field::FqField
end

################################################################################
#
#  Prime field
#
################################################################################

# Should be cached on the field
@doc raw"""
    prime_field(F::FqField)

Return the prime field of `F`.
"""
function prime_field(F::FqField)
  # We want them to be equal among all finite fields
  return FqField(characteristic(F), 1, :o, true)
end

################################################################################
#
#  Internal coercion into base/prime field
#
################################################################################

# Need this for the trace and norm
function _coerce_to_base_field(a::FqFieldElem)
  L = parent(a)
  K = base_field(L)
  if is_absolute(L)
    return K(lift(ZZ, a))
  else
    return L.preimage_basefield(a)
  end
end

function _coerce_to_prime_field(a::FqFieldElem)
  L = parent(a)
  K = prime_field(L)
  return K(lift(ZZ, a))
end

@doc raw"""
    defining_polynomial([R::FqPolyRing], K::FqField)

Return the defining polynomial of `K` as a polynomial over the
base field of `K`.

If the polynomial ring `R` is specified, the polynomial will be
an element of `R`.

# Examples

```jldoctest
julia> K, a = finite_field(9, "a");

julia> defining_polynomial(K)
x^2 + 2*x + 2

julia> Ky, y = K["y"];

julia> L, b = finite_field(y^3 + y^2 + y + 2, "b");

julia> defining_polynomial(L)
y^3 + y^2 + y + 2
```
"""
function defining_polynomial(R::FqPolyRing, K::FqField)
  coefficient_ring(R) !== base_field(K) && error("Coefficient ring must be base field of finite field")
  f = defining_polynomial(K) # this is cached
  if parent(f) === R
    return f
  else
    g = deepcopy(f)
    g.parent = R
    return g
  end
end

function defining_polynomial(K::FqField)
  if !isdefined(K, :defining_poly)
    @assert K.isstandard
    F, = polynomial_ring(prime_field(K), "x", cached = false)
    K.defining_poly = F(map(lift, collect(coefficients(modulus(K)))))
  end
  return K.defining_poly::FqPolyRingElem
end

################################################################################
#
#  Degree
#
################################################################################

@doc raw"""
    degree(K::FqField) -> Int

Return the degree of the given finite field over the base field.

# Examples

```jldoctest
julia> K, a = finite_field(3, 2, "a");

julia> degree(K)
2

julia> Kx, x = K["x"];

julia> L, b = finite_field(x^3 + x^2 + x + 2, "b");

julia> degree(L)
3
```
"""
function degree(K::FqField)
  if is_absolute(K)
    return _degree(K)
  else
    return degree(defining_polynomial(K))
  end
end

@doc raw"""
    absolute_degree(a::FqField)

Return the degree of the given finite field over the prime field.
"""
function absolute_degree(F::FqField)
  if is_absolute(F)
    return _degree(F)
  else
    return absolute_degree(base_field(F)) * degree(defining_polynomial(F))
  end
end

################################################################################
#
#  Algebra generator
#
################################################################################

@doc raw"""
    gen(L::FqField)

Return a $K$-algebra generator `a` of the finite field $L$, where $K$ is the
base field of $L$. The element `a` satisfies `defining_polyomial(a) == 0`.

Note that this is in general not a multiplicative generator and can be zero, if
$L/K$ is an extension of degree one.
"""
function gen(L::FqField)
  # should not be cached (for in place stuff etc)
  if is_absolute(L)
    return _gen(L)
  else
    L.forwardmap(gen(parent(defining_polynomial(L))))::FqFieldElem
  end
end

@doc raw"""
    is_gen(a::FqFieldElem)

Return `true` if the given finite field element is the generator of the
finite field over its base field, otherwise return `false`.
"""
function is_gen(a::FqFieldElem)
  L = parent(a)
  if is_absolute(L)
    return _is_gen(a)
  else
    return a == L.forwardmap(gen(parent(defining_polynomial(L))))
  end
end

################################################################################
#
#  Write element as polynomial
#
################################################################################

# assumes that we are not absolute, but we are not checking this
function _as_poly(a::FqFieldElem)
  if a.poly !== nothing
    return a.poly::FqPolyRingElem
  else
    g = parent(a).backwardmap(a)
    a.poly = g
    return g::FqPolyRingElem
  end
end

################################################################################
#
#  Coeff
#
################################################################################

@doc raw"""
    coeff(x::FqFieldElem, n::Int) -> FqFieldElem

Given an element $x$ of a finite field $K$, return the degree $n$
coefficient (as an element of the base field) of $x$ when expressed
in the power basis of $K$.

# Examples

```jldoctest
julia> K, a = finite_field(9, "a");

julia> x = 2 * a + 1
2*a + 1

julia> coeff(x, 1)
2

julia> x == sum([coeff(x, i - 1) * basis(K)[i] for i in 1:degree(K)]) ==
            sum([coeff(x, i) * a^i for i in 0:degree(K) - 1])
true
```
"""
function coeff(x::FqFieldElem, n::Int)
  if is_absolute(parent(x))
    return base_field(parent(x))(_coeff(x, n))
  end
  return coeff(_as_poly(x), n)
end

################################################################################
#
#  Frobenius
#
################################################################################

@doc raw"""
    frobenius(x::FqFieldElem, n = 1)

Return the iterated Frobenius $x^{q^n}$ of an element $x$, where $q$ is
the order of the base field. By default the Frobenius map is applied $n =
1$
times if $n$ is not specified.
"""
function frobenius(x::FqFieldElem, n = 1)
  # we want x -> x^#base_field
  z = parent(x)()
  if is_absolute(parent(x))
    m = n
  else
    m = n * absolute_degree(base_field(parent(x)))
  end
  return _frobenius(x, m)
end

@doc raw"""
    absolute_frobenius(x::FqFieldElem, n = 1)

Return the iterated absolute Frobenius $x^{p^n}$, where $p$ is the
characteristic of the parent of $x$. By default the Frobenius map is
applied $n = 1$ times if $n$ is not specified.
"""
function absolute_frobenius(x::FqFieldElem, n = 1)
  return _frobenius(x, n)
end

################################################################################
#
#  Basis
#
################################################################################

@doc raw"""
    basis(F::FqField)

Return the list $1,a,a^2,\dotsc,a^{d-1}$, where $d$ is the degree of $F$
and $a$ its generator.
"""
function basis(F::FqField)
  return powers(gen(F), degree(F) - 1)
end

# internal for now
function _absolute_basis(F::FqField)
  if is_absolute(F)
    return basis(F)
  else
    res = elem_type(F)[]
    kabs = _absolute_basis(base_field(F))
    for b in basis(F)
      for c in kabs
        push!(res, F(c) * b)
      end
    end
    return res
  end
end

################################################################################
#
#  Minimal polynomial
#
################################################################################

function minpoly(a::FqFieldElem)
  return minpoly(polynomial_ring(base_field(parent(a)), "x", cached = false)[1], a)
end

function minpoly(Rx::FqPolyRing, a::FqFieldElem)
  @assert base_ring(Rx) === base_field(parent(a))
  c = [a]
  fa = frobenius(a)
  while !(fa in c)
    push!(c, fa)
    fa = frobenius(fa)
  end
  St = polynomial_ring(parent(a), "x", cached = false)[1]
  f = prod([gen(St) - x for x = c], init = one(St))
  g = Rx()
  for i = 0:degree(f)
    setcoeff!(g, i, _coerce_to_base_field(coeff(f, i)))
  end
  return g
end

function absolute_minpoly(a::FqFieldElem)
  return absolute_minpoly(polynomial_ring(prime_field(parent(a)), "x", cached = false)[1], a)
end

function absolute_minpoly(Rx::FqPolyRing, a::FqFieldElem)
  @assert base_ring(Rx) === prime_field(parent(a))
  c = [a]
  fa = absolute_frobenius(a)
  while !(fa in c)
    push!(c, fa)
    fa = absolute_frobenius(fa)
  end
  St = polynomial_ring(parent(a), "x", cached = false)[1]
  f = prod([gen(St) - x for x = c], init = one(St))
  g = Rx()
  for i = 0:degree(f)
    setcoeff!(g, i, _coerce_to_prime_field(coeff(f, i)))
  end
  return g
end

################################################################################
#
#  Characteristic polynomial
#
################################################################################

function charpoly(a::FqFieldElem)
  return charpoly(polynomial_ring(base_field(parent(a)), "x", cached = false)[1], a)
end

function charpoly(Rx::FqPolyRing, a::FqFieldElem)
  f = minpoly(Rx, a)
  d = divexact(degree(parent(a)), degree(f))
  return f^d
end

function absolute_charpoly(a::FqFieldElem)
  return absolute_charpoly(polynomial_ring(prime_field(parent(a)), "x", cached = false)[1], a)
end

function absolute_charpoly(Rx::FqPolyRing, a::FqFieldElem)
  f = absolute_minpoly(Rx, a)
  d = divexact(absolute_degree(parent(a)), degree(f))
  return f^d
end

################################################################################
#
#  Norm
#
################################################################################

@doc raw"""
    norm(x::FqFieldElem)

Return the norm of $x$. This is an element of the base field.
"""
function norm(a::FqFieldElem)
  # TODO: Should probably use resultant, but _as_poly is not that fast at the
  # moment?
  if is_absolute(parent(a))
    return base_field(parent(a))(_norm(a))
  end
  d = degree(parent(a))
  f = charpoly(a)
  return isodd(d) ? -constant_coefficient(f) : constant_coefficient(f)
end

@doc raw"""
    absolute_norm(x::FqFieldElem)

Return the absolute norm of $x$. This is an element of the prime field.
"""
function absolute_norm(a::FqFieldElem)
  return prime_field(parent(a))(_norm(a))
end

@doc raw"""
    tr(x::FqFieldElem)

Return the trace of $x$. This is an element of the base field.
"""
function tr(a::FqFieldElem)
  if is_absolute(parent(a))
    return base_field(parent(a))(_tr(a))
  end
  d = degree(parent(a))
  f = charpoly(a)
  return -coeff(f, d - 1)
end

@doc raw"""
    absolute_tr(x::FqFieldElem)

Return the absolute trace of $x$. This is an element of the prime field.
"""
function absolute_tr(a::FqFieldElem)
  return prime_field(parent(a))(_tr(a))
end

################################################################################
#
#  Embedding helper
#
################################################################################

# I just need one embedding which I fix once and for all
# This is used to embed K into L \cong K[x]/(f)
# TODO: Improve this or just use embed(K, L) once it works
function _embed(K::FqField, L::FqField)
  if absolute_degree(K) == 1
    return x -> begin
      y = L(coeff(lift(ZZ["x"][1], x), 0))
    end::FqFieldElem
  else
    # must be absolute minpoly
    g = absolute_minpoly(_gen(K))
    e = _embed(prime_field(K), L)
    a = roots(map_coefficients(e, g, cached = false))[1]
    return x -> begin
      return sum(_coeff(x, i)*a^i for i in 0:(absolute_degree(K) - 1))
    end::FqFieldElem
  end
end

################################################################################
#
#  Print the internal presentation for debugging purposes
#
################################################################################

struct _fq_default_dummy
  a
end

function expressify(a::_fq_default_dummy; context = nothing)
  x = a.a.parent.var
  d = _degree(a.a.parent)

  sum = Expr(:call, :+)
  for k in (d - 1):-1:0
    c = _coeff(a.a, k)
    iszero(c) && continue
    xk = k < 1 ? 1 : k == 1 ? x : Expr(:call, :^, x, k)
    push!(sum.args, isone(c) ? Expr(:call, :*, xk) :
          Expr(:call, :*, expressify(c, context = context), xk))
  end
  return sum
end

show_raw(io::IO, a::FqFieldElem) =
println(io, AbstractAlgebra.obj_to_string(_fq_default_dummy(a), context = io))

################################################################################
#
#  Constructor for relative extensions
#
################################################################################

# Given an FqField F and a polynomial f in F[x], we want to construct
# FF = F[x]/(f) together with the map p : F[x] -> FF
#
# There are first two special cases, where F is in fact an
# FpField or an fpfield (in disguise)
# In this case we call directly the corresponding flint function
# to construct FF and p.

function _fq_field_from_fmpz_mod_poly_in_disguise(f::FqPolyRingElem, s::Symbol)
  K = base_ring(f)
  @assert _fq_default_ctx_type(K) == _FQ_DEFAULT_FMPZ_NMOD
  # f is an fmpz_mod_poly in disguise
  # I cannot use the FqField constructor, since f has the wrong type
  # on the julia side
  #
  # The following trick of picking the fmpz_mod_ctx_struct from the fq_default_ctx
  # does not work anymore:
  #
  # It is in K but the first 4 bytes are the type
  # z = @new_struct(FqField) # this is just new() usable outside the type definition
  # z.var = string(s)
  # Temporary hack
  #_K = _get_raw_type(FpField, K)
  # ss = string(s)
  # GC.@preserve K ss begin
  #   ccall((:fq_default_ctx_init_modulus, libflint), Nothing,
  #         (Ref{FqField}, Ref{FqPolyRingElem}, Ptr{Nothing}, Ptr{UInt8}),
  #         #z, f, _K.ninv, string(s))
  #         z, f, pointer_from_objref(K) + 2 * sizeof(Cint), ss)
  #   finalizer(_fq_default_ctx_clear_fn, z)
  # end
  _K = _get_raw_type(FpField, K)
  ff = map_coefficients(c -> _K(lift(ZZ, c)), f; cached = false)
  z = FqField(ff, s, false; check = false)

  z.isabsolute = true
  z.isstandard = true
  z.base_field = K
  z.defining_poly = f
  z.forwardmap = g -> begin
    y = FqFieldElem(z)
    @ccall libflint.fq_default_set_fmpz_mod_poly(y::Ref{FqFieldElem}, g::Ref{FqPolyRingElem}, z::Ref{FqField})::Nothing
    @assert parent(y) === z
    return y
  end
  z.backwardmap = function(g, R = parent(f))
    y = R()
    @ccall libflint.fq_default_get_fmpz_mod_poly(y::Ref{FqPolyRingElem}, g::Ref{FqFieldElem}, z::Ref{FqField})::Nothing
    return y
  end
  return z
end

function _fq_field_from_nmod_poly_in_disguise(f::FqPolyRingElem, s::Symbol)
  K = base_ring(f)
  @assert _fq_default_ctx_type(K) == _FQ_DEFAULT_NMOD
  # f is an nmod_poly in disguise
  # I cannot use the FqField constructor, since f has the wrong type
  # on the julia side
  z = @new_struct(FqField) # this is just new() usable outside the type definition
  z.var = string(s)
  ss = string(s)
  GC.@preserve ss begin
    @ccall libflint.fq_default_ctx_init_modulus_nmod(z::Ref{FqField}, f::Ref{FqPolyRingElem}, ss::Ptr{UInt8})::Nothing
    finalizer(_fq_default_ctx_clear_fn, z)
  end
  z.isabsolute = true
  z.isstandard = true
  z.base_field = K
  z.defining_poly = f
  z.forwardmap = g -> begin
    y = FqFieldElem(z)
    @ccall libflint.fq_default_set_nmod_poly(y::Ref{FqFieldElem}, g::Ref{FqPolyRingElem}, z::Ref{FqField})::Nothing
    return y
  end
  z.backwardmap = function(g, R = parent(f))
    y = R()
    @ccall libflint.fq_default_get_nmod_poly(y::Ref{FqPolyRingElem}, g::Ref{FqFieldElem}, z::Ref{FqField})::Nothing
    return y
  end
  return z
end

const FqDefaultFiniteFieldIDFqDefaultPoly = CacheDictType{Tuple{FqPolyRingElem, Symbol, Bool}, FqField}()

function FqField(f::FqPolyRingElem, s::Symbol, cached::Bool = false, absolute::Bool = false)
  return get_cached!(FqDefaultFiniteFieldIDFqDefaultPoly, (f, s, absolute), cached) do
    K = base_ring(f)
    if absolute_degree(K) == 1
      # K is F_p
      # f is either nmod_poly or fmpz_mod_poly
      # we can define K[t]/(f) directly on the C side with the right modulus
      _fq_ctx_type = _fq_default_ctx_type(K)
      if _fq_ctx_type == _FQ_DEFAULT_NMOD
        z = _fq_field_from_nmod_poly_in_disguise(f, s)
      else
        @assert _fq_ctx_type == _FQ_DEFAULT_FMPZ_NMOD
        z = _fq_field_from_fmpz_mod_poly_in_disguise(f, s)
      end
    else
      # This is the generic case
      p = characteristic(K)
      d = absolute_degree(K) * degree(f)
      # Construct a "standard" copy of F_p^d
      L = FqField(p, d, s, false)
      L.isabsolute = absolute
      L.isstandard = false
      L.defining_poly = f
      L.base_field = K
      # We also need to determine the map K[x]/(f) -> L
      # First embed K into L
      e = _embed(K, L)
      # Push f to L
      Lx, _ = polynomial_ring(L, "\$", cached = false)
      foverL = map_coefficients(e, f, parent = Lx)
      a = roots(foverL)[1]
      # Found the map K[x]/(f) -> L
      forwardmap = y -> evaluate(map_coefficients(e, y, parent = Lx), a)
      Kabs = _absolute_basis(K)
      Fp = prime_field(K)
      # We have no natural coercion Fp -> K
      eabs = _embed(Fp, K)
      # Determine inverse of forwardmap using linear algebra
      # First determine the matrix representing forwardmap
      forwardmat = zero_matrix(Fp, d, d)
      l = 1
      x = gen(parent(f))
      xi = powers(x, degree(f) - 1)
      for i in 0:(degree(f) - 1)
        for b in Kabs
          v = forwardmap(b * xi[i + 1])
          for j in 1:_degree(L)
            forwardmat[l, j] = _coeff(v, j - 1)
          end
          l += 1
        end
      end
      forwardmatinv = inv(forwardmat)
      backwardmap = function(y, R = parent(f))
        w = matrix(Fp, 1, d, [_coeff(y, j - 1) for j in 1:d])
        ww = [Fp(_coeff(y, j - 1)) for j in 1:d]
        _abs_gen_rel = zero(R)
        fl, vv = can_solve_with_solution(forwardmat, w, side = :left)
        vvv = ww * forwardmatinv
        @assert fl
        l = 1
        for i in 0:(degree(f) - 1)
          for b in Kabs
            _abs_gen_rel += eabs(vv[1, l]) * b * xi[i + 1]
            l += 1
          end
        end
        return _abs_gen_rel
      end
      backwardmap_basefield = y -> begin
        w = matrix(Fp, 1, d, [_coeff(y, j - 1) for j in 1:d])
        fl, vv = can_solve_with_solution(forwardmat, w, side = :left)
        @assert fl
        return sum(eabs(vv[1, i]) * Kabs[i] for i in 1:absolute_degree(K))
      end

      L.forwardmap = forwardmap
      L.backwardmap = backwardmap
      L.image_basefield = e
      L.preimage_basefield = backwardmap_basefield
      return L
    end::FqField
  end
end

################################################################################
#
#  Constructors
#
################################################################################

################################################################################
#
#  Fancy coercion
#
################################################################################

function (a::FqField)(b::FqFieldElem)
  k = parent(b)
  if k === a
    return b
  end

  if is_absolute(a)
    da = degree(a)
    dk = degree(k)
    if dk < da
      da % dk != 0 && error("Coercion impossible")
      f = embed(k, a)
      return f(b)
    else
      dk % da != 0 && error("Coercion impossible")
      f = preimage_map(a, k)
      return f(b)
    end
  end

  if k === base_field(a)
    return (a.image_basefield)(b)::FqFieldElem
  end

  # To make it work in towers
  return a(base_field(a)(b))::FqFieldElem
end

################################################################################
#
#  Proper way to construct extension via polynomials
#
################################################################################

# Note: the modulus might be rescaled to be monic
function _residue_field(f::FqPolyRingElem, s = "o"; absolute::Bool = false, check::Bool = true)
  if check
    !is_irreducible(f) && throw(ArgumentError("Polynomial must be irreducible"))
  end
  F = FqField(f, Symbol(s), false, absolute)
  return F, FqPolyRingToFqField(parent(f), F)
end

@attributes mutable struct FqPolyRingToFqField <: Map{FqPolyRing, FqField, SetMap, FqPolyRingToFqField}
  D::FqPolyRing
  C::FqField
  f# the actual map
  g# the inverse

  function FqPolyRingToFqField(R::FqPolyRing, F::FqField)
    z = new(R, F, F.forwardmap, F.backwardmap)
    return z
  end
end

domain(f::FqPolyRingToFqField) = f.D

codomain(f::FqPolyRingToFqField) = f.C

image(f::FqPolyRingToFqField, x::FqPolyRingElem) = f.f(x)::FqFieldElem

(f::FqPolyRingToFqField)(x::FqPolyRingElem) = image(f, x)

preimage(f::FqPolyRingToFqField, x::FqFieldElem) = f.g(x)::FqPolyRingElem

################################################################################
#
#  Coercion of polynomials
#
################################################################################

function (F::FqField)(p::FqPolyRingElem)
  if isdefined(F, :forwardmap)
    parent(p) !== parent(defining_polynomial(F)) && error("Polynomial has wrong coefficient ring")
    return F.forwardmap(p)
  else
    # F was not created using a defining polynomial
    @assert is_absolute(F)
    K = base_field(F)
    characteristic(base_ring(p)) != characteristic(F) && error("Polynomial has wrong coefficient ring")
    _fq_ctx_type = _fq_default_ctx_type(K)
    if _fq_ctx_type == _FQ_DEFAULT_NMOD
      y = FqFieldElem(F)
      @ccall libflint.fq_default_set_nmod_poly(y::Ref{FqFieldElem}, p::Ref{FqPolyRingElem}, F::Ref{FqField})::Nothing
      return y
    else
      @assert _fq_ctx_type == _FQ_DEFAULT_FMPZ_NMOD
      y = FqFieldElem(F)
      @ccall libflint.fq_default_set_fmpz_mod_poly(y::Ref{FqFieldElem}, p::Ref{FqPolyRingElem}, F::Ref{FqField})::Nothing
      return y
    end
  end
end

################################################################################
#
#  Lift
#
################################################################################

function _lift_standard(R::FqPolyRing, a::FqFieldElem)
  K = parent(a)
  F = base_ring(R)
  p = R()
  @assert F === base_field(parent(a))
  _fq_ctx_type = _fq_default_ctx_type(F)
  if _fq_ctx_type == _FQ_DEFAULT_NMOD
    @ccall libflint.fq_default_get_nmod_poly(p::Ref{FqPolyRingElem}, a::Ref{FqFieldElem}, K::Ref{FqField})::Nothing
    return p
  else
    @assert _fq_ctx_type == _FQ_DEFAULT_FMPZ_NMOD
    @ccall libflint.fq_default_get_fmpz_mod_poly(p::Ref{FqPolyRingElem}, a::Ref{FqFieldElem}, K::Ref{FqField})::Nothing
    return p
  end
end

@doc raw"""
    lift(R::FqPolyRing, a::FqFieldElem) -> FqPolyRingElem

Given a polynomial ring over the base field of the parent of `a`, return a lift
such that `parent(a)(lift(R, a)) == a` is `true`.
"""
function lift(R::FqPolyRing, a::FqFieldElem)
  base_ring(R) !== base_field(parent(a)) &&
  error("Polynomial ring has wrong coefficient ring")
  K = parent(a)
  if isdefined(K, :backwardmap)
    return K.backwardmap(a)
  else
    @assert is_absolute(K)
    @assert K.isstandard
    return _lift_standard(R, a)
  end
end

################################################################################
#
#  Promotion
#
################################################################################

function _try_promote(K::FqField, a::FqFieldElem)
  L = parent(a)

  if K === L
    return true, a
  end

  if absolute_degree(L) == 1 && L === base_field(K)
    return true, K(lift(ZZ, a))
  end

  # we have to break the base_field recursion at the prime field
  # apparently, the only way to know if K is *the* prime field, is the property
  # base_field(K) === K

  if base_field(K) === K && K !== L
    return false, a
  end

  fl, b = _try_promote(base_field(K), a)

  if fl
    return fl, K(a)::FqFieldElem
  else
    return false, a
  end
end

function _try_promote(a::FqFieldElem, b::FqFieldElem)
  fl, c = _try_promote(parent(a), b)
  if fl
    return true, a, c
  end
  fl, c = _try_promote(parent(b), a)
  if fl
    return true, c, b
  end
  return false, a, b
end

function _promote(a::FqFieldElem, b::FqFieldElem)
  fl, aa, bb = _try_promote(a, b)
  if fl
    return aa, bb
  end
  error("Cannot promote to common finite field")
end
