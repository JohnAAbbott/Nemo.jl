################################################################################
#
#  gfp_mat.jl: flint gfp_mat types in julia for small prime modulus
#
################################################################################

################################################################################
#
#  Data type and parent object methods
#
################################################################################

dense_matrix_type(::Type{fpFieldElem}) = fpMatrix

is_zero_initialized(::Type{fpMatrix}) = true

################################################################################
#
#  Manipulation
#
################################################################################

# v.data is immutable so we can't do anything in-place
getindex!(v::fpFieldElem, a::fpMatrix, i::Int, j::Int) = getindex(a, i, j)

@inline function getindex(a::fpMatrix, i::Int, j::Int)
  @boundscheck _checkbounds(a, i, j)
  u = getindex_raw(a, i, j)
  return fpFieldElem(u, base_ring(a)) # no reduction needed
end

@inline function setindex!(a::fpMatrix, u::fpFieldElem, i::Int, j::Int)
  @boundscheck _checkbounds(a, i, j)
  (base_ring(a) != parent(u)) && error("Parent objects must coincide")
  setindex_raw!(a, u.data, i, j) # no reduction necessary
end

function setindex!(a::fpMatrix, b::fpMatrix, r::UnitRange{Int64}, c::UnitRange{Int64})
  _checkbounds(a, r, c)
  size(b) == (length(r), length(c)) || throw(DimensionMismatch("tried to assign a $(size(b, 1))x$(size(b, 2)) matrix to a $(length(r))x$(length(c)) destination"))
  A = view(a, r, c)
  @ccall libflint.nmod_mat_set(A::Ref{fpMatrix}, b::Ref{fpMatrix})::Nothing
end

function deepcopy_internal(a::fpMatrix, dict::IdDict)
  z = fpMatrix(nrows(a), ncols(a), modulus(base_ring(a)))
  if isdefined(a, :base_ring)
    z.base_ring = a.base_ring
  end
  @ccall libflint.nmod_mat_set(z::Ref{fpMatrix}, a::Ref{fpMatrix})::Nothing
  return z
end

function one(a::fpMatrixSpace)
  check_square(a)
  return one!(a())
end

################################################################################
#
#  Ad hoc binary operators
#
################################################################################

function *(x::fpMatrix, y::fpFieldElem)
  (base_ring(x) != parent(y)) && error("Parent objects must coincide")
  return x*y.data
end

*(x::fpFieldElem, y::fpMatrix) = y*x

################################################################################
#
#  Row reduced echelon form
#
################################################################################

function rref(a::fpMatrix)
  z = deepcopy(a)
  r = @ccall libflint.nmod_mat_rref(z::Ref{fpMatrix})::Int
  return r, z
end

function rref!(a::fpMatrix)
  r = @ccall libflint.nmod_mat_rref(a::Ref{fpMatrix})::Int
  return r
end

################################################################################
#
#  Strong echelon form and Howell form
#
################################################################################

@doc raw"""
    strong_echelon_form(a::fpMatrix)

Return the strong echeleon form of $a$. The matrix $a$ must have at least as
many rows as columns.
"""
function strong_echelon_form(a::fpMatrix)
  (nrows(a) < ncols(a)) &&
  error("Matrix must have at least as many rows as columns")
  r, z = rref(a)
  j_new =  1
  for i in 1:r
    for j in j_new:ncols(a)
      if isone(a[i, j]) && i != j
        z[i, j] = 0
        z[j, j] = 1
        j_new = j
        continue
      end
    end
  end
  return z
end

@doc raw"""
    howell_form(a::fpMatrix)

Return the Howell normal form of $a$. The matrix $a$ must have at least as
many rows as columns.
"""
function howell_form(a::fpMatrix)
  (nrows(a) < ncols(a)) &&
  error("Matrix must have at least as many rows as columns")
  return rref(a)[2]
end

################################################################################
#
#  Determinant
#
################################################################################

function det(a::fpMatrix)
  !is_square(a) && error("Matrix must be a square matrix")
  r = @ccall libflint.nmod_mat_det(a::Ref{fpMatrix})::UInt
  return base_ring(a)(r)
end

################################################################################
#
#  Windowing
#
################################################################################

function _view_window(x::fpMatrix, r1::Int, c1::Int, r2::Int, c2::Int)

  _checkrange_or_empty(nrows(x), r1, r2) ||
  Base.throw_boundserror(x, (r1:r2, c1:c2))

  _checkrange_or_empty(ncols(x), c1, c2) ||
  Base.throw_boundserror(x, (r1:r2, c1:c2))

  if (r1 > r2)
    r1 = 1
    r2 = 0
  end
  if (c1 > c2)
    c1 = 1
    c2 = 0
  end

  z = fpMatrix()
  z.base_ring = x.base_ring
  z.view_parent = x
  @ccall libflint.nmod_mat_window_init(z::Ref{fpMatrix}, x::Ref{fpMatrix}, (r1 - 1)::Int, (c1 - 1)::Int, r2::Int, c2::Int)::Nothing
  finalizer(_gfp_mat_window_clear_fn, z)
  return z
end

function _gfp_mat_window_clear_fn(a::fpMatrix)
  @ccall libflint.nmod_mat_window_clear(a::Ref{fpMatrix})::Nothing
end

################################################################################
#
#  Characteristic polynomial
#
################################################################################

function charpoly(R::fpPolyRing, a::fpMatrix)
  m = deepcopy(a)
  p = R()
  @ccall libflint.nmod_mat_charpoly(p::Ref{fpPolyRingElem}, m::Ref{fpMatrix})::Nothing
  return p
end

################################################################################
#
#  Minimal polynomial
#
################################################################################

function minpoly(R::fpPolyRing, a::fpMatrix)
  p = R()
  @ccall libflint.nmod_mat_minpoly(p::Ref{fpPolyRingElem}, a::Ref{fpMatrix})::Nothing
  return p
end

###############################################################################
#
#   Promotion rules
#
###############################################################################

promote_rule(::Type{fpMatrix}, ::Type{V}) where {V <: Integer} = fpMatrix

promote_rule(::Type{fpMatrix}, ::Type{fpFieldElem}) = fpMatrix

promote_rule(::Type{fpMatrix}, ::Type{ZZRingElem}) = fpMatrix

################################################################################
#
#  Inverse
#
################################################################################

function inv(a::fpMatrix)
  !is_square(a) && error("Matrix must be a square matrix")
  z = similar(a)
  r = @ccall libflint.nmod_mat_inv(z::Ref{fpMatrix}, a::Ref{fpMatrix})::Int
  !Bool(r) && error("Matrix not invertible")
  return z
end

################################################################################
#
#   Linear solving
#
################################################################################

Solve.matrix_normal_form_type(::fpField) = Solve.LUTrait()
Solve.matrix_normal_form_type(::fpMatrix) = Solve.LUTrait()

function Solve._can_solve_internal_no_check(::Solve.LUTrait, A::fpMatrix, b::fpMatrix, task::Symbol; side::Symbol = :left)
  if side === :left
    fl, sol, K = Solve._can_solve_internal_no_check(Solve.LUTrait(), transpose(A), transpose(b), task, side = :right)
    return fl, transpose(sol), transpose(K)
  end

  x = similar(A, ncols(A), ncols(b))
  fl = @ccall libflint.nmod_mat_can_solve(x::Ref{fpMatrix}, A::Ref{fpMatrix}, b::Ref{fpMatrix})::Cint
  if task === :only_check || task === :with_solution
    return Bool(fl), x, zero(A, 0, 0)
  end
  return Bool(fl), x, kernel(A, side = :right)
end

# Direct interface to the C functions to be able to write 'generic' code for
# different matrix types
function _solve_tril_right_flint!(x::fpMatrix, L::fpMatrix, B::fpMatrix, unit::Bool)
  @ccall libflint.nmod_mat_solve_tril(x::Ref{fpMatrix}, L::Ref{fpMatrix}, B::Ref{fpMatrix}, Cint(unit)::Cint)::Nothing
  return nothing
end

function _solve_triu_right_flint!(x::fpMatrix, U::fpMatrix, B::fpMatrix, unit::Bool)
  @ccall libflint.nmod_mat_solve_triu(x::Ref{fpMatrix}, U::Ref{fpMatrix}, B::Ref{fpMatrix}, Cint(unit)::Cint)::Nothing
  return nothing
end

################################################################################
#
#  Parent object overloading
#
################################################################################

function (a::fpMatrixSpace)()
  z = fpMatrix(base_ring(a), undef, nrows(a), ncols(a))
  return z
end

function (a::fpMatrixSpace)(arr::AbstractVecOrMat{T}) where {T <: IntegerUnion}
  _check_dim(nrows(a), ncols(a), arr)
  z = fpMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::fpMatrixSpace)(arr::AbstractVecOrMat{fpFieldElem})
  _check_dim(nrows(a), ncols(a), arr)
  (length(arr) > 0 && (base_ring(a) != parent(arr[1]))) && error("Elements must have same base ring")
  z = fpMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::fpMatrixSpace)(b::ZZMatrix)
  (ncols(a) != b.c || nrows(a) != b.r) && error("Dimensions do not fit")
  z = fpMatrix(modulus(base_ring(a)), b)
  z.base_ring = a.base_ring
  return z
end

###############################################################################
#
#   Matrix constructor
#
###############################################################################

function matrix(R::fpField, arr::AbstractMatrix{<: Union{fpFieldElem, ZZRingElem, Integer}})
  z = fpMatrix(size(arr, 1), size(arr, 2), R.n, arr)
  z.base_ring = R
  return z
end

function matrix(R::fpField, r::Int, c::Int, arr::AbstractVector{<: Union{fpFieldElem, ZZRingElem, Integer}})
  _check_dim(r, c, arr)
  z = fpMatrix(r, c, R.n, arr)
  z.base_ring = R
  return z
end

################################################################################
#
#  Kernel
#
################################################################################

function nullspace(M::fpMatrix)
  N = similar(M, ncols(M), ncols(M))
  nullity = @ccall libflint.nmod_mat_nullspace(N::Ref{fpMatrix}, M::Ref{fpMatrix})::Int
  return nullity, view(N, 1:nrows(N), 1:nullity)
end

################################################################################
#
#  LU decomposition
#
################################################################################

function lu!(P::Perm, x::fpMatrix)
  P.d .-= 1
  rank = @ccall libflint.nmod_mat_lu(P.d::Ptr{Int}, x::Ref{fpMatrix}, Cint(false)::Cint)::Int
  P.d .+= 1

  inv!(P) # FLINT does PLU = x instead of Px = LU

  return rank
end

function lu(x::fpMatrix, P = SymmetricGroup(nrows(x)))
  m = nrows(x)
  n = ncols(x)
  P.n != m && error("Permutation does not match matrix")
  p = one(P)
  R = base_ring(x)
  U = deepcopy(x)

  L = similar(x, m, m)

  rank = lu!(p, U)

  for i = 1:m
    for j = 1:n
      if i > j
        L[i, j] = U[i, j]
        U[i, j] = R()
      elseif i == j
        L[i, j] = one(R)
      elseif j <= m
        L[i, j] = R()
      end
    end
  end
  return rank, p, L, U
end
