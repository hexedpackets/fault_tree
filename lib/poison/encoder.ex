defimpl Poison.Encoder, for: Decimal do
  def encode(dec, options) do
    dec
    |> Decimal.to_string(:scientific)
    |> Poison.Encoder.BitString.encode(options)
  end
end

defimpl Poison.Encoder, for: Tuple do
  def encode({k, n}, options) do
    %{"k" => k, "n" => n}
    |> Poison.Encoder.Map.encode(options)
  end
end
