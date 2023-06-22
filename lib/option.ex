defmodule Option do
  @moduledoc """
  Option monad. An `Option` can be a `Some` or `None`.
  This is akin to the 'Maybe Monad' from other languages.

  `None` represents the abseence of a result, while `Some` represents the existance of a result.

  Has interopability with Enum, as it is implemented as a list underneath.

  It is important to note that while it can interact with other Enumerables, such as lists, if you
  don't convert the final result into an `Option` type, you will get `[]` for `None` and `[x]` for
  `Some` where `x` is the result of the computation.
  """
  alias Either

  @type t(elem) :: __MODULE__.Some.t(elem) | __MODULE__.None.t()

  defmodule Some do
    @moduledoc """
    Represents the `Some` side of an `Option`. Used to represent the presence of a value.
    """
    @type t(elem) :: %__MODULE__{val: elem}

    defstruct [:val]

    defimpl Collectable do
      @impl Collectable
      def into(option), do: {option, fn acc, _command -> {:done, acc} end}
    end

    defimpl Enumerable do
      @impl Enumerable
      def count(_some), do: {:ok, 1}

      @impl Enumerable
      def member?(some, element), do: {:ok, some.val == element}

      @impl Enumerable
      def reduce(some, acc, fun)

      def reduce(_some, {:halt, acc}, _fun), do: {:halted, acc}
      def reduce(some, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(some, &1, fun)}
      def reduce([], {:cont, acc}, _fun), do: {:done, acc}

      def reduce(%Option.Some{} = some, {:cont, acc}, fun),
        do: reduce([], fun.(some.val, acc), fun)

      @impl Enumerable
      def slice(%Option.Some{val: val}),
        do: {:ok, 1, &Enumerable.List.slice([val], &1, &2, 1)}
    end
  end

  defmodule None do
    @moduledoc """
    Represents the `None` side of an `Option`. Used to represent the absence of a value.
    """
    @type t :: %__MODULE__{}

    defstruct []

    defimpl Collectable do
      @impl Collectable
      def into(option) do
        {option,
         fn
           _acc, {:cont, val} ->
             %Option.Some{val: val}

           acc, :done ->
             acc

           _acc, :halt ->
             :ok
         end}
      end
    end

    defimpl Enumerable do
      @impl Enumerable
      def count(_none), do: {:ok, 0}
      @impl Enumerable
      def member?(_none, _element), do: {:ok, false}

      @impl Enumerable
      def reduce(none, acc, fun)

      def reduce(_none, {:cont, acc}, _fun), do: {:done, acc}
      def reduce(_none, {:halt, acc}, _fun), do: {:halted, acc}
      def reduce(none, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(none, &1, fun)}

      @impl Enumerable
      def slice(%Option.None{}),
        do: {:ok, 0, &Enumerable.List.slice([], &1, &2, 0)}
    end
  end

  @spec new(any) :: __MODULE__.Some.t(any)
  def new(val), do: %__MODULE__.Some{val: val}

  @spec new :: __MODULE__.None.t()
  def new, do: %__MODULE__.None{}

  @spec none :: __MODULE__.None.t()
  def none, do: Option.new()

  @spec some(any) :: __MODULE__.Some.t(any)
  def some(val), do: Option.new(val)

  @spec or_else(Option.t(any), Option.t(any)) :: Option.t(any)
  def or_else(option_1, option_2) do
    case option_1 do
      %__MODULE__.Some{} -> option_1
      _ -> option_2
    end
  end

  @spec to_right(Option.t(any), any) :: Either.t(any, any)
  def to_right(option, error) do
    case option do
      %__MODULE__.Some{val: val} -> Either.right(val)
      _ -> Either.left(error)
    end
  end
end
