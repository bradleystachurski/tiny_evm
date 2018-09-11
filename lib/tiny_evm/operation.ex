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
      outputs: 1
    },
    0x18 => %Metadata{
      value: 0x18,
      mnemonic: :xor,
      function: :xor,
      inputs: 2,
      outputs: 1
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
      outputs: 15
    }
  }

  @doc """
  Runs the given operation in the EVM, returning the updated `world_state`,
  `machine_state`, and `execution_environment`.
  """
  @spec run(WorldState.t(), Metadata.t(), MachineState.t(), ExecutionEnvironment.t()) ::
          {WorldState.t(), MachineState.t(), ExecutionEnvironment.t()}
  def run(world_state, operation, machine_state, execution_environment) do
    args = operation_args(operation, machine_state, execution_environment, world_state)
    updated_vm_map = apply(__MODULE__, operation.function, args)

    {updated_vm_map.world_state, updated_vm_map.machine_state,
     updated_vm_map.execution_environment}
  end

  @doc """
  Reads the inputs for the given operation from the stack and returns a list of the relevant
  operations for the opcode.
  """
  @spec operation_args(Metadata.t(), MachineState.t(), ExecutionEnvironment.t(), WorldState.t()) ::
          [...]
  def operation_args(operation, machine_state, execution_environment, world_state) do
    {stack_args, updated_machine_state} = MachineState.pop_n(machine_state, operation.inputs)

    vm_map = %{
      world_state: world_state,
      machine_state: updated_machine_state,
      execution_environment: execution_environment
    }

    operation.args ++ [stack_args, vm_map]
  end

  @spec get_operation_at(MachineCode.t(), MachineState.program_counter()) :: byte()
  def get_operation_at(machine_code, program_counter) do
    :binary.at(machine_code, program_counter)
  end

  @spec metadata(integer()) :: Metadata.t()
  def metadata(opcode) do
    Map.get(@operations, opcode)
  end

  @doc """
  Implements `PUSH1` through `PUSH32` opcodes and returns the updated `vm_map`.
  """
  @spec push_n(non_neg_integer(), stack_args(), map()) :: map()
  def push_n(n, _stack_args, vm_map) do
    operation_result =
      vm_map.execution_environment.machine_code
      |> read_memory(vm_map.machine_state.program_counter + 1, n)
      |> :binary.decode_unsigned()

    put_in(vm_map.machine_state.last_return_data, operation_result)
    |> put_in([:machine_state, :stack], Stack.push(vm_map.machine_state.stack, operation_result))
  end

  @doc """
  `c` defined in Push Operations in Appendix H of the Yellow Paper.
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

  @doc """
  Implements the `MULMOD` opcode and updates the `vm_map`.
  """
  @spec mulmod(stack_args(), map()) :: map()
  def mulmod([_s_0, _s_1, s_2], vm_map) when s_2 == 0 do
    operation_result = 0

    put_in(vm_map.machine_state.last_return_data, operation_result)
    |> put_in([:machine_state, :stack], Stack.push(vm_map.machine_state.stack, operation_result))
  end

  def mulmod([s_0, s_1, s_2], vm_map) do
    operation_result = rem(s_0 * s_1, s_2)

    put_in(vm_map.machine_state.last_return_data, operation_result)
    |> put_in([:machine_state, :stack], Stack.push(vm_map.machine_state.stack, operation_result))
  end

  @doc """
  Implements the `XOR` opcode and updates the `vm_map`.
  """
  @spec xor(stack_args(), map()) :: map()
  def xor([s_0, s_1], vm_map) do
    operation_result = bxor(s_0, s_1)

    put_in(vm_map.machine_state.last_return_data, operation_result)
    |> put_in([:machine_state, :stack], Stack.push(vm_map.machine_state.stack, operation_result))
  end

  @doc """
  Implments the `SWAP1` through `SWAP16` opcodes and returns the updated `vm_map`.
  """
  def swap_n(stack_args, vm_map) do
    updated_first = List.replace_at(stack_args, 0, List.last(stack_args))
    operation_result = List.replace_at(updated_first, -1, List.first(stack_args))

    put_in(vm_map.machine_state.last_return_data, operation_result)
    |> put_in([:machine_state, :stack], Stack.push(vm_map.machine_state.stack, operation_result))
  end

  @doc """
  Implements the `SSTORE` opcode and returns the updated `vm_map`.

  Note: This implementation doesn't need to handle refunds, however this could
  be extneded with the addition of Substate.
  """
  @spec sstore(stack_args(), map()) :: map()
  def sstore([key, value], vm_map) do
    account_state = %{key => value}
    put_in(vm_map.world_state[vm_map.execution_environment.address], account_state)
  end
end
