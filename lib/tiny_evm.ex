defmodule TinyEVM do
  @moduledoc"""
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
  @type output :: binary() | :failed

  @doc"""
  The entry point for the TinyEVM Execution Model, described in
  Section 9 of the Yellow Paper.

  ## Parameters

    - `address`: The address any storage modifcations are applied to.
    - `gas`: Total gas units sent for this "transaction" (not actually
      a formal transaction, however a proxy for a transaction in the TinyEVM).
    - `code`: The binary of the EVM machine code (meant to represent the
      contract code that would normally be associated with the address).

  ## Returns

    - `g′`: The remaining gas after the Execution Model completes.
    - `σ′`: The resultant state after the Execution Model completes.

  ## Examples

    # Some pretty cool examples go here
  """
  @spec execution_model_entry(String.t(), gas, binary()) :: {gas, WorldState.t()}
  def execution_model_entry(address, gas, code) do
    world_state = %{}
    machine_state = %MachineState{gas: gas}
    # setting permission for state modificaiton to true for this implementation
    execution_environment = %ExecutionEnvironment{address: address, machine_code: code, permission: true}

    {world_state_prime, machine_state_prime, _output} = execution_xi(world_state, machine_state, execution_environment)
    {machine_state_prime.gas, world_state_prime}
  end

  @doc"""
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
    - `machine_state_prime`:
    - `output`:
  """
  @spec execution_xi(WorldState.t(), MachineState.t(), ExecutionEnvironment.t()) :: {WorldState.t(), MachineState.t(), output}
  def execution_xi(world_state, machine_state, execution_environment) do
    {world_state_prime, machine_state_prime, output} =
      recursive_execution_chi(world_state, machine_state, execution_environment, {world_state, machine_state, execution_environment})
  end

  @doc"""
  `X` function defined in Section 9.4 of the Yellow Paper.

  Recursively runs the Execution Cycle, `O`, until the machine
  reaches either a normal or exceptional halting state. The machine
  is guaranteed to reach a halting state due to the requirement of
  gas for each cycle.

  ## Paramaters

    - `world_state`: The world state prior to running a cyle in the VM.
    - `machine_state`: The machine state prior to running a cycle in the VM.
    - `execution_environment`: The execution environment prior to running
      a cycle in the VM.
    - `original_world_state`: The world state passed in by the `Ξ` function. Used
      for reverting any state changes in the event of an exceptional halt.
    - `original_machine_state:`: The machine state passed in by the `Ξ` function. Used
      for reverting any state changes in the event of an exceptional halt.
    - `original_execution_environment:`: The execution environment passed in by the `Ξ` function. Used
      for reverting any state changes in the event of an exceptional halt.


  ## Returns

    - `
  """
  @spec recursive_execution_chi(
          WorldState.t(),
          MachineState.t(),
          ExecutionEnviornment.t(),
          {WorldState.t(),
            MachineState.t(),
            ExecutionEnvironment.t()}
        ) :: {WorldState.t(), MachineState.t(), output}
  def recursive_execution_chi(
        world_state,
        machine_state,
        execution_environment,
        {original_world_state,
          original_machine_state,
          original_execution_environment}
      ) do
    case exceptional_halt_state?(machine_state, execution_environment) do
      true ->
        {original_world_state, original_machine_state, original_execution_environment, :failed}

      false ->
        {world_state_n, machine_state_n, execution_environment_n} =
          cycle(world_state, machine_state, execution_environment)

        case normal_halt_state?(machine_state_n, execution_environment_n) do
          false ->
            recursive_execution_chi(world_state_n, machine_state_n, execution_environment_n, {original_world_state, original_machine_state, original_execution_environment})

          {true, output} ->
            {world_state_n, machine_state_n, output}
        end
    end
  end

  @doc"""
  The Execution Cycle, defined as `O` in Section 9.4 of the Yellow Paper.
  """
  @spec cycle(WorldState.t(), MachineState.t(), ExecutionEnvironment.t()) :: {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
  def cycle(world_state, machine_state, execution_environment) do
    operation = MachineCode.current_operation(machine_state, execution_environment)
    machine_state_less_gas = Gas.subtract_gas(machine_state, execution_environment)

    {world_state_n, machine_state_n, execution_environment_n} = Operation.run(world_state, operation, machine_state_less_gas, execution_environment)
    final_machine_state = MachineState.move_program_counter(machine_state_n, operation)

    {world_state_n, final_machine_state, execution_environment_n}
  end

  @doc"""
  `Z` function in Yellow Paper. More docs to come...

  If this function evaluates to true, any changes are discarded except for gas used.
  """
  @spec exceptional_halt_state?(MachineState.t(), ExecutionEnviornment.t()) :: boolean()
  def exceptional_halt_state?(machine_state, execution_environment) do
    operation =
      Operation.get_operation_at(execution_environment.machine_code, machine_state.program_counter)
      |> Operation.metadata()

      cond do
        Gas.insufficient_gas?(machine_state, execution_environment) -> true

        Utils.invalid_instruction?(operation) -> true

        Utils.insufficient_stack_items?(operation, machine_state) -> true

        # Omitting check for JUMP/JUMPI since the opcodes aren't implemented

        Utils.will_exceed_stack_size?(operation, machine_state) -> true

        # Only state modificaiton opcode implemented is sstore, no need to check for others
        !execution_environment.permission && operation.mnemonic == :sstore -> true

        true -> false
      end
  end

  @doc"""
  The Normal Halting function, `H`, described in Section 9.4.4 of the Yellow Paper.

  ## Note
    This implementation doesn't test RETURN, REVERT, STOP, or SELFDESTRUCT opcodes,
    so H_return has been omitted.
  """
  @spec normal_halt_state?(MachineState.t(), ExecutionEnvironment.t()) :: boolean() | {boolean(), output}
  def normal_halt_state?(machine_state, execution_environment) do
    if machine_state.program_counter >= byte_size(execution_environment.machine_code) do
      {true, machine_state.last_return_data}
    else
      false
    end
  end
end
