defmodule Handkit.Middleware.KeyTransform do
  @moduledoc false
  # Tesla middleware responsible for automatically converting request and response
  # keys to and from snake case to camel case formatting.

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, _ops) do
    env
    |> camelize_keys()
    |> Tesla.run(next)
    |> case do
      {:ok, env} ->
        {:ok, underscore_keys(env)}
      {:error, error} ->
        {:error, error}
    end
  end

  # Expends the request body and converts keys to camel case
  defp camelize_keys(%{body: body} = env) do
    Tesla.put_body(env, expand(body, &Inflex.camelize(&1, :lower)))
  end

  # Expends the response body and converts keys to underscore case
  defp underscore_keys(%{body: body} = env) do
    Tesla.put_body(env, expand(body, &Inflex.underscore/1))
  end

  # Recursively expands the parameters
  defp expand(value, fun) when is_map(value) do
    Enum.into(value, %{}, &expand(&1, fun))
  end

  defp expand(value, fun) when is_list(value) do
    Enum.map(value, &expand(&1, fun))
  end

  defp expand({key, val}, fun) do
    {fun.(key), expand(val, fun)}
  end

  defp expand(value, _fun), do: value

end
