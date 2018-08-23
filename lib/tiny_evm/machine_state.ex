defmodule TinyEVM.MachineState do
  @moduledoc"""
  The machine state of the EVM, `μ`, as defined in Section
  9.4.1 in the Yellow Paper.
  """

  defstruct gas: nil,
            program_counter: 0,
            memory_contents: <<>>,
            words_in_memory: nil,
            stack: nil

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
          program_counter: integer(),
          memory_contents: binary(),
          words_in_memory: integer(),
          stack: [integer()]
        }
end