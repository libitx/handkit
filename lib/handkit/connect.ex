defmodule Handkit.Connect do
  @moduledoc """
  A client module for connecting and interfacing with the Handcash Connect API
  endpoints.
  """
  alias Handkit.ConnectError
  alias Handkit.Middleware.{KeyTransform, SignedRequest}

  defstruct client: nil

  @typedoc "Handcash Connect client"
  @type t :: %__MODULE__{
    client: Tesla.Client.t
  }

  @typedoc "Connect environment"
  @type env :: :prod | :beta | :iae


  @envs %{
    prod: %{
      api_endpoint: "https://cloud.handcash.io",
      client_url: "https://app.handcash.io"
    },
    beta: %{
      api_endpoint: "https://beta-cloud.handcash.io",
      client_url: "https://beta-app.handcash.io"
    },
    iae: %{
      api_endpoint: "https://iae-cloud.handcash.io",
      client_url: "https://iae-app.handcash.io"
    },
  }

  @doc """
  Returns the Handcash API URL for the given environment.
  """
  @spec api_endpoint(env) :: String.t
  def api_endpoint(env \\ :prod),
    do: get_in(@envs, [env, :api_endpoint])


  @doc """
  Returns the Handcash Client URL for the given environment.
  """
  @spec client_url(env) :: String.t
  def client_url(env \\ :prod),
    do: get_in(@envs, [env, :client_url])


  @doc """
  Initiates a new Handcash Connect client.

  Must be passed a valid auth token.
  """
  @spec init_client(String.t, env) :: t
  def init_client(auth_token, env \\ :prod) do
    middleware = [
      {Tesla.Middleware.BaseUrl, api_endpoint(env)},
      KeyTransform,
      Tesla.Middleware.JSON,
      {SignedRequest, auth_token}
    ]

    struct(__MODULE__, [
      client: Tesla.client(middleware)
    ])
  end


  @doc """
  Handles the result from a Connect request.

  If the result is a success, the request body is returned. Where the request
  returns an error, a `%ConnectError{}` exception is returned.
  """
  @spec handle_result(Tesla.Env.result, String.t | nil) :: {:ok, any} | {:error, any}
  def handle_result(result, key \\ nil)

  def handle_result({:ok, %{status: status, body: body}}, nil) when status < 400,
    do: {:ok, body}

  def handle_result({:ok, %{status: status, body: body}}, key) when status < 400,
    do: {:ok, Map.get(body, key)}

  def handle_result({:ok, %{body: body, status: staus}}, _key) do
    error = ConnectError.exception([
      message: Map.get(body, "message"),
      info: Map.get(body, "info"),
      status: staus
    ])
    {:error, error}
  end

  def handle_result({:error, error}, _key), do: {:error, error}

end
