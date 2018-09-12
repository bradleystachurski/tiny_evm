defmodule TinyEVM do
  @moduledoc """
  A simplified version of the Ethereum Virtual Machine.

  ## Note

    This implementation is an abbreviated version of the the
    Ethereum Virtual Machine, supporting only a limited subset
    of the functionality described in the Yellow Paper. The Execution
    Model returns **only** the remaining gas and account storage
    for the Ethereum Common VM Tests used in the Tiny EVM test assignment.

    The accrued substate, `A`, has been omitted from this implementation
    because the tests in question only touch a single account without any
    refunds, suicides, or logs.
  """

  alias TinyEVM.{WorldState, MachineState, ExecutionEnvironment, MachineCode, Operation, Gas}
  alias Utils

  @type gas :: non_neg_integer()

  @doc """
  The entry point for the TinyEVM Execution Model, described in
  Section 9 of the Yellow Paper.

  ## Parameters

    - `address`: The address any storage modifcations are applied to.
    - `gas`: Total gas units sent for this "transaction" (not actually
      a formal transaction, however an abstraction for a transaction in the TinyEVM).
    - `code`: The binary of the EVM machine code (meant to represent the
      contract code that would normally be associated with the address).

  ## Returns

    - `g′`: The remaining gas after the Execution Model completes.
    - `σ′`: The resultant state after the Execution Model completes.

  ## Examples

    iex> TinyEVM.execution_model_entry("0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", 100000, <<96, 14, 96, 13, 96, 12, 96, 11, 96, 10, 96, 9, 96, 8, 96, 7, 96, 6, 96, 5, 96, 4, 96, 3, 96, 2, 96, 1, 96, 3, 157, 85>>)
    {79952, %{"0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6" => %{14 => 1}}}

    iex> TinyEVM.execution_model_entry("0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", 1000000, <<96, 5, 96, 2, 127, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 9, 96, 0, 85>>)
    {979980, %{"0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6" => %{0 => 3}}}

    iex> TinyEVM.execution_model_entry("0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", 100000, <<96, 1, 96, 3, 24, 96, 0, 85>>)
    {79988, %{"0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6" => %{0 => 2}}}
  """
  @spec execution_model_entry(String.t(), gas, binary()) :: {gas, WorldState.t()}
  def execution_model_entry(address, gas, code) do
    world_state = %{}
    machine_state = %MachineState{gas: gas}
    # setting permission for state modificaiton to true for this implementation
    execution_environment = %ExecutionEnvironment{
      address: address,
      machine_code: code,
      permission: true
    }

    {world_state_prime, machine_state_prime} =
      execution_xi(world_state, machine_state, execution_environment)

    {machine_state_prime.gas, world_state_prime}
  end

  @doc """
  `Ξ` function defined in Section 9.4 of the Yellow Paper.

  ## Note

    This implementation forgoes the substate `A` defined in the Yellow Paper and
    is omitted from the `Ξ` function and all sub-functions.

  ## Paramaters

    - `world_state`: EVM account state prior to the execution model running.
    - `machine_state`: MachineState prior to the execution model running.
    - `execution_environment`: ExecutionEnvironment prior to the execution model running.

  ## Returns

    - `world_state_prime`: The resultant EVM account state after recursive execution.
    - `machine_state_prime`: The resultant machine state after recursive execution.

  ## Examples

    iex> TinyEVM.execution_xi(%{}, %TinyEVM.MachineState{gas: 1000000}, %TinyEVM.ExecutionEnvironment{address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6", machine_code: <<96, 5, 96, 2, 127, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 9, 96, 0, 85>>, permission: true})
    {%{"0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6" => %{0 => 3}},
    %{
       gas: 979980,
       last_return_data: 0,
       memory_contents: "",
       program_counter: 41,
       stack: [],
       words_in_memory: 0
    }}
  """
  @spec execution_xi(WorldState.t(), MachineState.t(), ExecutionEnvironment.t()) ::
          {WorldState.t(), MachineState.t()}
  def execution_xi(world_state, machine_state, execution_environment) do
    recursive_execution_chi(
      world_state,
      machine_state,
      execution_environment,
      {world_state, machine_state, execution_environment}
    )
  end

  @doc """
  `X` function defined in Section 9.4 of the Yellow Paper.

  Recursively runs the Execution Cycle, `O`, until the machine
  reaches either a normal or exceptional halting state. The machine
  is guaranteed to reach a halting state due to the requirement of
  gas for each cycle.
  """
  @spec recursive_execution_chi(
          WorldState.t(),
          MachineState.t(),
          ExecutionEnviornment.t(),
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
        ) :: {WorldState.t(), MachineState.t()}
  def recursive_execution_chi(
        world_state,
        machine_state,
        execution_environment,
        {original_world_state, original_machine_state, original_execution_environment}
      ) do
    if exceptional_halt_state?(machine_state, execution_environment) do
      {original_world_state, original_machine_state}
    else
      {world_state_n, machine_state_n, execution_environment_n} =
        cycle(world_state, machine_state, execution_environment)

      normal_halt_or_cycle(
        world_state_n,
        machine_state_n,
        execution_environment_n,
        {original_world_state, original_machine_state, original_execution_environment}
      )
    end
  end

  @spec normal_halt_or_cycle(
          WorldState.t(),
          MachineState.t(),
          ExecutionEnvironment.t(),
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
        ) :: {WorldState.t(), MachineState.t()}
  defp normal_halt_or_cycle(
         world_state,
         machine_state,
         execution_environment,
         {original_world_state, original_machine_state, original_execution_environment}
       ) do
    if normal_halt_state?(machine_state, execution_environment),
      do: {world_state, machine_state},
      else:
        recursive_execution_chi(
          world_state,
          machine_state,
          execution_environment,
          {original_world_state, original_machine_state, original_execution_environment}
        )
  end

  @doc """
  The Execution Cycle, defined as `O` in Section 9.5 of the Yellow Paper.
  """
  @spec cycle(WorldState.t(), MachineState.t(), ExecutionEnvironment.t()) ::
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
  def cycle(world_state, machine_state, execution_environment) do
    operation = MachineCode.current_operation(machine_state, execution_environment)
    machine_state_less_gas = Gas.subtract_gas(machine_state, execution_environment)

    {world_state_n, machine_state_n, execution_environment_n} =
      Operation.run(world_state, operation, machine_state_less_gas, execution_environment)

    final_machine_state = MachineState.move_program_counter(machine_state_n, operation)

    {world_state_n, final_machine_state, execution_environment_n}
  end

  @doc """
  Exceptional Halting function, defined as `Z` in Section 9.4.2 of the Yellow Paper.
  """
  @spec exceptional_halt_state?(MachineState.t(), ExecutionEnviornment.t()) :: boolean()
  def exceptional_halt_state?(machine_state, execution_environment) do
    operation =
      Operation.get_operation_at(
        execution_environment.machine_code,
        machine_state.program_counter
      )
      |> Operation.metadata()

    is_exceptional?(operation, machine_state, execution_environment)
  end

  @spec is_exceptional?(Metadata.t(), MachineState.t(), ExecutionEnvironment.t()) :: boolean()
  defp is_exceptional?(operation, machine_state, execution_environment) do
    # Omitting checks for JUMP/JUMPI since opcodes aren't implemented
    Gas.insufficient_gas?(machine_state, execution_environment) ||
      Utils.invalid_instruction?(operation) ||
      Utils.insufficient_stack_items?(operation, machine_state) ||
      Utils.will_exceed_stack_size?(operation, machine_state) ||
      (!execution_environment.permission && operation.mnemonic == :sstore)
  end

  @doc """
  The Normal Halting function, `H`, described in Section 9.4.4 of the Yellow Paper.

  ## Note
    This implementation doesn't test RETURN, REVERT, STOP, or SELFDESTRUCT opcodes,
    so H_return has been omitted.
  """
  @spec normal_halt_state?(MachineState.t(), ExecutionEnvironment.t()) :: boolean()
  def normal_halt_state?(machine_state, execution_environment) do
    machine_state.program_counter >= byte_size(execution_environment.machine_code)
  end
end
