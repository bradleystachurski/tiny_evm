defmodule TinyEVM.Gas do
  @moduledoc """
  Gas stuff
  """

  alias TinyEVM.{MachineState, ExecutionEnvironment, MachineCode}

  @fee_schedule %{
    g_zero: %{
      value: 0,
      operations: [:stop, :return, :revert]
    },
    g_base: %{
      value: 2,
      operations: []
    },
    g_very_low: %{
      value: 3,
      operations: [:push_n, :xor, :swap_n]
    },
    g_mid: %{
      value: 8,
      operations: [:mulmod]
    }
  }

  @doc"""
  Calculates the cost to run the current operation.

  ## Examples

  """
  @spec cost(MachineState.t(), ExecutionEnvironment.t()) :: integer() | nil
  def cost(machine_state, execution_environment) do
    operation = MachineCode.current_operation(machine_state, execution_environment)

    if operation.function == :sstore,
       do: sstore_cost(),
       else: static_operation_cost(operation.function)
  end

  @spec sstore_cost() :: non_neg_integer()
  # no resets are tested, so cost will always be 20,000 gas
  def sstore_cost, do: 20000

  @spec static_operation_cost(atom()) :: non_neg_integer | nil
  def static_operation_cost(operation) do
    gas_group = Enum.find(Map.keys(@fee_schedule), fn x ->
      Enum.member?(@fee_schedule[x][:operations], operation)
    end)
    @fee_schedule[gas_group][:value]
  end

  @spec insufficient_gas?(MachineState.t(), ExecutionEnvironment.t()) :: boolean()
  def insufficient_gas?(machine_state, execution_environment) do
    cost = cost(machine_state, execution_environment)
    cost > machine_state.gas
  end

  def subtract_gas(machine_state, execution_environment) do
    cost = cost(machine_state, execution_environment)

    %{machine_state | gas: machine_state[:gas] - cost}
  end
end
