defmodule OptionTest do
  use ExUnit.Case

  alias Option
  alias Option.{Some, None}
  alias Either.{Left, Right}

  describe "new" do
    test "it returns Some when given a value" do
      assert Option.new(1) == %Some{val: 1}
    end

    test "it returns None when given no value" do
      assert Option.new() == %None{}
    end
  end

  describe "or_else" do
    test "it returns the first Option if its Some" do
      assert Option.or_else(Option.new(1), Option.new(2)) == %Some{val: 1}
    end

    test "it returns the second Option if the first is None" do
      assert Option.or_else(Option.new(), Option.new(2)) == %Some{val: 2}
    end
  end

  describe "to_right" do
    test "it returns Either.Right if it is Some" do
      assert Option.to_right(Option.new(1), "error") == %Right{val: 1}
    end

    test "it returns Either.Left with the given val if it is None" do
      assert Option.to_right(Option.new(), "error") == %Left{val: "error"}
    end
  end

  describe "some" do
    test "it returns Some with given val" do
      assert Option.some(1) == %Some{val: 1}
    end
  end

  describe "none" do
    test "it returns None" do
      assert Option.none() == %None{}
    end
  end

  describe "comprehensions" do
    test "it functions as a single list element if it is Some" do
      actual =
        for a <- [1, 2, 3],
            b <- Option.new(2) do
          a * b
        end

      assert actual == [2, 4, 6]
    end

    test "it functions as an empty list if it is None" do
      actual =
        for a <- [1, 2, 3],
            b <- Option.new() do
          a * b
        end

      assert actual == []
    end

    test "it returns None if comprehension is converted into an Option and interacts with None" do
      actual =
        for a <- [1, 2, 3], b <- Option.new(), into: Option.new() do
          a * b
        end

      assert actual == %None{}
    end

    test "it returns Some of the last operation on the list if comprehension is converted into an Option and interacts with Some" do
      actual =
        for a <- [1, 2, 3], b <- Option.new(2), into: Option.new() do
          a * b
        end

      assert actual == %Some{val: 6}
    end

    test "None has prevalence over Some" do
      actual =
        for a <- [1, 2, 3], b <- Option.some(2), c <- Option.none(), into: Option.new() do
          a * b * c
        end

      assert actual == %None{}
    end
  end
end
