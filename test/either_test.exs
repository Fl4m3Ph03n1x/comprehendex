defmodule EitherTest do
  use ExUnit.Case

  alias Either
  alias Either.{Left, Right}
  alias Option

  describe "new" do
    test "it returns Left with :uninitialized when called with no params" do
      assert Either.new() == %Left{val: :uninitialized}
    end

    test "it returns Left if called with error tuple" do
      assert Either.new({:error, 1}) == %Left{val: 1}
    end

    test "it returns Right if called with success tuple" do
      assert Either.new({:ok, 1}) == %Right{val: 1}
    end
  end

  describe "left" do
    test "it returns Left with the given val" do
      assert Either.left(1) == %Left{val: 1}
    end
  end

  describe "right" do
    test "it returns Right with the given val" do
      assert Either.right(1) == %Right{val: 1}
    end
  end

  describe "or_else" do
    test "it returns the first Either if its Right" do
      assert Either.or_else(Either.right(1), Either.right(2)) == %Right{val: 1}
    end

    test "it returns the second Either if the first is Left" do
      assert Either.or_else(Either.left(1), Either.right(2)) == %Right{val: 2}
    end
  end

  describe "to_option" do
    test "it converts Right to Option.Some" do
      assert Either.to_option(Either.right(1)) == %Option.Some{val: 1}
    end

    test "it converts Left to Option.None" do
      assert Either.to_option(Either.left(0)) == %Option.None{}
    end
  end

  describe "comprehensions" do
    test "it returns list by default with Left in comprehension" do
      actual =
        for a <- [1, 2, 3], b <- Either.left(0) do
          a * b
        end

      assert actual == [0]
    end

    test "it returns list by default with Right in comprehension" do
      actual =
        for a <- [1, 2, 3], b <- Either.right(2) do
          a * b
        end

      assert actual == [2, 4, 6]
    end

    test "it gives precedence to Left list in comprehension" do
      actual =
        for a <- [1, 2, 3], b <- Either.left(-1), c <- [4] do
          a * b * c
        end

      assert actual == [-1]
    end

    test "it returns Left if comprehension has a Left and is converted into Either" do
      actual =
        for a <- [1, 2, 3], b <- Either.left(1), into: Either.new() do
          a * b
        end

      assert actual == %Left{val: 1}
    end

    test "it returns Right if comprehension has a Right and is converted into Either" do
      actual =
        for a <- [1, 2, 3], b <- Either.right(2), into: Either.new() do
          a * b
        end

      assert actual == %Right{val: 6}
    end

    test "it returns Right if comprehension only works with Right" do
      actual =
        for a <- Either.right(2), b <- Either.right(2), into: Either.new() do
          a * b
        end

      assert actual == %Right{val: 4}
    end

    test "it returns top most Left if comprehension only works with Left" do
      actual =
        for a <- Either.left(1), b <- Either.left(2), into: Either.new() do
          a * b
        end

      assert actual == %Left{val: 1}
    end

    test "Left has prevalence over Right" do
      actual =
        for a <- Either.right(2), b <- Either.right(2), c <- Either.left(0), into: Either.new() do
          a * b * c
        end

      assert actual == %Left{val: 0}
    end

    test "Gives precedence to top most Left in complex comprehensions" do
      actual =
        for a <- Either.right(2),
            b <- Either.right(2),
            c <- Either.left(10),
            d <- Either.right(2),
            e <- Either.left(-1),
            into: Either.new() do
          a * b * c * d * e
        end

      assert actual == %Left{val: 10}
    end
  end

  describe "Enum protocol implementation" do
    test "count returns 1" do
      assert Enum.count(Either.left(1)) == 1
      assert Enum.count(Either.right(1)) == 1
    end

    test "member? returns if content of Either is the same" do
      assert Enum.member?(Either.right(1), 1) == true
      assert Enum.member?(Either.left(1), 1) == true
    end

    test "slice does not throw" do
      assert Enum.at(Either.left(1), 0) == 1
      assert Enum.at(Either.left(1), 10) == nil

      assert Enum.at(Either.right(1), 0) == 1
      assert Enum.at(Either.right(1), 10) == nil
    end
  end
end
