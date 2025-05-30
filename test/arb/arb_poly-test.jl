RR = ArbField(64)
coeff_types = [Int8, Int, UInt, BigInt,
               Float32, Float64, BigFloat,
               Rational{Int8}, Rational{Int}, Rational{BigInt},
               ZZRingElem, QQFieldElem]

@testset "ArbPolyRingElem.constructors" begin
  S1 = PolyRing(RR)
  S2 = PolyRing(RR)

  @test isa(S1, ArbPolyRing)
  @test S1 !== S2

  R, x = polynomial_ring(RR, "x")

  @test elem_type(R) == ArbPolyRingElem
  @test elem_type(ArbPolyRing) == ArbPolyRingElem
  @test parent_type(ArbPolyRingElem) == ArbPolyRing
  @test dense_poly_type(ArbFieldElem) == ArbPolyRingElem

  @test R isa ArbPolyRing

  @test isa(x, PolyRingElem)

  f = x^3 + 2x^2 + x + 1

  @test isa(f, PolyRingElem)

  g = R(2)

  @test isa(g, PolyRingElem)

  h = R(x^2 + 2x + 1)

  @test isa(h, PolyRingElem)

  k = R([RR(1), RR(2), RR(3)])

  @test isa(k, PolyRingElem)

  for T in coeff_types
    l = R(T[1, 2, 3])

    @test isa(l, PolyRingElem)
    @test k == l
  end
end

@testset "ArbPolyRingElem.printing" begin
  R, x = polynomial_ring(RR, "x")
  f = x^3 + 2x^2 + x + 1

  @test sprint(show, "text/plain", f) == "x^3 + 2.0000000000000000000*x^2 + x + 1"
end

@testset "ArbPolyRingElem.manipulation" begin
  R, x = polynomial_ring(RR, "x")

  @test iszero(zero(R))

  @test isone(one(R))

  @test is_gen(gen(R))

  # @test is_unit(one(R))

  f = x^2 + 2x + 1

  @test leading_coefficient(f) == 1

  @test degree(f) == 2

  @test length(f) == 3

  @test coeff(f, 1) == 2

  @test_throws DomainError coeff(f, -1)

  # @test canonical_unit(-x + 1) == -1

  @test deepcopy(f) == f

  @test characteristic(R) == 0
end

@testset "ArbPolyRingElem.polynomial" begin
  R = ArbField(53)

  f = polynomial(R, [])
  g = polynomial(R, [1, 2, 3])
  h = polynomial(R, ZZRingElem[1, 2, 3])
  k = polynomial(R, [R(1), R(2), R(3)])
  p = polynomial(R, [1, 2, 3], "y")

  @test isa(f, ArbPolyRingElem)
  @test isa(g, ArbPolyRingElem)
  @test isa(h, ArbPolyRingElem)
  @test isa(k, ArbPolyRingElem)
  @test isa(p, ArbPolyRingElem)

  q = polynomial(R, [1, 2, 3], cached=false)

  @test parent(g) != parent(q)
end

@testset "ArbPolyRingElem.similar" begin
  R = ArbField(53)

  f = polynomial(R, [1, 2, 3])
  g = similar(f)
  h = similar(f, "y")

  @test isa(g, ArbPolyRingElem)
  @test isa(h, ArbPolyRingElem)

  q = similar(g, cached=false)

  @test parent(g) != parent(q)
end

@testset "ArbPolyRingElem.binary_ops" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 2

  @test f + g == x^3+x^2+5*x+3

  @test f*g == x^5+2*x^4+4*x^3+8*x^2+7*x+2

  @test f - g == -x^3+x^2-x-1
end

@testset "ArbPolyRingElem.adhoc_binary" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 2

  for T in coeff_types
    @test f * T(12) == 12*x^2+24*x+12

    @test T(7) * g == 7*x^3+21*x+14

    @test T(3) * g == 3*x^3+9*x+6

    @test f * T(2) == 2*x^2+4*x+2

    @test T(2) * f == 2*x^2+4*x+2

    @test f + T(12) == x^2+2*x+13

    @test f - T(12) == x^2+2*x-11

    @test T(12) + g == x^3+3*x+14

    @test T(12) - g == -x^3-3*x+10
  end
end

@testset "ArbPolyRingElem.comparison" begin
  R, x = polynomial_ring(RR, "x")
  Zx, zx = polynomial_ring(ZZ, "x")
  Qx, qx = polynomial_ring(QQ, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 2
  h = f + RR("0 +/- 0.0001")
  i = f + RR("0 +/- 0.0001") * x^4

  @test f != g
  @test f == deepcopy(f)

  @test !(f == h)
  @test !(f != h)

  @test !(f == i)
  @test !(f != i)

  @test isequal(f, deepcopy(f))
  @test !isequal(f, h)

  @test contains(f, f)
  @test contains(h, f)
  @test contains(i, f)

  @test !contains(f, h)
  @test !contains(f, g)

  @test contains(h, zx^2 + 2zx + 1)
  @test !contains(h, zx^2 + 2zx + 2)
  @test contains(h, qx^2 + 2qx + 1)
  @test !contains(h, qx^2 + 2qx + 2)

  @test overlaps(f, h)
  @test overlaps(f, i)
  @test !overlaps(f, g)

  uniq, p = unique_integer(h)
  @test uniq
  @test p == zx^2 + 2zx + 1

  uniq, p = unique_integer(f + RR("3 +/- 1.01") * x^4)
  @test !uniq
end

@testset "ArbPolyRingElem.adhoc_comparison" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test f != 1

  @test 1 != f

  @test R(7) == ZZRingElem(7)

  @test ZZRingElem(7) != f

  @test R(7) == RR(7)

  @test RR(7) != f

  @test R(7) == QQ(7)

  @test QQ(7) != f
end

@testset "ArbPolyRingElem.unary_ops" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test -f == -x^2 - 2x - 1
end

@testset "ArbPolyRingElem.truncation" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 1

  @test truncate(f, 2) == 2*x+1

  @test_throws DomainError truncate(f, -1)

  @test mullow(f, g, 3) == 7*x^2+5*x+1

  @test_throws DomainError mullow(f, g, -1)
end

@testset "ArbPolyRingElem.reverse" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 3

  #@test reverse(f) == 3x^2 + 2x + 1
end

@testset "ArbPolyRingElem.shift" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test shift_left(f, 3) == x^5 + 2x^4 + x^3

  @test_throws DomainError shift_left(f, -1)

  @test shift_right(f, 1) == x + 2

  @test_throws DomainError shift_right(f, -1)
end

@testset "ArbPolyRingElem.powering" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test f^12 == x^24+24*x^23+276*x^22+2024*x^21+10626*x^20+42504*x^19+134596*x^18+346104*x^17+735471*x^16+1307504*x^15+1961256*x^14+2496144*x^13+2704156*x^12+2496144*x^11+1961256*x^10+1307504*x^9+735471*x^8+346104*x^7+134596*x^6+42504*x^5+10626*x^4+2024*x^3+276*x^2+24*x+1

  @test_throws DomainError f^-1
end

@testset "ArbPolyRingElem.exact_division" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 1

  @test divexact(f*g, f) == g
end

@testset "arb_poly_scalar_division" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test divexact(2*f, ZZ(2)) == f

  @test divexact(2*f, 2) == f

  @test divexact(2*f, QQ(2)) == f

  @test divexact(2*f, RR(2)) == f

  @test divexact(2*f, 2.0) == f
end

@testset "ArbPolyRingElem.evaluation" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test evaluate(f, 3) == 16

  @test evaluate(f, 10.0) == 121

  @test evaluate(f, ZZ(10)) == 121

  @test evaluate(f, QQ(10)) == 121

  @test evaluate(f, RR(10)) == 121

  @test evaluate2(f, 10) == (121, 22)

  @test evaluate2(f, 10.0) == (121, 22)

  @test evaluate2(f, ZZ(10)) == (121, 22)

  @test evaluate2(f, QQ(10)) == (121, 22)

  @test evaluate2(f, RR(10)) == (121, 22)
end

@testset "ArbPolyRingElem.composition" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1
  g = x^3 + 3x + 1

  @test compose(f, g; inner = :second) == x^6+6*x^4+4*x^3+9*x^2+12*x+4
end

@testset "ArbPolyRingElem.derivative_integral" begin
  R, x = polynomial_ring(RR, "x")

  f = x^2 + 2x + 1

  @test derivative(f) == 2x + 2

  @test contains(derivative(integral(f)), f)
end

@testset "ArbPolyRingElem.evaluation_interpolation" begin
  R, x = polynomial_ring(RR, "x")

  n = 5
  xs = ArbFieldElem[inv(RR(i)) for i=1:n]
  ys = ArbFieldElem[RR(i) for i=1:n]

  f = interpolate(R, xs, ys)
  vs = evaluate(f, xs)
  for i=1:n
    @test contains(vs[i], ys[i])
  end

  f = interpolate(R, xs, ys)
  vs = evaluate(f, xs)
  for i=1:n
    @test contains(vs[i], ys[i])
  end

  f = interpolate_fast(R, xs, ys)
  vs = evaluate_fast(f, xs)
  for i=1:n
    @test contains(vs[i], ys[i])
  end

  f = interpolate_newton(R, xs, ys)
  vs = evaluate(f, xs)
  for i=1:n
    @test contains(vs[i], ys[i])
  end

  f = interpolate_barycentric(R, xs, ys)
  vs = evaluate(f, xs)
  for i=1:n
    @test contains(vs[i], ys[i])
  end

  f = from_roots(R, xs)
  @test degree(f) == n
  for i=1:n
    @test contains_zero(evaluate(f, xs[i]))
  end
end

@testset "ArbPolyRingElem.root_bound" begin
  Rx, x = polynomial_ring(RR, "x")

  for i in 1:2
    r = rand(1:10)
    z = map(RR, rand(-BigInt(2)^60:BigInt(2)^60, r))
    f = prod([ x - z[i] for i in 1:r])
    b = roots_upper_bound(f)
    @test all([ abs(z[i]) <= b for i in 1:r])
  end
end
