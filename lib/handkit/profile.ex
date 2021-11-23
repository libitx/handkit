defmodule Handkit.Profile do
  @moduledoc """
  Module for interfacing with the Handcash Connect `profile` API endpoint.

  The profile endpoint provides default access to the user's **public profile**.
  The user's **private profile** can also be accessed, given that those
  permissions are granted.

  The profile endpoint can also be used to access the users encryption keys and
  to sign data, dependent on those permissions being granted to the connected
  app.
  """
  alias Handkit.Connect

  @endpoint "/v1/connect/profile"

  @doc """
  Returns the full profile of the currently authenticated user.

  ## Example

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
  """
  @spec get_current_profile(Connect.t) :: {:ok, map} | {:error, any}
  def get_current_profile(%Connect{client: client} = _client) do
    client
    |> Tesla.get(@endpoint <> "/currentUserProfile")
    |> Connect.handle_result()
  end


  @doc """
  Return a list of friends, each including their own public profile.

  ## Example

      iex> Handkit.Profile.get_friends(client)
      {:ok, [
        %{
          "avatar_url" => "https://res.cloudinary.com/hk7jbd3jh/image/upload/v1584356800/hprcfwdasenpnrqei3uz.jpg",
          "bitcoin_unit" => "DUR",
          "display_name" => "Rafa JS",
          "handle" => "rjseibane",
          "id" => "5f64dfbd7549610022d2861b",
          "local_currency_code" => "USD",
          "paymail" => "rjseibane@internal.handcash.io"
        }
      ]}
  """
  @spec get_friends(Connect.t) :: {:ok, list(map)} | {:error, any}
  def get_friends(%Connect{client: client} = _client) do
    client
    |> Tesla.get(@endpoint <> "/friends")
    |> Connect.handle_result("items")
  end


  @doc """
  Returns a list of permissions for the currently authenticated user.

  ## Example

      iex> Handkit.Profile.get_permissions(client)
      {:ok, [
        "USER_PUBLIC_PROFILE",
        "USER_PRIVATE_PROFILE",
        "DECRYPT",
        "FRIENDS",
        "PAY",
        "SIGN_DATA"
      ]}
  """
  @spec get_permissions(Connect.t) :: {:ok, list(String.t)} | {:error, any}
  def get_permissions(%Connect{client: client} = _client) do
    client
    |> Tesla.get(@endpoint <> "/permissions")
    |> Connect.handle_result("items")
  end


  @doc """
  Looks up and returns a list of public profiles from the given list of Handcash
  handles.

  ## Examples

      iex> Handkit.Profile.get_permissions(client, ["cryptokang", "eyeone"])
      {:ok, [
        %{
          "avatar_url" => "https://handcash.io/avatar/7d399a0c-22cf-40cf-b162-f5511a4645db",
          "bitcoin_unit" => "DUR",
          "display_name" => "Brandon",
          "handle" => "cryptokang",
          "id" => "5f15c31c3c177d003028eb97",
          "local_currency_code" => "USD",
          "paymail" => "cryptokang@handcash.io"
        },
        %{
          "avatar_url" => "https://handcash.io/avatar/7d399a0c-22cf-40cf-b162-f5511a4645db",
          "bitcoin_unit" => "DUR",
          "display_name" => "Ivan",
          "handle" => "eyeone",
          "id" => "5f14c41c3c188d003027eb77",
          "local_currency_code" => "EUR",
          "paymail" => "eyeone@handcash.io"
        }
      ]}
  """
  @spec get_public_profiles_by_handle(Connect.t, list(String.t)) ::
    {:ok, list(map)} |
    {:error, any}
  def get_public_profiles_by_handle(%Connect{client: client} = _client, handles)
    when is_list(handles)
  do
    query = %{"aliases" => handles}
    client
    |> Tesla.get(@endpoint <> "/publicUserProfiles", query: query)
    |> Connect.handle_result("items")
  end


  @doc """
  Returns the encryption keypair for the currently authenticated user.

  ## Examples

      iex> Handkit.Profile.get_encryption_keypair(client)
      {:ok, %{
        "private_key" => "KwEdGZs5R6WNtNGknuG9DYd7NNdPw3CPNV9DZhjxNydYmLdA3hAs",
        "public_key" => "0370794c83b3228f808fe589a4f9e5286254e245d59fe2d5b6edd9e4fc128c2b5f"
      }}
  """
  @spec get_encryption_keypair(Connect.t) :: {:ok, map} | {:error, any}
  def get_encryption_keypair(%Connect{client: client} = _client) do
    key = BSV.KeyPair.new()
    query = %{"encryptionPublicKey" => BSV.PubKey.to_binary(key.pubkey, encoding: :hex)}

    result = client
    |> Tesla.get(@endpoint <> "/encryptionKeypair", query: query)
    |> Connect.handle_result()

    with {:ok, %{"encrypted_public_key_hex" => enc_pubkey, "encrypted_private_key_hex" => enc_privkey}} <- result do
      pubkey = BSV.Message.decrypt(enc_pubkey, key.privkey, encoding: :hex)
      privkey = BSV.Message.decrypt(enc_privkey, key.privkey, encoding: :hex)

      {:ok, %{"public_key" => pubkey, "private_key" => privkey}}
    end
  end


  @doc """
  Signs the given data value with the currently authenticated user's identity key.

  ## Options

  * `format` - The data value format, must be one of `"base64"`, `"hex"` or `"utf-8"` (default).

  ## Example

      iex> Handkit.Profile.sign_data(client, "Handkit")
      {:ok, %{
        "public_key" => "02f29085c38697e1014283cc80ee22fec356be2c7803bbad8c46f8d62000cb374e",
        "signature" => "Hyy5LdDZxRy8M2Kfzz0/l9g9eywoO/Eo+B3epfP6V+12Fum+l4J5tPofq0Uo0j3B4it8nxGqYYAQBo/bvgGA5qk="
      }}

      iex> Handkit.Profile.sign_data(client, "SGFuZGtpdA==", format: "base64")
      {:ok, %{
        "public_key" => "02f29085c38697e1014283cc80ee22fec356be2c7803bbad8c46f8d62000cb374e",
        "signature" => "Hyy5LdDZxRy8M2Kfzz0/l9g9eywoO/Eo+B3epfP6V+12Fum+l4J5tPofq0Uo0j3B4it8nxGqYYAQBo/bvgGA5qk="
      }}
  """
  @spec sign_data(Connect.t, binary, keyword) :: {:ok, map} | {:error, any}
  def sign_data(%Connect{client: client} = _client, value, opts \\ []) do
    format = Keyword.get(opts, :format, "utf-8")
    client
    |> Tesla.post(@endpoint <> "/signData", %{format: format, value: value})
    |> Connect.handle_result()
  end

end
