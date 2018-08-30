defmodule TinyEVM do
  @moduledoc"""
  A simplified version of the Ethereum Virtual Machine.

  ## Note

    This implementation is an abbreviated version of the the
    Ethereum Virtual Machine, supporting only a limited subset
    of the functionality described in the Yellow Paper. The Execution
    Model returns **only** the remaining gas and account storage
    for the Ethereum Common VM Test in question.

    The accrued substate, `A`, has been omitted from this implementation
    because the tests in question only touch a single account without any
    refunds, suicides, or logs.
  """

  alias TinyEVM.{WorldState, MachineState, ExecutionEnvironment, MachineCode}

  @type gas :: non_neg_integer()
  @type storage :: %{optional(String.t()) => map()}
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
  @spec execution_model_entry(String.t(), gas, binary()) :: {gas, storage}
  def execution_model_entry(address, gas, code) do
    world_state = %WorldState{}
    machine_state = %MachineState{gas: gas}

    machine_code = MachineCode.convert_string_to_machine_code(code)
    execution_environment = %ExecutionEnvironment{machine_code: machine_code}

    {world_state, gas, output} = execution_xi(world_state, machine_state, execution_environment)
    {gas, world_state}
  end

  @doc"""
  `Ξ` function defined in Section 9.4 of the Yellow Paper.

  This implmentation
  """
  @spec execution_xi(WorldState.t(), MachineState.t(), ExecutionEnvironment.t()) :: {WorldState.t(), MachineState.t(), output}
  def execution_xi(world_state, machine_state, execution_environment) do
    {world_state_prime, machine_state_prime, output} =
      recursive_execution_chi(world_state, machine_state, execution_environment, {world_state, machine_state, execution_environment})
  end

  @doc"""
  Modified `X`. More docs to come...
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
    case exceptional_halt_state?(world_state, machine_state, execution_environment) do
      true ->
        {original_world_state, original_machine_state, original_execution_environment, :failed}

      false ->
        {world_state_n, machine_state_n, execution_environment_n} =
          cycle(world_state, machine_state, execution_environment)

        case normal_halt_state?(world_state_n, execution_environment_n) do
          {false, _} ->
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

    {machine_state_n, execution_environment_n} = Operation.run(operation, machine_state, execution_environment)

    final_machine_state = MachineState.move_program_counter(machine_state_n, operation)
  end

  @doc"""
  `Z` function in Yellow Paper. More docs to come...

  If this function evaluates to true, any changes are discarded except for gas used.
  """
  @spec exceptional_halt_state?(WorldState.t(), MachineState.t(), ExecutionEnviornment.t()) :: boolean()
  def exceptional_halt_state?(world_state, machine_state, execution_environment) do
    # placeholder for now
    false
  end

  @doc"""
  The Normal Halting function, `H`, described in Section 9.4.4 of the Yellow Paper.
  """
  @spec normal_halt_state?(MachineState.t(), ExecutionEnvironment.t()) :: boolean() | {boolean(), output}
  def normal_halt_state?(machine_state, execution_environment) do
    # placeholder for now
    false
  end
end
