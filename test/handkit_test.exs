defmodule HandkitTest do
  use ExUnit.Case

  describe "get_redirection_url/2" do
    test "returns a redirection url for the default env" do
      url = Handkit.get_redirection_url("12345")
      assert url =~ ~r/\/\/app\.handcash/
      assert url =~ ~r/12345/
    end

    test "returns the redirection url with the extra params" do
      url = Handkit.get_redirection_url("12345", %{"foo" => "bar"})
      assert url =~ ~r/foo=bar/
      assert url =~ ~r/12345/
    end
  end


  describe "create_connect_client/2" do
    test "returns a connect client" do
      assert %Handkit.Connect{} = Handkit.create_connect_client("abc")
    end
  end
end
