defmodule TinyEVM.MachineCode do
  @moduledoc """
  The Machine Code to run in the EVM.
  """

  alias TinyEVM.{Operation, MachineState, ExecutionEnvironment}
  alias TinyEVM.Operation.Metadata

  @type t :: binary()

  @doc """
  Current operation to be executed, defined as `w` in Section
  9.4.1 of the Yellow Paper.

  ## Examples

      iex> TinyEVM.MachineCode.current_operation(%TinyEVM.MachineState{}, %TinyEVM.ExecutionEnvironment{machine_code: <<96>>})
      %TinyEVM.Operation.Metadata{
        args: [1],
        function: :push_n,
        inputs: 0,
        machine_code_offset: 1,
        mnemonic: :push1,
        outputs: 1,
        value: 96
      }

      iex> TinyEVM.MachineCode.current_operation(%TinyEVM.MachineState{}, %TinyEVM.ExecutionEnvironment{machine_code: <<85>>})
      %TinyEVM.Operation.Metadata{
        args: [],
        function: :sstore,
        inputs: 2,
        machine_code_offset: 0,
        mnemonic: :sstore,
        outputs: 0,
        value: 85
      }
  """
  @spec current_operation(MachineState.t(), ExecutionEnvironment.t()) :: Metadata.t()
  def current_operation(machine_state, execution_environment) do
    execution_environment.machine_code
    |> Operation.get_operation_at(machine_state.program_counter)
    |> Operation.metadata()
  end
end
