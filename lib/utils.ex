defmodule Utils do
  @moduledoc"""
  Utility functions for the project
  """

  use Bitwise

  @int_size 256
  @max_int round(:math.pow(2, @int_size))

  @spec encode_val(integer() | list(integer()) | binary()) :: list(integer()) | integer()
  def encode_val(val) when is_binary(val), do: :binary.decode_unsigned(val)
  def encode_val(val) when is_list(val), do: Enum.map(val, &encode_val/1)
  def encode_val(val), do: val |> wrap_int |> encode_signed

  @spec wrap_int(integer()) :: integer()
  def wrap_int(n) when n > 0, do: band(n, @max_int - 1)
  def wrap_int(n), do: n

  @spec encode_signed(integer()) :: integer()
  def encode_signed(n) when n < 0, do: @max_int - abs(n)
  def encode_signed(n), do: n
end