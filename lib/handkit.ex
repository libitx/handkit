defmodule Handkit do
  @moduledoc """
  ![Handkit](https://github.com/libitx/handkit/raw/master/media/poster.png)

  ![License](https://img.shields.io/github/license/libitx/handkit?color=informational)

  Handkit is an Elixir client for the [Handcash Connect API](https://handcash.dev).

  Handkit offers 100% coverage of the Handcash Connect APIs, so you can build
  blazing fast Bitcoin apps with Elixir in hours.

  ## Installation

  The package can be installed by adding `handkit` to your list of dependencies
  in `mix.exs`.

      def deps do
        [
          {:handkit, "~> #{ Mix.Project.config[:version] }"}
        ]
      end

  You will need to register your application using the Handcash
  [developer dashboard](https://dashboard.handcash.dev) and make a note of your
  app's **app ID**.

  ## User authorization

  Familiarize yourself with the Handcash Connect
  [user authorization flow](https://docs.handcash.dev/authorization/).

  Within your Elixir app, use Handkit to generate a redirection URL and present
  a button in your app's UI for users to click and grant your app's permissions.

      iex> redirect_url = Handkit.get_redirection_url("123456789")
      "https://app.handcash.io/#/authorizeApp?appId=123456789"

  When a user grants your app's permissions, they will be redirected back to the
  URL configured in the developer dashboard. You app must handle that request
  and capture the `authToken` parameter. For example, a Phoenix action to
  capture the `authToken` and store it in a session may look like this:

      def auth(conn, %{"authToken" => auth_token}) do
        conn
        |> put_session(:auth_token, auth_token)
        |> put_flash(:info, "Successfully authenticated with Handcash")
        |> redirect(to: "/app")
      end

  ## Usage

  Once a user is connected, the Handcash Connect APIs are interfaced with by
  creating a [`Connect Client`](`t:Handkit.Connect.t/0`) struct and passing that
  to all subsequent API calls.

      # Create the client
      iex> client = Handkit.create_connect_client(auth_token)
      %Connect{}

      # Get the full profile of the currently connected user
      iex> Handkit.Profile.get_current_profile(client)
      {:ok, %{
        "private_profile" => %{
          "email" => "StevenUrban1234@gmail.com",
          "phone_number" => "+11234567891"
        },
        "public_profile" => %{
          "avatar_url" => "https://handcash.io/avatar/7d399a0c-22cf-40cf-b162-f5511a4645db",
          "bitcoin_unit" => "DUR",
          "display_name" => "Steven Urban K.",
          "handle" => "stuk_91",
          "id" => "5f15c31c3c177d003028eb97",
          "local_currency_code" => "USD",
          "paymail" => "BrandonC@handcash.io"
        }
      }}

      # Create a payment
      iex> payment_params = %{
      ...>   app_action: "test",
      ...>   description: "testing testing...",
      ...>   payments: [%{to: "Libs", amount: 5, currency_code: "DUR"}]
      ...> }
      iex> Handkit.Wallet.pay(client, payment_params)
      {:ok, %{
        "app_action" => "test",
        "attachments" => [],
        "fiat_currency_code" => "GBP",
        "fiat_exchange_rate" => 115.93006376003423,
        "note" => "testing testing...",
        "participants" => [
          %{
            "alias" => "Libs",
            "amount" => 2500,
            "display_name" => "Libitx",
            "profile_picture_url" => "https://www.gravatar.com/avatar/8c69771156957d453f9b74f9d57a523c?d=identicon",
            "response_note" => "",
            "type" => "user"
          }
        ],
        "raw_transaction_hex" => "0100000001019bab35b4d62fceaa6953c6b95ecf9e3c25e40836fc055d7b47addd9ce687a5010000006a4730440220221b6c59751de9576efd9e60cb7c648141e5331602656c97dc8722b740502287022025d9868894f72b4b0bcc70e95dc4820a9cbd79721974d95b184b72933af6cec4412102ed3547b19ce413e2e36c6182737d4d05b0e27022886bec96a7f7f2ea89f8cb78ffffffff03c4090000000000001976a914715779ac130d8ef5668425ce6e8f68ebd6c4596688acc4090000000000001976a914b0e9e9fa4ec584f76e4564d3f646151ce201920e88ac5c040000000000001976a914da5d00c49e00b27d5dbc59204230afa3f059b16888ac00000000",
        "satoshi_amount" => 2500,
        "satoshi_fees" => 128,
        "time" => 1624025595,
        "transaction_id" => "5a139f3f475f48001d733c8c767fa7124bb2835d927e01dd2782effd22f7081b",
        "type" => "send"
      }}

  Refer to the following modules for details of all the available API calls.

  * `Handkit.Profile`
  * `Handkit.Wallet`
  """
  alias Handkit.Connect

  @doc """
  Returns a redirection URL for the given app ID.

  Your app should redirect the user and they will be asked to grant your app
  permissions.

  Once the user selects *accept* or *decline*, they will be redirected back your
  app's *Authorization Success URL* or *Authorization Failed URL*.

  You app must handle that request and capture the `authToken` parameter.

  ## Example

      iex> redirect_url = Handkit.get_redirection_url("123456789")
      "https://app.handcash.io/#/authorizeApp?appId=123456789"
  """
  @spec get_redirection_url(String.t, map, Connect.env) :: String.t
  def get_redirection_url(app_id, query \\ %{}, env \\ :prod) when is_map(query) do
    client_url = Connect.client_url(env)
    query_str = query
    |> Map.put("appId", app_id)
    |> Tesla.encode_query()

    "#{ client_url }/#/authorizeApp?#{ query_str }"
  end


  @doc """
  Creates a Handcash Connect Client from the given auth token.

  The client can then passed to all subsequent API functions.

  ## Example

      iex> client = Handkit.create_connect_client(auth_token)
      %Connect{}
  """
  @spec create_connect_client(String.t, Connect.env) :: Connect.t
  def create_connect_client(auth_token, env \\ :prod) do
    Connect.init_client(auth_token, env)
  end

end
