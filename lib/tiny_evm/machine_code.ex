defmodule TinyEVM.MachineCode do
  @moduledoc"""
  The Machine Code to run in the EVM.
  """

  alias TinyEVM.{Operation, MachineState, ExecutionEnvironment}
  alias TinyEVM.Operation.Metadata

  @type t :: binary()
  
  @doc"""
  `w` from the Yellow Paper
  """
  @spec current_operation(MachineState.t(), ExecutionEnvironment.t()) :: Metadata.t()
  def current_operation(machine_state, execution_environment) do
    execution_environment.machine_code
    |> Operation.get_operation_at(machine_state.program_counter)
    |> Operation.metadata()
  end
end