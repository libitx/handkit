defmodule Handkit.Middleware.SignedRequest do
  @moduledoc false
  # Tesla middleware responsible for signing each request with the Handcash
  # Connect auth token.

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, auth_token) do
    key = auth_token
    |> Base.decode16!(case: :lower)
    |> Curvy.Key.from_privkey()

    timestamp = DateTime.now!("Etc/UTC")
    |> DateTime.to_iso8601()

    headers = [
      {"oauth-publickey", Curvy.Key.to_pubkey(key) |> Base.encode16(case: :lower)},
      {"oauth-signature", get_request_sig(env, timestamp, key)},
      {"oauth-timestamp", timestamp},
    ]

    env
    |> Tesla.put_headers(headers)
    |> Tesla.run(next)
  end

  # Signs the request payload with the key
  defp get_request_sig(env, timestamp, key) do
    env
    |> get_request_payload(timestamp)
    |> Curvy.sign(key, encoding: :hex)
  end

  # Builds a payload from the request parameters
  defp get_request_payload(%{body: body, method: method, query: query, url: url}, timestamp) do
    method = method
    |> Atom.to_string()
    |> String.upcase()

    endpoint = case Tesla.build_url(url, query) |> URI.parse() do
      %{path: path, query: nil} ->
        path
      %{path: path, query: query} ->
        path <> "?" <> query
    end

    "#{ method }\n#{ endpoint }\n#{ timestamp }\n#{ body }"
  end

end
