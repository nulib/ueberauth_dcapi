defmodule Ueberauth.Strategy.DcAPI.Test do
  use ExUnit.Case
  use Plug.Test
  alias Ueberauth.Strategy.DcAPI

  describe "request phase" do
    setup tags do
      conn =
        conn(:get, "/login")
        |> put_req_header("referer", tags[:referer])
        |> init_test_session(%{})
        |> Ueberauth.Strategy.run_request(DcAPI)

      {:ok, %{conn: conn}}
    end

    @tag referer: "https://referer.example.edu"
    test "redirect callback redirects to login url", %{conn: conn} do
      assert conn.status == 302
    end

    @tag referer: "https://referer.example.edu"
    test "https referer is passed through", %{conn: conn} do
      assert conn |> get_session("dcapiReferer") == "https://referer.example.edu"
    end

    @tag referer: "http://referer.example.edu"
    test "http referer is converted to https", %{conn: conn} do
      assert conn |> get_session("dcapiReferer") == "https://referer.example.edu"
    end
  end

  test "login callback without token shows an error" do
    conn = %Plug.Conn{cookies: %{}} |> init_test_session(%{}) |> DcAPI.handle_callback!()
    assert conn.assigns |> Map.has_key?(:ueberauth_failure)
  end

  describe "token validation" do
    @describetag referer: "https://referer.example.edu", token: "valid-token"
    setup %{referer: referer, token: token} do
      with conn <-
             %Plug.Conn{cookies: %{"dcApiCookie" => token}}
             |> init_test_session(%{dcapiReferer: referer})
             |> DcAPI.handle_callback!() do
        {:ok, %{conn: conn}}
      end
    end

    test "valid token", %{conn: conn} do
      with user <- conn.private.dcapi_user do
        assert user.isLoggedIn
        assert user.email == "archie.charles@example.edu"
        assert user.name == "Archie B. Charles"
        assert user.sub == "abc123"
      end
    end

    test "extracts UID", %{conn: conn} do
      assert conn |> DcAPI.uid() == "abc123"
    end

    test "generates an info struct", %{conn: conn} do
      assert info = conn |> DcAPI.info()
      assert info.email == "archie.charles@example.edu"
      assert info.name == "Archie B. Charles"
      assert info.nickname == "abc123"
    end

    test "generates a raw info struct", %{conn: conn} do
      assert user = DcAPI.extra(conn).raw_info.user
      assert user == conn.private.dcapi_user
    end

    test "resets original referer", %{conn: conn} do
      assert conn |> get_req_header("referer") == ["https://referer.example.edu"]
    end

    @tag token: "not-a-valid-token"
    test "invalid token", %{conn: conn} do
      refute conn.private.dcapi_user.isLoggedIn
    end

    @tag token: "server-error"
    test "error callback", %{conn: conn} do
      assert conn.assigns.ueberauth_failure.errors
             |> List.first()
             |> Map.get(:message) ==
               ~s'"Server Error"'
    end

    @tag token: "network-error"
    test "network error", %{conn: conn} do
      assert conn.assigns.ueberauth_failure.errors
             |> List.first()
             |> Map.get(:message) ==
               "non-existing domain"
    end

    @tag referer: nil
    test "no referer", %{conn: conn} do
      assert conn |> get_req_header("referer") == []
    end
  end
end
