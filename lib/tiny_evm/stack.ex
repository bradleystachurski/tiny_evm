defmodule TinyEVM.Stack do
  @moduledoc """
  Stack stuff
  """

  @type t :: [integer()]

  @spec push(t(), integer() | list(integer())) :: t()
  def push(stack, val) when is_list(val), do: val ++ stack
  def push(stack, val), do: [val | stack]

  @spec pop_n(t(), integer()) :: {[integer()], t()}
  def pop_n(stack, 0), do: {[], stack}

  def pop_n([head | tail], n) do
    {a, b} = pop_n(tail, n - 1)

    {[head | a], b}
  end

  def pop_n([], _n), do: {[], []}
end
