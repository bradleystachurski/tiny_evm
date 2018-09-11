defmodule Utils do
  @moduledoc """
  Utility functions for the project.
  """

  alias TinyEVM.{MachineState, Operation.Metadata}

  use Bitwise

  @max_stack_size 1024

  @doc """
  Checks if the operation instruction is invalid, defined in Section
  9.4.2 of the Yellow Paper.

    δ_w == ∅.
  """
  @spec invalid_instruction?(Metadata.t()) :: boolean()
  def invalid_instruction?(%Metadata{inputs: nil}), do: true

  def invalid_instruction?(_), do: false

  @doc """
  Checks if there are insufficient stack items, defined in Section 9.4.2
  of the Yellow Paper.

    ||μ_s|| < δ_w
  """
  @spec insufficient_stack_items?(Metadata.t(), MachineState.t()) :: boolean()
  def insufficient_stack_items?(operation, machine_state) do
    operation.inputs > length(machine_state.stack)
  end

  @doc """
  Checks if the new stack size will exceed the max allowed stack size, defined
  in section 9.4.2 of the Yellow Paper.

    ||μ_s|| − δ_w + α_w > 1024
  """
  @spec will_exceed_stack_size?(Metadata.t(), MachineState.t()) :: boolean()
  def will_exceed_stack_size?(operation, machine_state) do
    length(machine_state.stack) - operation.inputs + operation.outputs > @max_stack_size
  end
end
