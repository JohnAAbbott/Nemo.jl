@testset "FqPolyRepPolyRingElem.constructors" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")

  S1 = PolyRing(R)
  S2 = PolyRing(R)

  @test isa(S1, FqPolyRepPolyRing)
  @test S1 !== S2

  S, y = polynomial_ring(R, "y")

  @test elem_type(S) == FqPolyRepPolyRingElem
  @test elem_type(FqPolyRepPolyRing) == FqPolyRepPolyRingElem
  @test parent_type(FqPolyRepPolyRingElem) == FqPolyRepPolyRing
  @test dense_poly_type(FqPolyRepFieldElem) == FqPolyRepPolyRingElem

  @test S isa FqPolyRepPolyRing

  @test isa(y, PolyRingElem)

  T, z = polynomial_ring(S, "z")

  @test T isa Generic.PolyRing

  @test isa(z, PolyRingElem)

  f = x^2 + y^3 + z + 1

  @test isa(f, PolyRingElem)

  g = S(2)

  @test isa(g, PolyRingElem)

  h = S(x^2 + 2x + 1)

  @test isa(h, PolyRingElem)

  j = T(x + 2)

  @test isa(j, PolyRingElem)

  k = S([x, x + 2, x^2 + 3x + 1])

  @test isa(k, PolyRingElem)

  l = S(k)

  @test isa(l, PolyRingElem)

  m = S([1, 2, 3])

  @test isa(m, PolyRingElem)

  n = S(ZZRingElem(12))

  @test isa(n, PolyRingElem)

  T, z = polynomial_ring(ZZ, "z")

  p = S(3z^2 + 2z + 5)

  @test isa(p, PolyRingElem)

  r = S([ZZ(1), ZZ(2), ZZ(3)])

  @test isa(r, PolyRingElem)
end

@testset "FqPolyRepPolyRingElem.printing" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")
  T, z = polynomial_ring(S, "z")

  f = x^2 + y^3 + z + 1

  @test sprint(show, "text/plain", f) == "z + y^3 + x^2 + 1"
end

@testset "FqPolyRepPolyRingElem.manipulation" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  @test iszero(zero(S))

  @test isone(one(S))

  @test is_gen(gen(S))

  @test is_unit(one(S))

  f = 2x*y + x^2 + 1

  @test leading_coefficient(f) == 2x

  @test degree(f) == 1

  h = x*y^2 + (x + 1)*y + 3

  @test coeff(h, 2) == x

  @test_throws DomainError coeff(h, -1)

  @test length(h) == 3

  @test canonical_unit(-x*y + x + 1) == 22x

  @test deepcopy(h) == h
end

@testset "FqPolyRepPolyRingElem.polynomial" begin
  R, _ = Native.finite_field(ZZ(23), 3, "a")

  f = polynomial(R, [])
  g = polynomial(R, [1, 2, 3])
  h = polynomial(R, ZZRingElem[1, 2, 3])
  k = polynomial(R, [R(1), R(2), R(3)])
  p = polynomial(R, [1, 2, 3], "y")

  @test isa(f, FqPolyRepPolyRingElem)
  @test isa(g, FqPolyRepPolyRingElem)
  @test isa(h, FqPolyRepPolyRingElem)
  @test isa(k, FqPolyRepPolyRingElem)
  @test isa(p, FqPolyRepPolyRingElem)

  q = polynomial(R, [1, 2, 3], cached=false)

  @test parent(g) !== parent(q)
end

@testset "FqPolyRepPolyRingElem.similar" begin
  R, a = Native.finite_field(ZZ(23), 3, "a")

  f = polynomial(R, [1, 2, 3])
  g = similar(f)
  h = similar(f, "y")

  @test isa(g, FqPolyRepPolyRingElem)
  @test isa(h, FqPolyRepPolyRingElem)

  q = similar(g, cached=false)

  @test parent(g) === parent(q)
end

@testset "FqPolyRepPolyRingElem.binary_ops" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = (x + 1)*y + (x^3 + 2x + 2)

  @test f - g == x*y^2+(-x^3-2*x+1)

  @test f + g == x*y^2+(2*x+2)*y+(x^3+2*x+5)

  @test f*g == (x^2+x)*y^3+(x^4+3*x^2+4*x+1)*y^2+(x^4+x^3+2*x^2+7*x+5)*y+(3*x^3+6*x+6)
end

@testset "FqPolyRepPolyRingElem.adhoc_binary" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = (x + 1)*y + (x^3 + 2x + 2)

  @test f*4 == (4*x)*y^2+(4*x+4)*y+12

  @test 7*f == (7*x)*y^2+(7*x+7)*y+21

  @test ZZRingElem(5)*g == (5*x+5)*y+(5*x^3+10*x+10)

  @test g*ZZRingElem(3) == (3*x+3)*y+(3*x^3+6*x+6)

  @test (x + 1)*g == g*(x + 1)

  @test 234567654345676543456787655678765*g == g*234567654345676543456787655678765

  @test (x + 1) + g == g + (x + 1)

  @test 234567654345676543456787655678765 + g == g + 234567654345676543456787655678765

  @test 3 + g == g + 3

  @test ZZRingElem(7) + g == g + ZZRingElem(7)

  @test (x + 1) - g == -(g - (x + 1))

  @test 234567654345676543456787655678765 - g == -(g - 234567654345676543456787655678765)

  @test 3 - g == -(g - 3)

  @test ZZRingElem(7) - g == -(g - ZZRingElem(7))
end

@testset "FqPolyRepPolyRingElem.comparison" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = x*y^2 + (x + 1)*y + 3

  @test f == g

  @test isequal(f, g)
end

@testset "FqPolyRepPolyRingElem.adhoc_comparison" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  @test S(1) == 1

  @test 1 != x + y

  @test S(x) == x

  @test x + 1 == S(x + 1)

  @test ZZRingElem(3) != x + y

  @test S(7) == ZZRingElem(7)
end

@testset "FqPolyRepPolyRingElem.unary_ops" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test -f == -x*y^2 - (x + 1)*y - 3
end

@testset "FqPolyRepPolyRingElem.truncation" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = (x + 1)*y + (x^3 + 2x + 2)

  @test truncate(f, 1) == 3

  @test_throws DomainError truncate(f, -1)

  @test mullow(f, g, 4) == (x^2+x)*y^3+(x^4+3*x^2+4*x+1)*y^2+(x^4+x^3+2*x^2+7*x+5)*y+(3*x^3+6*x+6)

  @test_throws DomainError mullow(f, g, -1)
end

@testset "FqPolyRepPolyRingElem.reverse" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test reverse(f, 7) == 3y^6 + (x + 1)*y^5 + x*y^4

  @test_throws DomainError reverse(f, -1)
end

@testset "FqPolyRepPolyRingElem.shift" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test shift_left(f, 7) == x*y^9 + (x + 1)*y^8 + 3y^7

  @test_throws DomainError shift_left(f, -1)

  @test shift_right(f, 3) == 0

  @test_throws DomainError shift_right(f, -1)
end

@testset "FqPolyRepPolyRingElem.powering" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test f^5 == (x^5)*y^10+(5*x^5+5*x^4)*y^9+(10*x^5+35*x^4+10*x^3)*y^8+(10*x^5+90*x^4+90*x^3+10*x^2)*y^7+(5*x^5+110*x^4+300*x^3+110*x^2+5*x)*y^6+(x^5+65*x^4+460*x^3+460*x^2+65*x+1)*y^5+(15*x^4+330*x^3+900*x^2+330*x+15)*y^4+(90*x^3+810*x^2+810*x+90)*y^3+(270*x^2+945*x+270)*y^2+(405*x+405)*y+243

  @test_throws DomainError f^-1
end

@testset "FqPolyRepPolyRingElem.modular_arithmetic" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = (3*x^2 + x + 2)*y + x^2 + 1
  g = (5*x^2 + 2*x + 1)*y^2 + 2x*y + x + 1
  h = (3*x^3 + 2*x^2 + x + 7)*y^5 + 2x*y + 1

  @test invmod(f, g) == (19*x^4+16*x^3+14*x^2+9*x+13)*y+(13*x^4+19*x^3+4*x^2+19*x+18)

  @test mulmod(f, g, h) == (15*x^4+11*x^3+15*x^2+5*x+2)*y^3+(5*x^4+8*x^3+8*x^2+6*x+1)*y^2+(5*x^3+4*x^2+5*x+2)*y+(x^3+x^2+x+1)

  @test powermod(f, 3, h) == (17*x^4+14*x^3+7*x^2+20*x+5)*y^3+(20*x^4+7*x^3+16*x^2+x+10)*y^2+(x^4+6*x^3+17*x^2+16*x+21)*y+(3*x^4+5*x+1)

  @test powermod(f, -3, g) == (18*x^4+x^3+7*x^2+15*x+5)*y+(16*x^4+14*x^3+15*x^2+5*x+21)

  @test powermod(f, ZZRingElem(3), h) == (17*x^4+14*x^3+7*x^2+20*x+5)*y^3+(20*x^4+7*x^3+16*x^2+x+10)*y^2+(x^4+6*x^3+17*x^2+16*x+21)*y+(3*x^4+5*x+1)

  @test powermod(f, -ZZRingElem(3), g) == (18*x^4+x^3+7*x^2+15*x+5)*y+(16*x^4+14*x^3+15*x^2+5*x+21)
end

@testset "FqPolyRepPolyRingElem.exact_division" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = (x + 1)*y + (x^3 + 2x + 2)

  @test divexact(f*g, f) == g
end

@testset "FqPolyRepPolyRingElem.adhoc_exact_division" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test divexact(3*f, 3) == f

  @test divexact(x*f, x) == f
end

@testset "FqPolyRepPolyRingElem.euclidean_division" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  k = y^3 + x*y^2 + (x + 1)*y + 3
  l = (x + 1)*y^2 + (x^3 + 2x + 2)

  @test mod(k, l) == (18*x^4+5*x^3+17*x^2+7*x+1)*y+(5*x^4+17*x^3+6*x^2+15*x+1)

  @test divrem(k, l) == ((18*x^4+5*x^3+18*x^2+5*x+3)*y+(5*x^4+18*x^3+5*x^2+18*x+21), (18*x^4+5*x^3+17*x^2+7*x+1)*y+(5*x^4+17*x^3+6*x^2+15*x+1))
end

@testset "FqPolyRepPolyRingElem.content_primpart_gcd" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  k = x*y^2 + (x + 1)*y + 3
  l = (x + 1)*y + (x^3 + 2x + 2)
  m = y^2 + x + 1

  @test content(k) == 1

  @test primpart(k*(x^2 + 1)) == (x^3+x)*y^2+(x^3+x^2+x+1)*y+(3*x^2+3)

  @test gcd(k*m, l*m) == m

  @test lcm(k*m, l*m) == k*l*m

  r = y^3 + 2y + 1
  s = y^5 + 1

  @test gcdinv(r, s) == (1, 3*y^4+8*y^3+18*y^2+4*y+2)
end

@testset "FqPolyRepPolyRingElem.square_root" begin
  for p in [2, 23]
    R, x = Native.finite_field(ZZRingElem(p), 3, "x")
    S, y = polynomial_ring(R, "y")

    for iter in 1:1000
      f = rand(S, -1:10)
      while is_square(f)
        f = rand(S, -1:10)
      end

      g0 = rand(S, -1:10)
      g = g0^2

      @test is_square(g)
      @test sqrt(g)^2 == g

      if !iszero(g)
        @test !is_square(f*g)
        @test_throws ErrorException sqrt(f*g)
      end

      f1, s1 = is_square_with_sqrt(g)

      @test f1 && s1^2 == g

      if !iszero(g)
        f2, s2 = is_square_with_sqrt(f*g)

        @test !f2
      end
    end
  end
end

@testset "FqPolyRepPolyRingElem.evaluation" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x^2 + 2x + 1
  g = x*y^2 + (x + 1)*y + 3

  @test evaluate(g, 3) == 12x + 6

  @test evaluate(g, ZZRingElem(3)) == 12x + 6

  @test evaluate(g, f) == x^5+4*x^4+7*x^3+7*x^2+4*x+4

  @test g(3) == 12x + 6

  @test g(ZZRingElem(3)) == 12x + 6

  @test g(f) == x^5+4*x^4+7*x^3+7*x^2+4*x+4

end

@testset "FqPolyRepPolyRingElem.composition" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3
  g = (x + 1)*y + (x^3 + 2x + 2)

  @test compose(f, g; inner = :second) == (x^3+2*x^2+x)*y^2+(2*x^5+2*x^4+4*x^3+9*x^2+6*x+1)*y+(x^7+4*x^5+5*x^4+5*x^3+10*x^2+8*x+5)
end

@testset "FqPolyRepPolyRingElem.derivative" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  h = x*y^2 + (x + 1)*y + 3

  @test derivative(h) == 2x*y + x + 1
end

@testset "FqPolyRepPolyRingElem.integral" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = (x^2 + 2x + 1)*y^2 + (x + 1)*y - 2x + 4

  @test integral(f) == (8*x^2+16*x+8)*y^3+(12*x+12)*y^2+(21*x+4)*y
end

@testset "FqPolyRepPolyRingElem.resultant" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = 3x*y^2 + (x + 1)*y + 3
  g = 6(x + 1)*y + (x^3 + 2x + 2)

  @test resultant(f, g) == 3*x^7+6*x^5-6*x^3+96*x^2+192*x+96
end

@testset "FqPolyRepPolyRingElem.discriminant" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = x*y^2 + (x + 1)*y + 3

  @test discriminant(f) == x^2-10*x+1
end

@testset "FqPolyRepPolyRingElem.gcdx" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = 3x*y^2 + (x + 1)*y + 3
  g = 6(x + 1)*y + (x^3 + 2x + 2)

  @test gcdx(f, g) == (1, 18*x^4+8*x^3+6*x^2+17*x+13, (7*x^4+12*x^3+8*x^2+18*x+12)*y+(12*x^4+5*x^3+22*x^2+4*x+4))
end

@testset "FqPolyRepPolyRingElem.special" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  @test chebyshev_t(20, y) == 524288*y^20-2621440*y^18+5570560*y^16-6553600*y^14+4659200*y^12-2050048*y^10+549120*y^8-84480*y^6+6600*y^4-200*y^2+1

  @test chebyshev_u(15, y) == 32768*y^15-114688*y^13+159744*y^11-112640*y^9+42240*y^7-8064*y^5+672*y^3-16*y
end

@testset "FqPolyRepPolyRingElem.inflation_deflation" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = (x + 1)*y^2 + 2x*y + x + 3

  @test deflate(inflate(f, 3), 3) == f
end

@testset "FqPolyRepPolyRingElem.is_irreducible" begin
  R, a = Native.finite_field(ZZRingElem(23), 1, "a")
  Rx, x = polynomial_ring(R, "x")

  f = x^6 + x^4 + 2 *x^2

  @test !is_irreducible(f)

  @test is_irreducible(x)

  @test is_irreducible(x^16+2*x^9+x^8+x^2+x+1)

  @test !is_irreducible(x^0)
  @test !is_irreducible(0*x^0)
end

@testset "FqPolyRepPolyRingElem.is_squarefree" begin
  R, a = Native.finite_field(ZZRingElem(23), 1, "a")
  Rx, x = polynomial_ring(R, "x")

  f = x^6 + x^4 + 2 *x^2

  @test !is_squarefree(f)

  @test is_squarefree((x+1)*(x+2)*(x+3))
end

@testset "FqPolyRepPolyRingElem.factor" begin
  R, x = Native.finite_field(ZZRingElem(23), 5, "x")
  S, y = polynomial_ring(R, "y")

  f = 7y^2 + 3y + 2
  g = 11y^3 - 2y^2 + 5

  A = factor(f*g)

  @test occursin("y", sprint(show, "text/plain", A))

  @test unit(A)*prod([h^e for (h,e) = A]) == f*g

  A = factor_squarefree(f^2*g)

  @test unit(A)*prod([h^e for (h,e)=A]) == f^2*g

  @test unit(A)*prod([h^e for (h,e)=A]) == f^2*g
  @test divexact(g, leading_coefficient(g)) in A
  @test A[divexact(g, leading_coefficient(g))] == 1
  @test divexact(f, leading_coefficient(f)) in A
  @test A[divexact(f, leading_coefficient(f))] == 2

  C = factor_shape(f^2 * g)
  @test C == Dict(2 => 3, 1 => 1)

  B = factor_distinct_deg((y + 1)*g*(y^5+y^3+y+1))

  @test length(B) == 3
  @test 11*prod([h for (e,h) = B]) == ((y + 1)*g*(y^5+y^3+y+1))

  @test issetequal(roots(5 * y * (y^2 + 1)*(y^2 + 2)*(y+1) * (y - x)^10), R.([0, -1, x]))
end

@testset "FqPolyRepPolyRingElem.remove_valuation" begin
  R, x = Native.finite_field(23, 5, "x")
  S, y = polynomial_ring(R, "y")

  f = 7y^2 + 3y + 2
  g = f^5*(11y^3 - 2y^2 + 5)

  @test_throws Exception remove(f, zero(S))
  @test_throws Exception remove(f, one(S))
  @test_throws Exception remove(zero(S), f)

  v, h = remove(g, f)

  @test valuation(g, f) == 5
  @test v == 5
  @test h == (11y^3 - 2y^2 + 5)

  v, q = divides(f*g, f)

  @test v
  @test q == g

  v, q = divides(f*g + 1, f)

  @test !v
end
