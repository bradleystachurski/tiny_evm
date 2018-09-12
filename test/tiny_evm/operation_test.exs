defmodule TinyEVM.OperationTest do
  use ExUnit.Case
  doctest TinyEVM.Operation

  describe "run/4" do
    test "runs :mulmod opcode" do
      world_state = %{}

      operation = %TinyEVM.Operation.Metadata{
        args: [],
        function: :mulmod,
        inputs: 3,
        machine_code_offset: 0,
        mnemonic: :mulmod,
        outputs: 1,
        value: 9
      }

      machine_state = %TinyEVM.MachineState{
        gas: 100_000,
        last_return_data: nil,
        memory_contents: "",
        program_counter: 1,
        stack: [4, 2, 5],
        words_in_memory: 0
      }

      execution_environment = %TinyEVM.ExecutionEnvironment{
        address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6",
        block_header: nil,
        call_depth: nil,
        data: "",
        gas_price: 0,
        machine_code: <<96>>,
        origin: nil,
        permission: true,
        sender: nil,
        value: 0
      }

      updated_vm_map = %{
        execution_environment: %TinyEVM.ExecutionEnvironment{
          address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6",
          block_header: nil,
          call_depth: nil,
          data: "",
          gas_price: 0,
          machine_code: <<96>>,
          origin: nil,
          permission: true,
          sender: nil,
          value: 0
        },
        machine_state: %TinyEVM.MachineState{
          gas: 100_000,
          last_return_data: 3,
          memory_contents: "",
          program_counter: 1,
          stack: [3],
          words_in_memory: 0
        },
        world_state: %{}
      }

      {updated_world_state, updated_machine_state, updated_execution_environment} =
        TinyEVM.Operation.run(world_state, operation, machine_state, execution_environment)

      assert updated_world_state == updated_vm_map.world_state
      assert updated_machine_state == updated_vm_map.machine_state
      assert updated_execution_environment == updated_vm_map.execution_environment
    end

    test "runs :xor opcode" do
      world_state = %{}

      operation = %TinyEVM.Operation.Metadata{
        args: [],
        function: :xor,
        inputs: 2,
        machine_code_offset: 0,
        mnemonic: :xor,
        outputs: 1,
        value: 24
      }

      machine_state = %TinyEVM.MachineState{
        gas: 100_000,
        last_return_data: 3,
        memory_contents: "",
        program_counter: 1,
        stack: [3, 1],
        words_in_memory: 0
      }

      execution_environment = %TinyEVM.ExecutionEnvironment{
        address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6",
        block_header: nil,
        call_depth: nil,
        data: "",
        gas_price: 0,
        machine_code: <<85>>,
        origin: nil,
        permission: true,
        sender: nil,
        value: 0
      }

      updated_vm_map = %{
        world_state: %{},
        machine_state: %TinyEVM.MachineState{
          gas: 100_000,
          last_return_data: 2,
          memory_contents: "",
          program_counter: 1,
          stack: [2],
          words_in_memory: 0
        },
        execution_environment: %TinyEVM.ExecutionEnvironment{
          address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6",
          block_header: nil,
          call_depth: nil,
          data: "",
          gas_price: 0,
          machine_code: <<85>>,
          origin: nil,
          permission: true,
          sender: nil,
          value: 0
        }
      }

      {updated_world_state, updated_machine_state, updated_execution_environment} =
        TinyEVM.Operation.run(world_state, operation, machine_state, execution_environment)

      assert updated_world_state == updated_vm_map.world_state
      assert updated_machine_state == updated_vm_map.machine_state
      assert updated_execution_environment == updated_vm_map.execution_environment
    end
  end
end
