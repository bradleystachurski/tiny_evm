defmodule TinyEVM.Gas do
  @moduledoc """
  Gas stuff
  """

  alias TinyEVM.{MachineState, ExecutionEnvironment, MachineCode, Operation}

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

  @spec cost(MachineState.t(), ExecutionEnvironment.t()) :: integer() | nil
  def cost(machine_state, execution_environment) do
    operation = MachineCode.current_operation(machine_state, execution_environment)

    if operation.function == :sstore do
      sstore_cost()
    else
      static_operation_cost(operation.function)
    end
  end

  @spec sstore_cost() :: non_neg_integer()
  def sstore_cost, do: 5

  @spec static_operation_cost(atom()) :: non_neg_integer | nil
  def static_operation_cost(operation) do
    fee_schedules = Map.keys(@fee_schedule)

    fee_list =
      for group <- fee_schedules,
          operation in @fee_schedule[group].operations,
          do: @fee_schedule[group].value

    List.first(fee_list)
  end

  @spec insufficient_gas?(MachineState.t(), ExecutionEnvironment.t()) :: boolean()
  def insufficient_gas?(machine_state, execution_environment) do
    cost = cost(machine_state, execution_environment)
    cost > machine_state.gas
  end
end
