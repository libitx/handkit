defmodule Handkit.ConnectTest do
  use ExUnit.Case
  alias Handkit.{Connect, ConnectError}

  describe "api_endpoint/1" do
    test "returns the api endpoint url for the given environment" do
      assert Connect.api_endpoint(:prod) =~ ~r/\/\/cloud\.handcash/
      assert Connect.api_endpoint(:beta) =~ ~r/\/\/beta\-cloud\.handcash/
      assert Connect.api_endpoint(:iae) =~ ~r/\/\/iae\-cloud\.handcash/
    end
  end

  describe "client_url/1" do
    test "returns the client url for the given environment" do
      assert Connect.client_url(:prod) =~ ~r/\/\/app\.handcash/
      assert Connect.client_url(:beta) =~ ~r/\/\/beta\-app\.handcash/
      assert Connect.client_url(:iae) =~ ~r/\/\/iae\-app\.handcash/
    end
  end

  describe "init_client/1" do
    test "returns a connect client struct" do
      assert %Connect{} = Connect.init_client("abc")
    end
  end

  describe "handle_result/2" do
    test "returns the json payload with a successful Tesla result" do
      assert {:ok, res} = Connect.handle_result({:ok, %Tesla.Env{status: 200, body: %{"foo" => "bar"}}})
      assert res == %{"foo" => "bar"}
    end

    test "returns a json value with a successful Tesla result and key parameter" do
      assert {:ok, res} = Connect.handle_result({:ok, %Tesla.Env{status: 200, body: %{"foo" => "bar"}}}, "foo")
      assert res == "bar"
    end

    test "returns a connect error with a successful Tesla result and error code" do
      assert {:error, err} = Connect.handle_result({:ok, %Tesla.Env{status: 400, body: %{"message" => "test", "info" => 123}}})
      assert %ConnectError{message: "test", info: 123} = err
    end
  end
end
