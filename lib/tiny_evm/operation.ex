defmodule TinyEVM.Operation do
  @moduledoc """
  The Instruction Set defined in Appendix H of the Yellow Paper.
  """

  alias TinyEVM.{
    WorldState,
    MachineState,
    MachineCode,
    Operation.Metadata,
    Stack,
    ExecutionEnvironment
  }

  use Bitwise

  @type op_result :: any()
  @type operation :: atom()
  @type stack_args :: [integer()]

  @operations %{
    0x09 => %Metadata{
      value: 0x09,
      mnemonic: :mulmod,
      function: :mulmod,
      inputs: 3,
      outputs: 1,
      description: "Modulo multiplication operation"
    },
    0x18 => %Metadata{
      value: 0x18,
      mnemonic: :xor,
      function: :xor,
      inputs: 2,
      outputs: 1,
      description: "Bitwise XOR operation"
    },
    0x55 => %Metadata{
      value: 0x55,
      mnemonic: :sstore,
      function: :sstore,
      inputs: 2,
      outputs: 0
    },
    0x60 => %Metadata{
      value: 0x60,
      mnemonic: :push1,
      function: :push_n,
      args: [1],
      inputs: 0,
      outputs: 1,
      machine_code_offset: 1
    },
    0x7F => %Metadata{
      value: 0x7F,
      mnemonic: :push32,
      function: :push_n,
      args: [32],
      inputs: 0,
      outputs: 1,
      machine_code_offset: 32
    },
    0x9D => %Metadata{
      value: 0x9D,
      mnemonic: :swap14,
      function: :swap_n,
      inputs: 15,
      outputs: 15,
      description: "Exchange the 1st and 15th stack items"
    }
  }

  @spec run(WorldState.t(), Metadata.t(), MachineState.t(), ExecutionEnvironment.t()) ::
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
  def run(world_state, operation, machine_state, execution_environment) do
    {args, updated_machine_state} =
      operation_args(operation, machine_state, execution_environment, world_state)

    {world_state_n, machine_state_n, execution_environment_n} =
      apply(__MODULE__, operation.function, args)
      |> normalize_op_result(updated_machine_state.stack)
      |> merge_state(updated_machine_state, execution_environment, world_state)
  end

  def operation_args(operation, machine_state, execution_environment, world_state) do
    {stack_args, updated_machine_state} = MachineState.pop_n(machine_state, operation.inputs)

    vm_map = %{
      world_state: world_state,
      stack: updated_machine_state.stack,
      machine_state: updated_machine_state,
      execution_environment: execution_environment
    }

    args = operation.args ++ [stack_args, vm_map]

    {args, updated_machine_state}
  end

  @spec normalize_op_result(integer() | list(integer()) | op_result(), Stack.t()) :: op_result()
  def normalize_op_result(op_result, updated_stack) do
    if is_integer(op_result) || is_list(op_result) || is_binary(op_result) do
      last_return_data = Utils.encode_val(op_result)

      last_return_data_normalized =
        if is_list(last_return_data) do
          last_return_data
        else
          [last_return_data]
        end

      %{
        stack: Stack.push(updated_stack, last_return_data),
        last_return_data: last_return_data_normalized
      }
    else
      op_result
    end
  end

  # TODO: potentially change `merge_state` to be handled within the operation
  @spec merge_state(op_result(), MachineState.t(), ExecutionEnvironment.t(), WorldState.t()) ::
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
  def merge_state(op_result = %{}, machine_state, execution_environment, world_state) do
    next_world_state = op_result[:world_state] || world_state
    base_machine_state = op_result[:machine_state] || machine_state

    next_machine_state =
      if op_result[:stack],
        do: %{base_machine_state | stack: op_result[:stack]},
        else: base_machine_state

    next_machine_state =
      if op_result[:last_return_data],
        do: %{next_machine_state | last_return_data: op_result[:last_return_data]},
        else: %{next_machine_state | last_return_data: []}

    next_execution_environment = op_result[:execution_environment] || execution_environment

    {next_world_state, next_machine_state, next_execution_environment}
  end

  @spec get_operation_at(MachineCode.t(), MachineState.program_counter()) :: byte()
  def get_operation_at(machine_code, program_counter) do
    :binary.at(machine_code, program_counter)
  end

  @spec metadata(integer()) :: Metadata.t()
  def metadata(opcode) do
    Map.get(@operations, opcode)
  end

  def push_n(n, _args, %{
        machine_state: machine_state,
        execution_environment: %{machine_code: machine_code}
      }) do
    machine_code
    |> read_memory(machine_state.program_counter + 1, n)
    |> :binary.decode_unsigned()
  end

  @doc """
  `c` defined in Push Operations in Appendix H
  """
  def read_memory(memory, offset, bytes) do
    if memory == nil || offset > byte_size(memory) do
      bytes_in_bits = bytes * 8
      <<0::size(bytes_in_bits)>>
    else
      memory_size = byte_size(memory)
      final_pos = offset + bytes
      memory_bytes_final_pos = min(final_pos, memory_size)
      padding = (final_pos - memory_bytes_final_pos) * 8

      :binary.part(memory, offset, memory_bytes_final_pos - offset) <> <<0::size(padding)>>
    end
  end

  def inputs(operation, machine_state) do
    Stack.peep_n(machine_state.stack, operation.inputs)
  end

  @spec mulmod(stack_args(), map()) :: op_result()
  def mulmod([_s_0, _s_1, s_2], _vm_map) when s_2 == 0, do: 0
  def mulmod([s_0, s_1, s_2], _vm_map), do: rem(s_0 * s_1, s_2)

  def xor([s_0, s_1], _vm_map), do: bxor(s_0, s_1)

  def swap_n(stack_args, _vm_map) do
    updated_first = List.replace_at(stack_args, 0, List.last(stack_args))
    List.replace_at(updated_first, -1, List.first(stack_args))
  end

  def sstore([key, value], %{
        world_state: world_state,
        execution_environment: execution_environmnet
      }) do
    account_state = %{key => value}
    updated_world_state = Map.put(world_state, execution_environmnet.address, account_state)
    %{world_state: updated_world_state}
  end
end
