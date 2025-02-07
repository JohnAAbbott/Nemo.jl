###############################################################################
#
#   QQAbsPowerSeriesRingElem.jl : Power series over flint QQFieldElem rationals (using QQPolyRingElem)
#
###############################################################################

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

function O(a::QQAbsPowerSeriesRingElem)
  if iszero(a)
    return deepcopy(a)    # 0 + O(x^n)
  end
  prec = length(a) - 1
  prec < 0 && throw(DomainError(prec, "Precision must be non-negative"))
  z = parent(a)()
  z.prec = prec
  z.parent = parent(a)
  return z
end

elem_type(::Type{QQAbsPowerSeriesRing}) = QQAbsPowerSeriesRingElem

parent_type(::Type{QQAbsPowerSeriesRingElem}) = QQAbsPowerSeriesRing

base_ring(R::QQAbsPowerSeriesRing) = QQ

abs_series_type(::Type{QQFieldElem}) = QQAbsPowerSeriesRingElem

var(a::QQAbsPowerSeriesRing) = a.S

###############################################################################
#
#   Basic manipulation
#
###############################################################################

max_precision(R::QQAbsPowerSeriesRing) = R.prec_max

function normalise(a::QQAbsPowerSeriesRingElem, len::Int)
  if len > 0
    c = QQFieldElem()
    @ccall libflint.fmpq_poly_get_coeff_fmpq(c::Ref{QQFieldElem}, a::Ref{QQAbsPowerSeriesRingElem}, (len - 1)::Int)::Nothing
  end
  while len > 0 && iszero(c)
    len -= 1
    if len > 0
      @ccall libflint.fmpq_poly_get_coeff_fmpq(c::Ref{QQFieldElem}, a::Ref{QQAbsPowerSeriesRingElem}, (len - 1)::Int)::Nothing
    end
  end

  return len
end

function coeff(x::QQAbsPowerSeriesRingElem, n::Int)
  if n < 0
    return QQFieldElem(0)
  end
  z = QQFieldElem()
  @ccall libflint.fmpq_poly_get_coeff_fmpq(z::Ref{QQFieldElem}, x::Ref{QQAbsPowerSeriesRingElem}, n::Int)::Nothing
  return z
end

length(x::QQAbsPowerSeriesRingElem) = x.length

precision(x::QQAbsPowerSeriesRingElem) = x.prec

zero(R::QQAbsPowerSeriesRing) = R(0)

one(R::QQAbsPowerSeriesRing) = R(1)

function gen(R::QQAbsPowerSeriesRing)
  z = QQAbsPowerSeriesRingElem([QQFieldElem(0), QQFieldElem(1)], 2, max_precision(R))
  z.parent = R
  return z
end

function deepcopy_internal(a::QQAbsPowerSeriesRingElem, dict::IdDict)
  z = QQAbsPowerSeriesRingElem(a)
  z.prec = a.prec
  z.parent = parent(a)
  return z
end

function is_gen(a::QQAbsPowerSeriesRingElem)
  return precision(a) == 0 || @ccall libflint.fmpq_poly_is_gen(a::Ref{QQAbsPowerSeriesRingElem})::Bool
end

iszero(a::QQAbsPowerSeriesRingElem) = length(a) == 0

is_unit(a::QQAbsPowerSeriesRingElem) = valuation(a) == 0 && is_unit(coeff(a, 0))

function isone(a::QQAbsPowerSeriesRingElem)
  return precision(a) == 0 || @ccall libflint.fmpq_poly_is_one(a::Ref{QQAbsPowerSeriesRingElem})::Bool
end

# todo: write an fmpq_poly_valuation
function valuation(a::QQAbsPowerSeriesRingElem)
  for i = 1:length(a)
    if !iszero(coeff(a, i - 1))
      return i - 1
    end
  end
  return precision(a)
end

characteristic(::QQAbsPowerSeriesRing) = 0

###############################################################################
#
#   Similar
#
###############################################################################

function similar(f::AbsPowerSeriesRingElem, R::QQField, max_prec::Int,
    s::Symbol=var(parent(f)); cached::Bool=true)
  z = QQAbsPowerSeriesRingElem()
  if base_ring(f) === R && s == var(parent(f)) &&
    f isa QQAbsPowerSeriesRingElem && max_precision(parent(f)) == max_prec
    # steal parent in case it is not cached
    z.parent = parent(f)
  else
    z.parent = QQAbsPowerSeriesRing(max_prec, s, cached)
  end
  z.prec = max_prec
  return z
end

###############################################################################
#
#   abs_series constructor
#
###############################################################################

function abs_series(R::QQField, arr::Vector{T},
    len::Int, prec::Int, var::VarName=:x;
    max_precision::Int=prec, cached::Bool=true) where T
  prec < len && error("Precision too small for given data")
  coeffs = T == QQFieldElem ? arr : map(R, arr)
  coeffs = length(coeffs) == 0 ? QQFieldElem[] : coeffs
  z = QQAbsPowerSeriesRingElem(coeffs, len, prec)
  z.parent = QQAbsPowerSeriesRing(max_precision, Symbol(var), cached)
  return z
end

###############################################################################
#
#   Unary operators
#
###############################################################################

function -(x::QQAbsPowerSeriesRingElem)
  z = parent(x)()
  @ccall libflint.fmpq_poly_neg(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem})::Nothing
  z.prec = x.prec
  return z
end

###############################################################################
#
#   Binary operators
#
###############################################################################

function +(a::QQAbsPowerSeriesRingElem, b::QQAbsPowerSeriesRingElem)
  check_parent(a, b)
  lena = length(a)
  lenb = length(b)

  prec = min(a.prec, b.prec)

  lena = min(lena, prec)
  lenb = min(lenb, prec)

  lenz = max(lena, lenb)
  z = parent(a)()
  z.prec = prec
  @ccall libflint.fmpq_poly_add_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, b::Ref{QQAbsPowerSeriesRingElem}, lenz::Int)::Nothing
  return z
end

function -(a::QQAbsPowerSeriesRingElem, b::QQAbsPowerSeriesRingElem)
  check_parent(a, b)
  lena = length(a)
  lenb = length(b)

  prec = min(a.prec, b.prec)

  lena = min(lena, prec)
  lenb = min(lenb, prec)

  lenz = max(lena, lenb)
  z = parent(a)()
  z.prec = prec
  @ccall libflint.fmpq_poly_sub_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, b::Ref{QQAbsPowerSeriesRingElem}, lenz::Int)::Nothing
  return z
end

function *(a::QQAbsPowerSeriesRingElem, b::QQAbsPowerSeriesRingElem)
  check_parent(a, b)
  lena = length(a)
  lenb = length(b)

  aval = valuation(a)
  bval = valuation(b)

  prec = min(a.prec + bval, b.prec + aval)
  prec = min(prec, max_precision(parent(a)))

  lena = min(lena, prec)
  lenb = min(lenb, prec)

  z = parent(a)()
  z.prec = prec

  if lena == 0 || lenb == 0
    return z
  end

  lenz = min(lena + lenb - 1, prec)

  @ccall libflint.fmpq_poly_mullow(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, b::Ref{QQAbsPowerSeriesRingElem}, lenz::Int)::Nothing
  return z
end


###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function *(x::Int, y::QQAbsPowerSeriesRingElem)
  z = parent(y)()
  z.prec = y.prec
  @ccall libflint.fmpq_poly_scalar_mul_si(z::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem}, x::Int)::Nothing
  return z
end

function *(x::ZZRingElem, y::QQAbsPowerSeriesRingElem)
  z = parent(y)()
  z.prec = y.prec
  @ccall libflint.fmpq_poly_scalar_mul_fmpz(z::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem}, x::Ref{ZZRingElem})::Nothing
  return z
end

function *(x::QQFieldElem, y::QQAbsPowerSeriesRingElem)
  z = parent(y)()
  z.prec = y.prec
  @ccall libflint.fmpq_poly_scalar_mul_fmpq(z::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQFieldElem})::Nothing
  return z
end

*(x::QQAbsPowerSeriesRingElem, y::Int) = y*x

*(x::QQAbsPowerSeriesRingElem, y::ZZRingElem) = y*x

*(x::QQAbsPowerSeriesRingElem, y::QQFieldElem) = y*x

*(x::QQAbsPowerSeriesRingElem, y::Integer) = x*ZZRingElem(y)

*(x::Integer, y::QQAbsPowerSeriesRingElem) = ZZRingElem(x)*y

*(x::QQAbsPowerSeriesRingElem, y::Rational) = x*QQFieldElem(y)

*(x::Rational, y::QQAbsPowerSeriesRingElem) = QQFieldElem(x)*y

+(x::QQAbsPowerSeriesRingElem, y::Rational) = x + QQFieldElem(y)

+(x::Rational, y::QQAbsPowerSeriesRingElem) = QQFieldElem(x) + y

-(x::QQAbsPowerSeriesRingElem, y::Rational) = x - QQFieldElem(y)

-(x::Rational, y::QQAbsPowerSeriesRingElem) = QQFieldElem(x) - y

###############################################################################
#
#   Shifting
#
###############################################################################

function shift_left(x::QQAbsPowerSeriesRingElem, len::Int)
  len < 0 && throw(DomainError(len, "Shift must be non-negative"))
  xlen = length(x)
  z = parent(x)()
  z.prec = x.prec + len
  z.prec = min(z.prec, max_precision(parent(x)))
  zlen = min(z.prec, xlen + len)
  @ccall libflint.fmpq_poly_shift_left(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, len::Int)::Nothing
  @ccall libflint.fmpq_poly_set_trunc(z::Ref{QQAbsPowerSeriesRingElem}, z::Ref{QQAbsPowerSeriesRingElem}, zlen::Int)::Nothing
  return z
end

function shift_right(x::QQAbsPowerSeriesRingElem, len::Int)
  len < 0 && throw(DomainError(len, "Shift must be non-negative"))
  xlen = length(x)
  z = parent(x)()
  if len >= xlen
    z.prec = max(0, x.prec - len)
  else
    z.prec = x.prec - len
    @ccall libflint.fmpq_poly_shift_right(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, len::Int)::Nothing
  end
  return z
end

###############################################################################
#
#   Truncation
#
###############################################################################

function truncate(x::QQAbsPowerSeriesRingElem, k::Int)
  return truncate!(deepcopy(x), k)
end

function truncate!(x::QQAbsPowerSeriesRingElem, k::Int)
  k < 0 && throw(DomainError(k, "Index must be non-negative"))
  if precision(x) <= k
    return x
  end
  @ccall libflint.fmpq_poly_truncate(x::Ref{QQAbsPowerSeriesRingElem}, k::Int)::Nothing
  x.prec = k
  return x
end

###############################################################################
#
#   Powering
#
###############################################################################

function ^(a::QQAbsPowerSeriesRingElem, b::Int)
  b < 0 && throw(DomainError(b, "Exponent must be non-negative"))
  # special case powers of x for constructing power series efficiently
  if precision(a) > 0 && is_gen(a) && b > 0
    return shift_left(a, b - 1)
  elseif length(a) == 1
    z = parent(a)(coeff(a, 0)^b)
    z = set_precision!(z, precision(a))
    return z
  elseif b == 0
    z = one(parent(a))
    z = set_precision!(z, precision(a))
    return z
  else
    bit = ~((~UInt(0)) >> 1)
    while (UInt(bit) & b) == 0
      bit >>= 1
    end
    z = a
    bit >>= 1
    while bit !=0
      z = z*z
      if (UInt(bit) & b) != 0
        z *= a
      end
      bit >>= 1
    end
    return z
  end
end

###############################################################################
#
#   Comparison
#
###############################################################################

function ==(x::QQAbsPowerSeriesRingElem, y::QQAbsPowerSeriesRingElem)
  check_parent(x, y)
  prec = min(x.prec, y.prec)

  n = max(length(x), length(y))
  n = min(n, prec)

  return Bool(@ccall libflint.fmpq_poly_equal_trunc(x::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem}, n::Int)::Cint)
end

function isequal(x::QQAbsPowerSeriesRingElem, y::QQAbsPowerSeriesRingElem)
  if parent(x) != parent(y)
    return false
  end
  if x.prec != y.prec || length(x) != length(y)
    return false
  end
  return Bool(@ccall libflint.fmpq_poly_equal(x::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem})::Cint)
end

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

==(x::QQAbsPowerSeriesRingElem, y::Rational{T}) where T <: Union{Int, BigInt} = x == QQFieldElem(y)

==(x::QQAbsPowerSeriesRingElem, y::Integer) = x == ZZRingElem(y)

==(x::Rational{T}, y::QQAbsPowerSeriesRingElem) where T <: Union{Int, BigInt} = y == x

==(x::Integer, y::QQAbsPowerSeriesRingElem) = y == x

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(x::QQAbsPowerSeriesRingElem, y::QQAbsPowerSeriesRingElem; check::Bool=true)
  check_parent(x, y)
  iszero(y) && throw(DivideError())
  v2 = valuation(y)
  v1 = valuation(x)
  if v2 != 0
    if v1 >= v2
      x = shift_right(x, v2)
      y = shift_right(y, v2)
    end
  end
  check && !is_unit(y) && error("Unable to invert power series")
  prec = min(x.prec, y.prec - v2 + v1)
  z = parent(x)()
  z.prec = prec
  @ccall libflint.fmpq_poly_div_series(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQAbsPowerSeriesRingElem}, prec::Int)::Nothing
  return z
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

function divexact(x::QQAbsPowerSeriesRingElem, y::Int; check::Bool=true)
  y == 0 && throw(DivideError())
  z = parent(x)()
  z.prec = x.prec
  @ccall libflint.fmpq_poly_scalar_div_si(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, y::Int)::Nothing
  return z
end

function divexact(x::QQAbsPowerSeriesRingElem, y::ZZRingElem; check::Bool=true)
  iszero(y) && throw(DivideError())
  z = parent(x)()
  z.prec = x.prec
  @ccall libflint.fmpq_poly_scalar_div_fmpz(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, y::Ref{ZZRingElem})::Nothing
  return z
end

function divexact(x::QQAbsPowerSeriesRingElem, y::QQFieldElem; check::Bool=true)
  iszero(y) && throw(DivideError())
  z = parent(x)()
  z.prec = x.prec
  @ccall libflint.fmpq_poly_scalar_div_fmpq(z::Ref{QQAbsPowerSeriesRingElem}, x::Ref{QQAbsPowerSeriesRingElem}, y::Ref{QQFieldElem})::Nothing
  return z
end

divexact(x::QQAbsPowerSeriesRingElem, y::Integer; check::Bool=true) = divexact(x, ZZRingElem(y); check=check)

divexact(x::QQAbsPowerSeriesRingElem, y::Rational{T}; check::Bool=true) where T <: Union{Int, BigInt} = divexact(x, QQFieldElem(y); check=check)

###############################################################################
#
#   Inversion
#
###############################################################################

function inv(a::QQAbsPowerSeriesRingElem)
  iszero(a) && throw(DivideError())
  !is_unit(a) && error("Unable to invert power series")
  ainv = parent(a)()
  ainv.prec = a.prec
  @ccall libflint.fmpq_poly_inv_series(ainv::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return ainv
end

###############################################################################
#
#   Special functions
#
###############################################################################

function Base.exp(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in exp")
  if length(a) == 0 || a.prec == 1
    return parent(a)([QQFieldElem(1)], 1, a.prec)
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_exp_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function log(a::QQAbsPowerSeriesRingElem)
  !isone(coeff(a, 0)) && error("Constant term not one in log")
  if length(a) == 1 || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_log_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function tan(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in tan")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_tan_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function tanh(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in tanh")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_tanh_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function sin(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in sin")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_sin_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function sinh(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in sinh")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_sinh_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function cos(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in cos")
  if length(a) == 0 || a.prec == 1
    return one(parent(a))
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_cos_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function cosh(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in cosh")
  if length(a) == 0 || a.prec == 1
    return one(parent(a))
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_cosh_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function asin(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in asin")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_asin_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function asinh(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in asinh")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_asinh_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function atan(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in atan")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_atan_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function atanh(a::QQAbsPowerSeriesRingElem)
  !iszero(coeff(a, 0)) && error("Constant term not zero in atanh")
  if iszero(a) || a.prec < 2
    return parent(a)()
  end
  z = parent(a)()
  z.prec = a.prec
  @ccall libflint.fmpq_poly_atanh_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  return z
end

function Base.sqrt(a::QQAbsPowerSeriesRingElem; check::Bool=true)
  v = valuation(a)
  z = parent(a)()
  z.prec = a.prec - div(v, 2)
  if iszero(a)
    return z
  end
  check && !iseven(v) && error("Not a square")
  a = shift_right(a, v)
  c = coeff(a, 0)
  s = sqrt(c; check=check)
  a = divexact(a, c)
  z.prec = a.prec - div(v, 2)
  @ccall libflint.fmpq_poly_sqrt_series(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, a.prec::Int)::Nothing
  if !isone(s)
    z *= s
  end
  if !iszero(v)
    z = shift_left(z, div(v, 2))
  end
  return z
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(z::QQAbsPowerSeriesRingElem)
  @ccall libflint.fmpq_poly_zero(z::Ref{QQAbsPowerSeriesRingElem})::Nothing
  z.prec = parent(z).prec_max
  return z
end

function one!(z::QQAbsPowerSeriesRingElem)
  @ccall libflint.fmpq_poly_one(z::Ref{QQAbsPowerSeriesRingElem})::Nothing
  z.prec = parent(z).prec_max
  return z
end

function fit!(z::QQAbsPowerSeriesRingElem, n::Int)
  @ccall libflint.fmpq_poly_fit_length(z::Ref{QQAbsPowerSeriesRingElem}, n::Int)::Nothing
  return nothing
end

function setcoeff!(z::QQAbsPowerSeriesRingElem, n::Int, x::QQFieldElem)
  @ccall libflint.fmpq_poly_set_coeff_fmpq(z::Ref{QQAbsPowerSeriesRingElem}, n::Int, x::Ref{QQFieldElem})::Nothing
  return z
end

function mul!(z::QQAbsPowerSeriesRingElem, a::QQAbsPowerSeriesRingElem, b::QQAbsPowerSeriesRingElem)
  lena = length(a)
  lenb = length(b)

  aval = valuation(a)
  bval = valuation(b)

  prec = min(a.prec + bval, b.prec + aval)
  prec = min(prec, max_precision(parent(a)))

  lena = min(lena, prec)
  lenb = min(lenb, prec)

  lenz = min(lena + lenb - 1, prec)
  if lenz < 0
    lenz = 0
  end

  z.prec = prec
  @ccall libflint.fmpq_poly_mullow(z::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, b::Ref{QQAbsPowerSeriesRingElem}, lenz::Int)::Nothing
  return z
end

function add!(c::QQAbsPowerSeriesRingElem, a::QQAbsPowerSeriesRingElem, b::QQAbsPowerSeriesRingElem)
  lena = length(a)
  lenb = length(b)

  prec = min(a.prec, b.prec)

  lena = min(lena, prec)
  lenb = min(lenb, prec)

  lenc = max(lena, lenb)
  c.prec = prec
  @ccall libflint.fmpq_poly_add_series(c::Ref{QQAbsPowerSeriesRingElem}, a::Ref{QQAbsPowerSeriesRingElem}, b::Ref{QQAbsPowerSeriesRingElem}, lenc::Int)::Nothing
  return c
end

function set_length!(a::QQAbsPowerSeriesRingElem, n::Int)
  @ccall libflint._fmpq_poly_set_length(a::Ref{QQAbsPowerSeriesRingElem}, n::Int)::Nothing
  return a
end

###############################################################################
#
#   Promotion rules
#
###############################################################################

promote_rule(::Type{QQAbsPowerSeriesRingElem}, ::Type{T}) where {T <: Integer} = QQAbsPowerSeriesRingElem

promote_rule(::Type{QQAbsPowerSeriesRingElem}, ::Type{Rational{T}}) where T <: Union{Int, BigInt} = QQAbsPowerSeriesRingElem

promote_rule(::Type{QQAbsPowerSeriesRingElem}, ::Type{ZZRingElem}) = QQAbsPowerSeriesRingElem

promote_rule(::Type{QQAbsPowerSeriesRingElem}, ::Type{QQFieldElem}) = QQAbsPowerSeriesRingElem

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::QQAbsPowerSeriesRing)()
  z = QQAbsPowerSeriesRingElem()
  z.prec = a.prec_max
  z.parent = a
  return z
end

function (a::QQAbsPowerSeriesRing)(b::Integer)
  if b == 0
    z = QQAbsPowerSeriesRingElem()
    z.prec = a.prec_max
  else
    z = QQAbsPowerSeriesRingElem([QQFieldElem(b)], 1, a.prec_max)
  end
  z.parent = a
  return z
end

function (a::QQAbsPowerSeriesRing)(b::ZZRingElem)
  if iszero(b)
    z = QQAbsPowerSeriesRingElem()
    z.prec = a.prec_max
  else
    z = QQAbsPowerSeriesRingElem([QQFieldElem(b)], 1, a.prec_max)
  end
  z.parent = a
  return z
end

function (a::QQAbsPowerSeriesRing)(b::QQFieldElem)
  if iszero(b)
    z = QQAbsPowerSeriesRingElem()
    z.prec = a.prec_max
  else
    z = QQAbsPowerSeriesRingElem([b], 1, a.prec_max)
  end
  z.parent = a
  return z
end

(a::QQAbsPowerSeriesRing)(b::Rational{T}) where T <: Union{Int, BigInt} = a(QQFieldElem(b))

function (a::QQAbsPowerSeriesRing)(b::QQAbsPowerSeriesRingElem)
  parent(b) != a && error("Unable to coerce power series")
  return b
end

function (a::QQAbsPowerSeriesRing)(b::Vector{QQFieldElem}, len::Int, prec::Int)
  z = QQAbsPowerSeriesRingElem(b, len, prec)
  z.parent = a
  return z
end

###############################################################################
#
#   power_series_ring constructor
#
###############################################################################

function power_series_ring(R::QQField, prec::Int, s::VarName; model::Symbol=:capped_relative, cached::Bool = true)
  if model == :capped_relative
    parent_obj = QQRelPowerSeriesRing(prec, Symbol(s), cached)
  elseif model == :capped_absolute
    parent_obj = QQAbsPowerSeriesRing(prec, Symbol(s), cached)
  else
    error("Unknown model")
  end

  return parent_obj, gen(parent_obj)
end

function AbsPowerSeriesRing(R::QQField, prec::Int)
  return QQAbsPowerSeriesRing(prec, :x, false)
end

function RelPowerSeriesRing(R::QQField, prec::Int)
  return QQRelPowerSeriesRing(prec, :x, false)
end
