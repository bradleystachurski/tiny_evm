defmodule TinyEVM.MachineState do
  @moduledoc """
  The machine state of the EVM, `μ`, as defined in Section
  9.4.1 in the Yellow Paper.
  """

  alias TinyEVM.{Stack, MachineState, MachineCode.Metadata}

  @behaviour Access

  defstruct gas: 0,
            program_counter: 0,
            memory_contents: <<>>,
            words_in_memory: 0,
            stack: [],
            last_return_data: []

  @type program_counter :: integer()

  @typedoc """
  From Yellow Paper:

    `μ` is defined as the tuple `(g, pc, m, i, s)` where
      - `g`: gas available
      - `pc`: program counter (where pc ∈ N_256)
      - `m`: memory contents
      - `i`: active number of words in memory (0 based index)
      - `s`: stack contents
  """
  @type t :: %__MODULE__{
          gas: non_neg_integer(),
          program_counter: program_counter,
          memory_contents: binary(),
          words_in_memory: integer(),
          stack: Stack.t(),
          last_return_data: [integer()] | []
        }

  @doc """
  Removes and returns `n` items from the stack and updates the
  machine state.

  ## Paramaters

    - `machine_state`: The given machine state.
    - `n`: The number of items to remove and return from the stack.

  ## Returns

    - `values`: Items returned from the stack.
    - `machine_state`: Updated machine state.

  ## Examples
      iex> TinyEVM.MachineState.pop_n(%TinyEVM.MachineState{stack: [1, 2, 3]}, 3)
      {[1, 2, 3], %TinyEVM.MachineState{stack: []}}

      iex> TinyEVM.MachineState.pop_n(%TinyEVM.MachineState{stack: [1, 2, 3, 4, 5]}, 1)
      {[1], %TinyEVM.MachineState{stack: [2, 3, 4, 5]}}
  """
  @spec pop_n(MachineState.t(), non_neg_integer()) :: {[integer()], MachineState.t()}
  def pop_n(machine_state, n) do
    {values, stack} = Stack.pop_n(machine_state.stack, n)
    machine_state = %{machine_state | stack: stack}
    {values, machine_state}
  end

  @spec move_program_counter(MachineState.t(), Metadata.t()) :: MachineState.t()
  def move_program_counter(machine_state, operation) do
    next_position = machine_state.program_counter + operation.machine_code_offset + 1
    %{machine_state | program_counter: next_position}
  end

  @spec fetch(t(), term()) :: {:ok, term()} | :error
  def fetch(machine_state, key) do
    machine_state
    |> Map.from_struct()
    |> Map.fetch(key)
  end

  def get_and_update(data, key, function) do
    {get, updated_map} =
      data
      |> Map.from_struct()
      |> Map.get_and_update(key, function)

    {get, struct(MachineState, updated_map)}
  end
end
