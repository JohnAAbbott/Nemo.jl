@testset "dixon solver" begin
  A = matrix(ZZ, 4, 4, [1, 2, 7, 4, 15, 6, 7, 9, 19, 10, 11, 11, 53, 14, 15, 16])
  b = matrix(ZZ, 4, 1, [-1, -4, 5, 7])
  bb = matrix(ZZ, 4, 2, [-1, -2, -3, 5, 11, 2, 13, 17])
  for i = [1,5,10]
    s, d = Nemo.dixon_solve(A^i, b)
    @test A^i*s == d*b
    s, d = Nemo.dixon_solve(A^i, transpose(b); side = :left)
    @test s*A^i == d*transpose(b)

    s, d = Nemo.dixon_solve(A^i, bb)
    @test A^i*s == d*bb
    s, d = Nemo.dixon_solve(A^i, transpose(bb); side = :left)
    @test s*A^i == d*transpose(bb)
  end
end

@testset "DoublePlusOne" begin
  A = matrix(ZZ, 4, 4, [1, 2, 7, 4, 15, 6, 7, 9, 19, 10, 11, 11, 53, 14, 15, 16])
  b = matrix(ZZ, 1, 4, [-1, -4, 5, 7])
  bb = matrix(ZZ, 2, 4, [-1, -2, -3, 5, 11, 2, 13, 17])
  for i = [1,5,10]
    s, d = Nemo.UniCertSolve(A^i, b)
    @test s*A^i == d*b

    s, d = Nemo.UniCertSolve(A^i, bb)
    @test s*A^i == d*bb
  end
end

@testset "Ex-bugs" begin
  # bugs (!wrong result!) introduced when moving to ZZMatrix-linalg
  # Smallest failing random example I managed to find:
  A = matrix(ZZ, [-80 187 -31 -136 -109 -113 -101 106 112 168;
                  -250 582 -85 -417 -337 -351 -318 325 345 516;
                  444 -1032 148 738 597 622 565 -576 -611 -913;
                  398 -930 147 672 539 560 502 -524 -555 -830;
                  -502 1160 -160 -825 -671 -697 -636 643 683 1022;
                  94 -228 49 172 133 139 118 -134 -141 -211;
                  -766 1778 -255 -1271 -1029 -1070 -972 991 1052 1573;
                  -549 1266 -170 -898 -732 -760 -696 700 744 1113;
                  -251 578 -74 -408 -334 -348 -320 318 338 506;
                  159 -371 60 268 215 223 199 -209 -221 -331]);
  @test is_unimodular(A)

  # Triggers some other bug
  A = matrix(ZZ, [-1599 854 -367 -458 -408 323 2050 -1815 -236 175;
                  -13937 3869 -4069 224 -2074 2897 16569 -16879 -7452 5906;
                  -2097 -173 -700 538 -31 379 2365 -2697 -1911 1460;
                  -33599 7840 -9935 1358 -4461 6836 39741 -40961 -19338 15186;
                  -27748 4229 -8513 2575 -2843 5502 32673 -34396 -18591 14464;
                  -12643 2254 -3878 1165 -1402 2563 14807 -15612 -8238 6467;
                  -23752 5832 -7028 859 -3251 4881 28164 -28939 -13533 10671;
                  4806 -1851 1420 -87 879 -1099 -5622 5749 2287 -1920;
                  -21384 2805 -6662 2496 -2005 4244 25011 -26631 -14973 11667;
                  -2551 -491 -893 839 68 445 2865 -3356 -2666 2029]);
  @test is_unimodular(A^7)
end

