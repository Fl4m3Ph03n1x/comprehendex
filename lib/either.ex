defmodule Either do
  @moduledoc """
  Either monad. An `Either` can be a `Left` or a `Right`.
  This is akin to the 'Error Monad' or 'Result Monad' from other languages.

  Left is usually used to hold an error or failure, where Right is usually used to hold the correct
  state of a computation.

  Has interopability with Enum, as it is implemented as a list underneath.

  It is important to note that while it can interact with other Enumerables, such as lists, if you
  don't convert the final result into an `Either` type, you will loose the granularity of the
  operation, meaning, you will only get a list and wont know if the result is a `Left` or a `Right`.
  """
  alias Option

  @type t(error, success) :: __MODULE__.Left.t(error) | __MODULE__.Right.t(success)

  defmodule Right do
    @moduledoc """
    Represents the `Right` side of an `Either`. Normally used to hold the correct result of a
    computation.
    """
    @type t(elem) :: %__MODULE__{val: elem}

    defstruct [:val]

    defimpl Collectable do
      @impl Collectable
      def into(option),
        do:
          {option,
           fn
             _acc, :halt ->
               :ok

             acc, _command ->
               {:done, acc}
           end}
    end

    defimpl Enumerable do
      @impl Enumerable
      def count(_right), do: {:ok, 1}

      @impl Enumerable
      def member?(right, element), do: {:ok, right.val == element}

      @impl Enumerable
      def reduce(some, acc, fun)

      def reduce(_right, {:halt, acc}, _fun), do: {:halted, acc}
      def reduce(right, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(right, &1, fun)}

      def reduce([], {:cont, %Either.Right{} = acc}, _fun), do: {:done, acc}

      def reduce([], {:cont, acc}, _fun) do
        cond do
          is_map(acc) and Map.has_key?(acc, :val) and acc.__struct__ == Either.Left ->
            {:done, Either.left(acc.val)}

          is_map(acc) and Map.has_key?(acc, :val) ->
            {:done, %Either.Right{val: acc.val}}

          true ->
            {:done, acc}
        end
      end

      def reduce(%Either.Right{} = right, {:cont, acc}, fun) do
        reduce([], fun.(right.val, acc), fun)
      end

      @impl Enumerable
      def slice(%Either.Right{val: val}),
        do: {:ok, 1, &Enumerable.List.slice([val], &1, &2, 1)}
    end
  end

  defmodule Left do
    @moduledoc """
    Represents the `Left` side of an `Either`. Normally used to hold a failure or error result of a
    computation. Takes precedence over any `Right`.
    """
    @type t(elem) :: %__MODULE__{val: elem}

    defstruct [:val]

    defimpl Collectable do
      @impl Collectable
      def into(either) do
        {either,
         fn
           %Either.Left{val: :uninitialized}, {:cont, val} ->
             Either.right(val)

           %Either.Right{}, {:cont, val} ->
             Either.right(val)

           [ok: %Either.Right{}], {:cont, val} ->
             Either.right(val)

           _acc, {:cont, val} ->
             Either.left(val)

           acc, :done ->
             acc
         end}
      end
    end

    defimpl Enumerable do
      @impl Enumerable
      def count(_some), do: {:ok, 1}

      @impl Enumerable
      def member?(some, element), do: {:ok, some.val == element}

      @impl Enumerable
      def reduce(left, acc, fun)

      def reduce(_left, {:halt, acc}, _fun), do: {:halted, acc}
      def reduce(left, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(left, &1, fun)}

      def reduce(%Either.Left{} = left, {:cont, %Either.Left{val: val} = acc}, _fun) do
        case val do
          :uninitialized -> {:done, left}
          _ -> {:done, acc}
        end
      end

      def reduce(%Either.Left{val: val}, {:cont, _acc}, _fun), do: {:done, [val]}

      @impl Enumerable
      def slice(%Either.Left{val: val}),
        do: {:ok, 1, &Enumerable.List.slice([val], &1, &2, 1)}
    end
  end

  @spec new({:ok, any}) :: __MODULE__.Right.t(any)
  def new({:ok, val}), do: %__MODULE__.Right{val: val}

  @spec new({:error, any}) :: __MODULE__.Left.t(any)
  def new({:error, val}), do: %__MODULE__.Left{val: val}

  @spec new :: __MODULE__.Left.t(:uninitialized)
  def new, do: %__MODULE__.Left{val: :uninitialized}

  @spec left(any) :: __MODULE__.Left.t(any)
  def left(val), do: Either.new({:error, val})

  @spec right(any) :: __MODULE__.Right.t(any)
  def right(val), do: Either.new({:ok, val})

  @spec or_else(__MODULE__.t(any, any), __MODULE__.t(any, any)) :: __MODULE__.t(any, any)
  def or_else(either_1, either_2) do
    case either_1 do
      %__MODULE__.Right{} -> either_1
      _ -> either_2
    end
  end

  @spec to_option(__MODULE__.t(any, any)) :: Option.t(any)
  def to_option(%Either.Right{val: val}), do: Option.some(val)
  def to_option(%Either.Left{}), do: Option.none()
end
