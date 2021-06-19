defmodule Handkit.Wallet do
  @moduledoc """
  Module for interfacing with the Handcash Connect `profile` API endpoint.

  The wallet endpoint provides a way to create and fetch transactions on behalf
  of your connected users.
  """
  alias Handkit.Connect

  @endpoint "/v1/connect/wallet"

  @doc """
  Returns the exchange rate of the given currency code.

  If no currency code is given, defaults to `"USD"`.

  ## Example

      iex> Handkit.Wallet.get_exchange_rate(client, "GBP")
      {:ok, %{
        "exchange_rate_version" => "60cd1670bae3370b5c628574",
        "fiat_symbol" => "USD",
        "gbp" => 112.72077169559775,
        "rate" => 112.72077169559775
      }}
  """
  @spec get_exchange_rate(Connect.t, String.t) :: {:ok, map} | {:error, any}
  def get_exchange_rate(%Connect{client: client} = _client, currency \\ "USD") do
    client
    |> Tesla.get(@endpoint <> "/exchangeRate/#{ currency }")
    |> Connect.handle_result()
  end


  @doc """
  Returns transaction information from the given txid.

  Must be a transaction created by the same connected app.

  ## Example

      iex> Handkit.Wallet.get_payment(client, txid)
      {:ok, %{
        "app_action" => "like",
        "attachments" => [],
        "fiat_currency_code" => "GBP",
        "fiat_exchange_rate" => 115.72678751775005,
        "note" => "Hold my beer!🍺",
        "participants" => [
          %{
            "alias" => "nosetwo",
            "amount" => 5000,
            "display_name" => "Nose two",
            "profile_picture_url" => "https://res.cloudinary.com/hk7jbd3jh/image/upload/v1574787300/gntqxv6ed7sacwpfwumj.jpg",
            "response_note" => "",
            "type" => "user"
          }
        ],
        "satoshi_amount" => 5000,
        "satoshi_fees" => 131,
        "time" => 1624024631,
        "transaction_id" => "4c7b7cdc18702bb1a09c75a47bc2fa9630545761fbbd53b8c38735c73173e043",
        "type" => "send"
      }}
  """
  @spec get_payment(Connect.t, String.t) :: {:ok, map} | {:error, any}
  def get_payment(%Connect{client: client} = _client, txid) do
    query = %{"transactionId" => txid}
    client
    |> Tesla.get(@endpoint <> "/payment", query: query)
    |> Connect.handle_result()
  end


  @doc """
  Returns the connected user's spendable balance.

  Can optionally be passed a currency code. By default uses the users preferred
  currency.

  ## Example

      iex> Handkit.Wallet.get_spendable_balance(client)
      {:ok, %{
        "currency_code" => "USD",
        "spendable_fiat_balance" => 2.3015,
        "spendable_satoshi_balance" => 1479882
      }}
  """
  @spec get_spendable_balance(Connect.t, String.t) :: {:ok, map} | {:error, any}
  def get_spendable_balance(%Connect{client: client} = _client, currency \\ "USD") do
    query = %{"currencyCode" => currency}
    client
    |> Tesla.get(@endpoint <> "/spendableBalance", query: query)
    |> Connect.handle_result()
  end


  @doc """
  Constructs and executes a transaction on behalf of the connected user.

  ## Payment parameters

  The payment parameters are a map containing the following keys:

  * `:app_action` - string used for transaction labeling and notification grouping
  * `:description` - max 25 character note describing the transaction
  * `:payments` - list of payment recipients
  * `:attachment` - parameters for a single data attachment output

  Each *payment recipient* is a map containing the following keys:

  * `:to` - recipient Handcash handle, paymail address or P2PKH Bitcoin address
  * `:currency_code` - recipient payment currency code
  * `:amount` - value of the payment measured in units of the specified currency code

  If provided, the *attachment parameters* is a map containing the following keys:

  * `:format` - format of the data from `"base64"`, `"hex"`, `"hexArray"` or `"json"`
  * `:value` - data value of the attachment in the specified format

  ## Example

      iex> payment_params = %{
      ...>   app_action: "test",
      ...>   attachment: %{
      ...>     format: "json",
      ...>     value: %{foo: "testing"}
      ...>   },
      ...>   description: "testing testing...",
      ...>   payments: [%{
      ...>     amount: 5,
      ...>     currency_code: "DUR",
      ...>     to: "Libs"
      ...>   }]
      ...> }
      iex> Handkit.Wallet.pay(client, payment_params)
      {:ok, %{
        "app_action" => "test",
        "attachments" => [%{"format" => "json", "value" => %{"foo" => "testing"}}],
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
        "raw_transaction_hex" => "0100000001b7acb150dc848a72e84c11d07b51d3b2fdb547fd98e1835b72a804b390c8c14c020000006a47304402204a4e5eb8da880821df2facc4f32d31481d5ceecbe714bb0de3d46c8ad9079f6a02203ab09fcab3bf235876c43c321bba9d3c916263fa93aab1ebab9ad5ddfbe2bc0b412102da3c986fc05050da02a2f5bd0143ab000467134e3c00460eb87977c7ada75bc6ffffffff03c4090000000000001976a91436795507d273218a19471fd863646a83525c67d188ac000000000000000014006a117b22666f6f223a2274657374696e67227db3080000000000001976a91420c908009397169108738ebe35cf53f70162501f88ac00000000",
        "satoshi_amount" => 2500,
        "satoshi_fees" => 128,
        "time" => 1624025595,
        "transaction_id" => "5a139f3f475f48001d733c8c767fa7124bb2835d927e01dd2782effd22f7081b",
        "type" => "send"
      }}
  """
  @spec pay(Connect.t, map) :: {:ok, map} | {:error, any}
  def pay(%Connect{client: client} = _client, %{} = params) do
    params = Enum.into(params, %{}, &rename_payments_key/1)

    client
    |> Tesla.post(@endpoint <> "/pay", params)
    |> Connect.handle_result()
  end

  # Replaces the "payments" key with "receivers"
  defp rename_payments_key({key, value})
    when key in [:payments, "payments"],
    do: {:receivers, value}

  defp rename_payments_key(pair), do: pair

end
