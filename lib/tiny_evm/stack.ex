defmodule TinyEVM.Stack do
  @moduledoc """
  Stack stuff
  """

  @type t :: [integer()]

  @doc """
  Pushes an item on the stack and returns the updated
  stack.

  ## Examples
      iex> TinyEVM.Stack.push([1, 2, 3], 4)
      [4, 1, 2, 3]

      iex> TinyEVM.Stack.push([3, 4, 5], [1, 2])
      [1, 2, 3, 4, 5]
  """
  @spec push(t(), integer() | list(integer())) :: t()
  def push(stack, val) when is_list(val), do: val ++ stack
  def push(stack, val), do: [val | stack]

  @doc """
  Removes n items from the stack and returns the tuple
  of the items removed and updated stack.

  ## Examples
      iex> TinyEVM.Stack.pop_n([1, 2, 3], 1)
      {[1], [2, 3]}

      iex> TinyEVM.Stack.pop_n([1, 2, 3, 4, 5], 2)
      {[1, 2], [3, 4, 5]}
  """
  @spec pop_n(t(), integer()) :: {[integer()], t()}
  def pop_n(stack, 0), do: {[], stack}

  def pop_n([head | tail], n) do
    {a, b} = pop_n(tail, n - 1)

    {[head | a], b}
  end

  def pop_n([], _n), do: {[], []}
end
