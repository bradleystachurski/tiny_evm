defmodule TinyEVM.WorldState do
  @moduledoc """
  A simplified World State represented by `σ` in the Yellow Paper.

  This implementation only supports passing a small subset of
  the Ethereum Common VM Tests, so the World State is implemented
  as a mapping between accounts represented as strings and
  the account's state represented as a map. A full implementation of
  the EVM will maintain the World State in a modified Merkle Patricia Trie as
  a mapping between 160 bit addresses and RLP serialized account states.
  """

  @typedoc """
  A modified World State, represented as a mapping of addresses (String) to
  account states (map)
  """
  @type t :: %{String.t() => map()} | %{}
end
