defmodule TinyEVM.MachineState do
  @moduledoc"""
  The machine state of the EVM, `μ`, as defined in Section
  9.4.1 in the Yellow Paper.
  """

  alias TinyEVM.{Stack}

  defstruct gas: 0,
            program_counter: 0,
            memory_contents: <<>>,
            words_in_memory: 0,
            stack: [],
            last_return_data: []

  @type program_counter :: integer()

  @typedoc"""
  From Yellow Paper:

    `μ` is defined as the tuple `(g, pc, m, i, s)` where
      - `g`: gas available
      - `pc`: program counter (where pc ∈ N_256)
      - `m`: memory contents
      - `i`: active number of words in memory (0 based index)
      - `s`: stack contents
  """
  @type t :: %__MODULE__{
               gas: integer(),
               program_counter: program_counter,
               memory_contents: binary(),
               words_in_memory: integer(),
               stack: [integer()],
               last_return_data: [integer()] | []
             }

  def pop_n(machine_state, n) do
    {values, stack} = Stack.pop_n(machine_state.stack, n)
    machine_state = %{machine_state | stack: stack}
    {values, machine_state}
  end
end