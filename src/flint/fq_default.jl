###############################################################################
#
#   FqFieldElem.jl : FLINT finite fields
#
###############################################################################

###############################################################################
#
#   Type and parent object methods
#
###############################################################################

parent_type(::Type{FqFieldElem}) = FqField

elem_type(::Type{FqField}) = FqFieldElem

base_ring_type(::Type{FqField}) = typeof(Union{})

base_ring(a::FqField) = Union{}

parent(a::FqFieldElem) = a.parent

is_domain_type(::Type{FqFieldElem}) = true

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function Base.hash(a::FqFieldElem, h::UInt)
  b = 0xb310fb6ea97e1f1a%UInt
  for i in 0:_degree(parent(a)) - 1
    b = xor(b, xor(hash(_coeff(a, i), h), h))
    b = (b << 1) | (b >> (sizeof(Int)*8 - 1))
  end
  return b
end

function _coeff(x::FqFieldElem, n::Int)
  n < 0 && throw(DomainError(n, "Index must be non-negative"))
  z = ZZRingElem()
  @ccall libflint.fq_default_get_coeff_fmpz(z::Ref{ZZRingElem}, x::Ref{FqFieldElem}, n::Int, parent(x)::Ref{FqField})::Nothing
  return z
end

zero(a::FqField) = zero!(a())

one(a::FqField) = one!(a())

function _gen(a::FqField)
  d = a()
  @ccall libflint.fq_default_gen(d::Ref{FqFieldElem}, a::Ref{FqField})::Nothing
  return d
end

iszero(a::FqFieldElem) = @ccall libflint.fq_default_is_zero(a::Ref{FqFieldElem}, a.parent::Ref{FqField})::Bool

isone(a::FqFieldElem) = @ccall libflint.fq_default_is_one(a::Ref{FqFieldElem}, a.parent::Ref{FqField})::Bool

_is_gen(a::FqFieldElem) = a == _gen(parent(a))

function characteristic(a::FqField)
  d = ZZRingElem()
  @ccall libflint.fq_default_ctx_prime(d::Ref{ZZRingElem}, a::Ref{FqField})::Nothing
  return d
end

function order(a::FqField)
  d = ZZRingElem()
  @ccall libflint.fq_default_ctx_order(d::Ref{ZZRingElem}, a::Ref{FqField})::Nothing
  return d
end

function _degree(a::FqField)
  return @ccall libflint.fq_default_ctx_degree(a::Ref{FqField})::Int
end

function deepcopy_internal(d::FqFieldElem, dict::IdDict)
  z = FqFieldElem(parent(d), d)
  return z
end

###############################################################################
#
#   Lifts and conversions
#
###############################################################################

@doc raw"""
    lift(::ZZRing, x::FqFieldElem) -> ZZRingElem

Given an element $x$ of a prime field $\mathbf{F}_p$, return
a preimage under the canonical map $\mathbf{Z} \to \mathbf{F}_p$.

# Examples

```jldoctest
julia> K = GF(19);

julia> lift(ZZ, K(3))
3
```
"""
function lift(R::ZZRing, x::FqFieldElem)
  z = R()
  ok = @ccall libflint.fq_default_get_fmpz(z::Ref{ZZRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Cint
  ok == 0 && error("cannot lift")
  return z
end

function lift(R::ZZPolyRing, x::FqFieldElem)
  p = R()
  !parent(x).isstandard && error("Cannot lift to integer polynomial")
  @ccall libflint.fq_default_get_fmpz_poly(p::Ref{ZZPolyRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Nothing
  return p
end

function (R::zzModPolyRing)(x::FqFieldElem)
  p = R()
  @ccall libflint.fq_default_get_nmod_poly(p::Ref{zzModPolyRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Nothing
  return p
end

function (R::fpPolyRing)(x::FqFieldElem)
  p = R()
  @ccall libflint.fq_default_get_nmod_poly(p::Ref{fpPolyRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Nothing
  return p
end

function (R::ZZModPolyRing)(x::FqFieldElem)
  p = R()
  @ccall libflint.fq_default_get_fmpz_mod_poly(p::Ref{ZZModPolyRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Nothing
  return p
end

function (R::FpPolyRing)(x::FqFieldElem)
  p = R()
  @ccall libflint.fq_default_get_fmpz_mod_poly(p::Ref{FpPolyRingElem}, x::Ref{FqFieldElem}, parent(x)::Ref{FqField})::Nothing
  return p
end

# with FqPolyRepFieldElem
function _unchecked_coerce(a::FqPolyRepField, b::FqFieldElem)
  x = ZZPolyRingElem()
  @ccall libflint.fq_default_get_fmpz_poly(x::Ref{ZZPolyRingElem}, b::Ref{FqFieldElem}, parent(b)::Ref{FqField})::Nothing
  return FqPolyRepFieldElem(a, x)
end

function _unchecked_coerce(a::FqField, b::FqPolyRepFieldElem)
  x = ZZPolyRingElem()
  @ccall libflint.fq_get_fmpz_poly(x::Ref{ZZPolyRingElem}, b::Ref{FqPolyRepFieldElem}, parent(b)::Ref{FqPolyRepField})::Nothing
  return FqFieldElem(a, x)
end

# with zzModRingElem
function _unchecked_coerce(a::fpField, b::FqFieldElem)
  iszero(b) && return zero(a)
  return a(lift(ZZ, b))
end

function _unchecked_coerce(a::FqField, b::fpFieldElem)
  return FqFieldElem(a, lift(b))
end

# with ZZModRingElem
function _unchecked_coerce(a::FpField, b::FqFieldElem)
  iszero(b) && return zero(a)
  return a(lift(ZZ, b))
end

function _unchecked_coerce(a::FqField, b::FpFieldElem)
  return FqFieldElem(a, lift(b))
end

# with fqPolyRepFieldElem
function _unchecked_coerce(a::fqPolyRepField, b::FqFieldElem)
  x = zzModPolyRingElem(UInt(characteristic(a)))
  @ccall libflint.fq_default_get_nmod_poly(x::Ref{zzModPolyRingElem}, b::Ref{FqFieldElem}, parent(b)::Ref{FqField})::Nothing
  y = a()
  @ccall libflint.fq_nmod_set_nmod_poly(y::Ref{fqPolyRepFieldElem}, x::Ref{zzModPolyRingElem}, a::Ref{fqPolyRepField})::Nothing
  return y
end

function _unchecked_coerce(a::FqField, b::fqPolyRepFieldElem)
  x = zzModPolyRingElem(UInt(characteristic(parent(b))))
  @ccall libflint.fq_nmod_get_nmod_poly(x::Ref{zzModPolyRingElem}, b::Ref{fqPolyRepFieldElem}, parent(b)::Ref{fqPolyRepField})::Nothing
  return FqFieldElem(a, x)
end

################################################################################
#
#  Convenience conversion maps
#
################################################################################

const _FQ_DEFAULT_FQ_ZECH   = 1
const _FQ_DEFAULT_FQ_NMOD   = 2
const _FQ_DEFAULT_FQ        = 3
const _FQ_DEFAULT_NMOD      = 4
const _FQ_DEFAULT_FMPZ_NMOD = 5

mutable struct CanonicalFqDefaultMap{T}# <: Map{FqField, T, SetMap, CanonicalFqDefaultMap}
  D::FqField
  C::T
end

domain(f::CanonicalFqDefaultMap) = f.D

codomain(f::CanonicalFqDefaultMap) = f.C

mutable struct CanonicalFqDefaultMapInverse{T}# <: Map{T, FqField, SetMap, CanonicalFqDefaultMapInverse}
  D::T
  C::FqField
end

domain(f::CanonicalFqDefaultMapInverse) = f.D

codomain(f::CanonicalFqDefaultMapInverse) = f.C

function _fq_default_ctx_type(F::FqField)
  return @ccall libflint.fq_default_ctx_type(F::Ref{FqField})::Cint
end

function _get_raw_type(::Type{fqPolyRepField}, F::FqField)
  @assert _fq_default_ctx_type(F) == 2
  Rx, _ = polynomial_ring(Native.GF(UInt(characteristic(F))), "x", cached = false)
  m = map_coefficients(x -> _coeff(x, 0), defining_polynomial(F), parent = Rx)
  return fqPolyRepField(m, :$, false)
end

function _get_raw_type(::Type{FqPolyRepField}, F::FqField)
  @assert _fq_default_ctx_type(F) == 3
  Rx, _ = polynomial_ring(Native.GF(characteristic(F)), "x", cached = false)
  m = map_coefficients(x -> _coeff(x, 0), defining_polynomial(F), parent = Rx)
  return FqPolyRepField(m, :$, false)
end

function canonical_raw_type(::Type{T}, F::FqField) where {T}
  C = _get_raw_type(T, F)
  return CanonicalFqDefaultMap{T}(F, C)
end

function _get_raw_type(::Type{fpField}, F::FqField)
  @assert _fq_default_ctx_type(F) == 4
  return Native.GF(UInt(order(F)), cached = false)
end

function _get_raw_type(::Type{FpField}, F::FqField)
  @assert _fq_default_ctx_type(F) == 5
  return Native.GF(order(F), cached = false)
end

# image/preimage

function image(f::CanonicalFqDefaultMap, x::FqFieldElem)
  @assert parent(x) === f.D
  return _unchecked_coerce(f.C, x)
end

function preimage(f::CanonicalFqDefaultMap, x)
  @assert parent(x) === f.C
  return _unchecked_coerce(f.D, x)
end

(f::CanonicalFqDefaultMap)(x::FqFieldElem) = image(f, x)

# inv

function inv(f::CanonicalFqDefaultMap{T}) where {T}
  return CanonicalFqDefaultMapInverse{T}(f.C, f.D)
end

# image/preimage for inv

function image(f::CanonicalFqDefaultMapInverse, x)
  @assert parent(x) === f.D
  _unchecked_coerce(f.C, x)
end

function preimage(f::CanonicalFqDefaultMapInverse, x::FqFieldElem)
  @assert parent(x) === f.C
  _unchecked_coerce(f.D, x)
end

(f::CanonicalFqDefaultMapInverse)(x) = image(f, x)

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function expressify(a::FqFieldElem; context = nothing)
  x = a.parent.var
  d = degree(a.parent)

  sum = Expr(:call, :+)
  for k in (d - 1):-1:0
    c = is_absolute(parent(a)) ? _coeff(a, k) : coeff(a, k)
    if !iszero(c)
      xk = k < 1 ? 1 : k == 1 ? x : Expr(:call, :^, x, k)
      if isone(c)
        push!(sum.args, Expr(:call, :*, xk))
      else
        push!(sum.args, Expr(:call, :*, expressify(c, context = context), xk))
      end
    end
  end
  return sum
end

show(io::IO, a::FqFieldElem) = print(io, AbstractAlgebra.obj_to_string(a, context = io))

function show(io::IO, a::FqField)
  @show_name(io, a)
  @show_special(io, a)
  io = pretty(io)
  if is_absolute(a)
    deg = degree(a)
    if is_terse(io)
      if deg == 1
        print(io, LowercaseOff(), "GF($(characteristic(a)))")
      else
        print(io, LowercaseOff(), "GF($(characteristic(a)), $(deg))")
      end
    else
      if deg == 1
        print(io, "Prime field of characteristic $(characteristic(a))")
      else
        print(io, "Finite field of degree $(deg) and characteristic $(characteristic(a))")
      end
    end
  else
    if is_terse(io)
      degrees = Int[]
      b = a
      while !is_absolute(b)
        push!(degrees, degree(b))
        b = base_field(b)
      end
      print(io, LowercaseOff(), "GF($(characteristic(a)), $(join(reverse(degrees), '*')))")
    else
      print(io, "Finite field of degree $(degree(a)) over ")
      print(terse(io), base_field(a))
    end
  end
end

###############################################################################
#
#   Unary operations
#
###############################################################################

-(x::FqFieldElem) = neg!(parent(x)(), x)

###############################################################################
#
#   Binary operations
#
###############################################################################

function +(x::FqFieldElem, y::FqFieldElem)
  if parent(x) === parent(y)
    z = parent(y)()
    return add!(z, x, y)
  end
  return +(_promote(x, y)...)
end

function -(x::FqFieldElem, y::FqFieldElem)
  if parent(x) === parent(y)
    z = parent(y)()
    return sub!(z, x, y)
  end
  return -(_promote(x, y)...)
end

function *(x::FqFieldElem, y::FqFieldElem)
  if parent(x) === parent(y)
    z = parent(y)()
    return mul!(z, x, y)
  end
  return *(_promote(x, y)...)
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

for jT in (Integer, ZZRingElem)
  @eval begin
    *(x::FqFieldElem, y::$jT) = mul!(parent(x)(), x, y)
    *(x::$jT, y::FqFieldElem) = mul!(parent(y)(), x, y)
    
    +(x::FqFieldElem, y::$jT) = x + parent(x)(y)
    +(x::$jT, y::FqFieldElem) = y + x
    
    -(x::FqFieldElem, y::$jT) = x - parent(x)(y)
    -(x::$jT, y::FqFieldElem) = parent(y)(x) - y
  end
end

###############################################################################
#
#   Powering
#
###############################################################################

function ^(x::FqFieldElem, y::Int)
  if y < 0
    x = inv(x)
    y = -y
  end
  z = parent(x)()
  @ccall libflint.fq_default_pow_ui(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Int, x.parent::Ref{FqField})::Nothing
  return z
end

function ^(x::FqFieldElem, y::ZZRingElem)
  if y < 0
    x = inv(x)
    y = -y
  end
  z = parent(x)()
  @ccall libflint.fq_default_pow(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{ZZRingElem}, x.parent::Ref{FqField})::Nothing
  return z
end

###############################################################################
#
#   Comparison
#
###############################################################################

function ==(x::FqFieldElem, y::FqFieldElem)
  check_parent(x, y)
  @ccall libflint.fq_default_equal(x::Ref{FqFieldElem}, y::Ref{FqFieldElem}, y.parent::Ref{FqField})::Bool
end

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

==(x::FqFieldElem, y::Integer) = x == parent(x)(y)

==(x::FqFieldElem, y::ZZRingElem) = x == parent(x)(y)

==(x::Integer, y::FqFieldElem) = parent(y)(x) == y

==(x::ZZRingElem, y::FqFieldElem) = parent(y)(x) == y

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(x::FqFieldElem, y::FqFieldElem; check::Bool=true)
  if parent(x) === parent(y)
    iszero(y) && throw(DivideError())
    z = parent(y)()
    @ccall libflint.fq_default_div(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{FqFieldElem}, y.parent::Ref{FqField})::Nothing
    return z
  end
  return divexact(_promote(x, y)...)
end

function divides(a::FqFieldElem, b::FqFieldElem)
  if parent(a) === parent(b)
    if iszero(a)
      return true, zero(parent(a))
    end
    if iszero(b)
      return false, zero(parent(a))
    end
    return true, divexact(a, b)
  end
  return divides(_promote(a, b)...)
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

divexact(x::FqFieldElem, y::Integer; check::Bool=true) = divexact(x, parent(x)(y); check=check)

divexact(x::FqFieldElem, y::ZZRingElem; check::Bool=true) = divexact(x, parent(x)(y); check=check)

divexact(x::Integer, y::FqFieldElem; check::Bool=true) = divexact(parent(y)(x), y; check=check)

divexact(x::ZZRingElem, y::FqFieldElem; check::Bool=true) = divexact(parent(y)(x), y; check=check)

###############################################################################
#
#   Inversion
#
###############################################################################

function inv(x::FqFieldElem)
  iszero(x) && throw(DivideError())
  z = parent(x)()
  @ccall libflint.fq_default_inv(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  return z
end

###############################################################################
#
#   Special functions
#
###############################################################################

function sqrt(x::FqFieldElem)
  z = parent(x)()
  res = Bool(@ccall libflint.fq_default_sqrt(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Cint)
  res || error("Not a square")
  return z
end

function is_square(x::FqFieldElem)
  return Bool(@ccall libflint.fq_default_is_square(x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Cint)
end

function is_square_with_sqrt(x::FqFieldElem)
  z = parent(x)()
  flag = @ccall libflint.fq_default_sqrt(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Cint
  return (Bool(flag), z)
end

@doc raw"""
    pth_root(x::FqFieldElem)

Return the $p$-th root of $x$ in the finite field of characteristic $p$. This
is the inverse operation to the absolute Frobenius map.
"""
function pth_root(x::FqFieldElem)
  z = parent(x)()
  @ccall libflint.fq_default_pth_root(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  return z
end

function _tr(x::FqFieldElem)
  z = ZZRingElem()
  @ccall libflint.fq_default_trace(z::Ref{ZZRingElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  return z
end

function _norm(x::FqFieldElem)
  z = ZZRingElem()
  @ccall libflint.fq_default_norm(z::Ref{ZZRingElem}, x::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  return z
end

function _frobenius(x::FqFieldElem, n = 1)
  z = parent(x)()
  @ccall libflint.fq_default_frobenius(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, n::Int, x.parent::Ref{FqField})::Nothing
  return z
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(z::FqFieldElem)
  @ccall libflint.fq_default_zero(z::Ref{FqFieldElem}, z.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function one!(z::FqFieldElem)
  @ccall libflint.fq_default_one(z::Ref{FqFieldElem}, z.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function neg!(z::FqFieldElem, a::FqFieldElem)
  @ccall libflint.fq_default_neg(z::Ref{FqFieldElem}, a::Ref{FqFieldElem}, a.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

#

function set!(z::FqFieldElem, a::FqFieldElemOrPtr)
  @ccall libflint.fq_default_set(z::Ref{FqFieldElem}, a::Ref{FqFieldElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::Int)
  @ccall libflint.fq_default_set_si(z::Ref{FqFieldElem}, a::Int, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::UInt)
  @ccall libflint.fq_default_set_ui(z::Ref{FqFieldElem}, a::UInt, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::ZZRingElemOrPtr)
  @ccall libflint.fq_default_set_fmpz(z::Ref{FqFieldElem}, a::Ref{ZZRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

set!(z::FqFieldElem, a::Integer) = set!(z, flintify(a))

function set!(z::FqFieldElem, a::ZZPolyRingElemOrPtr)
  @ccall libflint.fq_default_set_fmpz_poly(z::Ref{FqFieldElem}, a::Ref{ZZPolyRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::zzModPolyRingElemOrPtr)
  @ccall libflint.fq_default_set_nmod_poly(z::Ref{FqFieldElem}, a::Ref{zzModPolyRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::fpPolyRingElemOrPtr)
  @ccall libflint.fq_default_set_nmod_poly(z::Ref{FqFieldElem}, a::Ref{fpPolyRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::ZZModPolyRingElemOrPtr)
  @ccall libflint.fq_default_set_fmpz_mod_poly(z::Ref{FqFieldElem}, a::Ref{ZZModPolyRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function set!(z::FqFieldElem, a::FpPolyRingElemOrPtr)
  @ccall libflint.fq_default_set_fmpz_mod_poly(z::Ref{FqFieldElem}, a::Ref{FpPolyRingElem}, parent(z)::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

#

function add!(z::FqFieldElem, x::FqFieldElem, y::FqFieldElem)
  @ccall libflint.fq_default_add(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

#

function sub!(z::FqFieldElem, x::FqFieldElem, y::FqFieldElem)
  @ccall libflint.fq_default_sub(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{FqFieldElem}, x.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

#

function mul!(z::FqFieldElem, x::FqFieldElem, y::FqFieldElem)
  @ccall libflint.fq_default_mul(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{FqFieldElem}, y.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function mul!(z::FqFieldElem, x::FqFieldElem, y::ZZRingElemOrPtr)
  @ccall libflint.fq_default_mul_fmpz(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Ref{ZZRingElem}, x.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function mul!(z::FqFieldElem, x::FqFieldElem, y::Int)
  @ccall libflint.fq_default_mul_si(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Int, x.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

function mul!(z::FqFieldElem, x::FqFieldElem, y::UInt)
  @ccall libflint.fq_default_mul_ui(z::Ref{FqFieldElem}, x::Ref{FqFieldElem}, y::Int, x.parent::Ref{FqField})::Nothing
  z.poly = nothing
  return z
end

mul!(z::FqFieldElem, x::FqFieldElem, y::Integer) = mul!(z, x, flintify(y))

mul!(z::FqFieldElem, x::ZZRingElemOrPtr, y::FqFieldElem) = mul!(z, y, x)
mul!(z::FqFieldElem, x::Integer, y::FqFieldElem) = mul!(z, y, x)

###############################################################################
#
#   Random functions
#
###############################################################################

# define rand(::FqField)

Random.Sampler(::Type{RNG}, R::FqField, n::Random.Repetition) where {RNG<:AbstractRNG} =
Random.SamplerSimple(R, Random.Sampler(RNG, BigInt(0):BigInt(order(R))-1, n))

function rand(rng::AbstractRNG, R::Random.SamplerSimple{FqField})
  F = R[]
  x = _gen(F)
  z = zero(F)
  p = characteristic(F)
  n = ZZRingElem(rand(rng, R.data))
  xi = one(F)
  while !iszero(n)
    n, r = divrem(n, p)
    z += r*xi
    xi *= x
  end
  return z
end

Random.gentype(::Type{FqField}) = elem_type(FqField)

# define rand(make(::FqField, arr)), where arr is any abstract array with integer or ZZRingElem entries

RandomExtensions.maketype(R::FqField, _) = elem_type(R)

rand(rng::AbstractRNG, sp::SamplerTrivial{<:Make2{FqFieldElem,FqField,<:AbstractArray{<:IntegerUnion}}}) =
sp[][1](rand(rng, sp[][2]))

# define rand(::FqField, arr), where arr is any abstract array with integer or ZZRingElem entries

rand(r::Random.AbstractRNG, R::FqField, b::AbstractArray) = rand(r, make(R, b))

rand(R::FqField, b::AbstractArray) = rand(Random.default_rng(), R, b)

###############################################################################
#
#   Modulus
#
###############################################################################

function modulus(R::FpPolyRing, k::FqField)
  Q = R()
  @ccall libflint.fq_default_ctx_modulus(Q::Ref{FpPolyRingElem}, k::Ref{FqField})::Nothing
  return Q
end

function modulus(k::FqField, var::String="T")
  p = characteristic(k)
  Q = polynomial(Native.GF(p), [], var, cached = false)
  @ccall libflint.fq_default_ctx_modulus(Q::Ref{FpPolyRingElem}, k::Ref{FqField})::Nothing
  return Q
end

###############################################################################
#
#   Promotions
#
###############################################################################

promote_rule(::Type{FqFieldElem}, ::Type{T}) where {T <: Integer} = FqFieldElem

promote_rule(::Type{FqFieldElem}, ::Type{ZZRingElem}) = FqFieldElem

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::FqField)()
  z = FqFieldElem(a)
  return z
end

(a::FqField)(b::Integer) = a(ZZRingElem(b))

function (a::FqField)(b::Int)
  z = FqFieldElem(a, b)
  return z
end

function (a::FqField)(b::ZZRingElem)
  z = FqFieldElem(a, b)
  return z
end

function (a::FqField)(b::Rational{<:Integer})
  d = a(denominator(b))
  is_zero(d) && error("Denominator not invertible")
  return a(numerator(b))/d
end

function (a::FqField)(b::QQFieldElem)
  d = a(denominator(b))
  is_zero(d) && error("Denominator not invertible")
  return a(numerator(b))/d
end

function (a::FqField)(b::ZZPolyRingElem)
  if a.isstandard
    z = FqFieldElem(a, b)
  else
    return a.forwardmap(parent(defining_polynomial(a))(b))
  end
  return z
end

function (a::FqField)(b::Union{zzModPolyRingElem, fpPolyRingElem})
  characteristic(parent(b)) != characteristic(a) &&
  error("Incompatible characteristic")
  z = FqFieldElem(a, b)
  return z
end

function (a::FqField)(b::Union{ZZModPolyRingElem, FpPolyRingElem})
  characteristic(parent(b)) != characteristic(a) &&
  error("Incompatible characteristic")
  z = FqFieldElem(a, b)
  return z
end

function (a::FqField)(b::Vector{<:IntegerUnion})
  da = degree(a)
  db = length(b)
  da == db || error("Coercion impossible")
  return a(parent(defining_polynomial(a))(b))
end

###############################################################################
#
#   FqField constructor
#
###############################################################################

@doc raw"""
    finite_field(p::IntegerUnion, d::Int, s::VarName = :o; cached::Bool = true, check::Bool = true)
    finite_field(q::IntegerUnion, s::VarName = :o; cached::Bool = true, check::Bool = true)
    finite_field(f::FqPolyRingElem, s::VarName = :o; cached::Bool = true, check::Bool = true)

Return a tuple $(K, x)$ of a finite field $K$ of order $q = p^d$, where $p$ is a prime,
and a generator $x$ of $K$ (see [`gen`](@ref) for a definition).
The identifier $s$ is used to designate how the finite field generator will be printed.

If a polynomial $f \in k[X]$ over a finite field $k$ is specified,
the finite field $K = k[X]/(f)$ will be constructed as a finite
field with base field $k$.

See also [`GF`](@ref) which only returns $K$.

# Examples

```jldoctest
julia> K, a = finite_field(3, 2, "a")
(Finite field of degree 2 and characteristic 3, a)

julia> K, a = finite_field(9, "a")
(Finite field of degree 2 and characteristic 3, a)

julia> Kx, x = K["x"];

julia> L, b = finite_field(x^3 + x^2 + x + 2, "b")
(Finite field of degree 3 over GF(3, 2), b)
```
"""
finite_field

function finite_field(char::IntegerUnion, deg::Int, s::VarName = :o; cached::Bool = true, check::Bool = true)
  check && !is_prime(char) && error("Characteristic must be prime")
  _char = ZZRingElem(char)
  S = Symbol(s)
  parent_obj = FqField(_char, deg, S, cached)

  return parent_obj, _gen(parent_obj)
end

function finite_field(q::IntegerUnion, s::VarName = :o; cached::Bool = true, check::Bool = true)
  fl, e, p = is_prime_power_with_data(q)
  !fl && error("Order must be a prime power")
  return finite_field(p, e, s; cached = cached, check = false) 
end

function finite_field(f::FqPolyRingElem, s::VarName = :o; cached::Bool = true, check::Bool = true, absolute::Bool = false)
  (check && !is_irreducible(f)) && error("Defining polynomial must be irreducible")
  # Should probably have its own cache
  F = FqField(f, Symbol(s), cached, absolute)
  return F, gen(F)
end

@doc raw"""
    GF(p::IntegerUnion, d::Int, s::VarName = :o; cached::Bool = true, check::Bool = true)
    GF(q::IntegerUnion, s::VarName = :o; cached::Bool = true, check::Bool = true)
    GF(f::FqPolyRingElem, s::VarName = :o; cached::Bool = true, check::Bool = true)

Return a finite field $K$ of order $q = p^d$, where $p$ is a prime.
The identifier $s$ is used to designate how the finite field generator will be printed.

If a polynomial $f \in k[X]$ over a finite field $k$ is specified,
the finite field $K = k[X]/(f)$ will be constructed as a finite
field with base field $k$.

See also [`finite_field`](@ref) which additionally returns a finite field generator of $K$.

# Examples

```jldoctest
julia> K = GF(3, 2, "a")
Finite field of degree 2 and characteristic 3

julia> K = GF(9, "a")
Finite field of degree 2 and characteristic 3

julia> Kx, x = K["x"];

julia> L = GF(x^3 + x^2 + x + 2, "b")
Finite field of degree 3 over GF(3, 2)
```
"""
GF

function GF(q::IntegerUnion, s::VarName = :o; cached::Bool = true, check::Bool = true)
  return finite_field(q, s; cached = cached, check = check)[1]
end

function GF(p::IntegerUnion, d::Int, s::VarName = :o; cached::Bool = true, check::Bool = true)
  return finite_field(p, d, s; cached = cached, check = check)[1]
end

function GF(f::FqPolyRingElem, s::VarName = :o; cached::Bool = true, check::Bool = true, absolute::Bool = false)
  return finite_field(f, s; cached = cached, check = check)[1]
end

################################################################################
#
#  Intersection code
#
################################################################################

# The following code is used in the intersection code
similar(F::FqField, deg::Int, s::VarName = :o; cached::Bool = true) = finite_field(characteristic(F), deg, s, cached = cached)[1]

################################################################################
#
#  Residue field of ZZ
#
################################################################################

function residue_field(R::ZZRing, p::IntegerUnion; cached::Bool = true)
  S = GF(p; cached = cached)
  f = Generic.EuclideanRingResidueMap(R, S)
  return S, f
end

function preimage(f::Generic.EuclideanRingResidueMap{ZZRing, FqField}, x)
  parent(x) !== codomain(f) && error("Not an element of the codomain")
  return lift(ZZ, x)
end

###############################################################################
#
#   Power detection
#
###############################################################################

function is_power(a::Union{fpFieldElem, FpFieldElem, fqPolyRepFieldElem, FqPolyRepFieldElem, FqFieldElem}, m::Int)
  if iszero(a)
    return true, a
  end
  s = order(parent(a))
  if gcd(s - 1, m) == 1
    return true, a^invmod(ZZ(m), s - 1)
  end
  St, t = polynomial_ring(parent(a), :t, cached=false)
  f = t^m - a
  rt = roots(f)
  if length(rt) > 0
    return true, rt[1]
  else
    return false, a
  end
end
