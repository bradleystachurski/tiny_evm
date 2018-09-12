defmodule TinyEVMTest do
  use ExUnit.Case
  doctest TinyEVM

  alias TinyEVM.EthTest

  @common_tests_path "./test/support/ethereum_common_tests/VMTests/"

  @tests [
    "vmArithmeticTest/mulmod1_overflow4.json",
    "vmPushDupSwapTest/swap14.json",
    "vmBitwiseLogicOperation/xor2.json"
  ]

  test "runs common test" do
    @tests
    |> Enum.map(&read_test_file/1)
    |> Enum.each(fn test ->
      {remaining_gas, storage} =
        TinyEVM.execution_model_entry(test.input.address, test.input.gas, test.input.code)

      assert remaining_gas == test.output.gas
      assert test.output.storage[test.input.address] == storage[test.input.address]
    end)
  end

  defp read_test_file(file_name) do
    file_path = @common_tests_path <> file_name

    EthTest.read(file_path)
  end

  test "runs normal-halting recursive_execution_chi" do
    world_state = %{}
    machine_state = %TinyEVM.MachineState{gas: 1_000_000}

    execution_environment = %TinyEVM.ExecutionEnvironment{
      address: "0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6",
      machine_code:
        <<96, 5, 96, 2, 127, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 9, 96, 0, 85>>,
      permission: true
    }

    {updated_world_state, updated_machine_state} =
      TinyEVM.recursive_execution_chi(
        world_state,
        machine_state,
        execution_environment,
        {world_state, machine_state, execution_environment}
      )

    expected_world_state = %{"0x0f572e5295c57f15886f9b263e2f6d2d6c7b5ec6" => %{0 => 3}}

    expected_machine_state = %TinyEVM.MachineState{
      gas: 979_980,
      program_counter: 41,
      stack: [],
      last_return_data: 0,
      memory_contents: "",
      words_in_memory: 0
    }

    assert expected_world_state == updated_world_state
    assert expected_machine_state == updated_machine_state
  end
end
