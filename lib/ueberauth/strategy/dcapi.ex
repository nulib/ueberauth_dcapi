defmodule Ueberauth.Strategy.DcAPI do
  @moduledoc """
  NUL Digital Collections API Strategy for Überauth. Redirects the
  user to the DC API login and verifies the JWT returned after a
  successful login.

  1. User is redirected to the DC API login page by
    `Ueberauth.Strategy.DcAPI.handle_request!`
  2. User signs in to the DC API server (currently via NUSSO).
  3. DC API server redirects back to the Elixir application, including
     the user's JWT in a cookie.
  4. This auth token is validated by this Überauth DcAPI strategy,
     fetching the user's information at the same time.
  5. User can proceed to use the Elixir application.
  """

  use Ueberauth.Strategy

  alias Ueberauth.Auth.{Extra, Info}

  import Plug.Conn

  @referer_key "dcapiReferer"

  @doc """
  Ueberauth `request` handler. Redirects to the DC API login route.
  """
  def handle_request!(conn) do
    conn
    |> put_session(@referer_key, extract_referer(conn))
    |> redirect!(redirect_url(conn))
  end

  @doc """
  Ueberauth after login callback with a valid DC API token.
  """
  def handle_callback!(%Plug.Conn{} = conn) do
    conn
    |> reset_referer()
    |> handle_token(conn.cookies[settings(:cookie)])
  end

  @doc """
  Ueberauth UID callback.
  """
  def uid(conn), do: conn.private |> get_in([:dcapi_user, :sub])

  @doc """
  Ueberauth extra information callback. Returns all information DC API
  returned about the user that authenticated.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        user: conn.private.dcapi_user
      }
    }
  end

  @doc """
  Ueberauth user information.
  """
  def info(conn) do
    with user <- conn.private.dcapi_user do
      %Info{
        email: Map.get(user, :email),
        name: Map.get(user, :name),
        nickname: Map.get(user, :sub)
      }
    end
  end

  defp redirect_url(conn) do
    callback_url(conn)
    |> force_https()
    |> login_url()
  end

  defp login_url(callback) do
    settings(:base_url) <> "/auth/login?goto=" <> callback
  end

  defp force_https(url) do
    with port <- settings(:ssl_port, 443) do
      case url |> URI.parse() do
        %URI{scheme: "https"} = uri -> uri
        uri -> %{uri | scheme: "https", port: port}
      end
      |> URI.to_string()
    end
  end

  defp reset_referer(%Plug.Conn{} = conn) do
    case conn |> get_session(@referer_key) do
      nil -> conn
      value -> conn |> delete_session(@referer_key) |> put_req_header("referer", value)
    end
  end

  defp extract_referer(%Plug.Conn{} = conn) do
    conn
    |> Plug.Conn.get_req_header("referer")
    |> extract_referer()
    |> force_https()
  end

  defp extract_referer([referer | _]), do: referer

  defp handle_token(conn, nil) do
    conn
    |> set_errors!([error("missing_jwt", "No DC API token received")])
  end

  defp handle_token(conn, token) do
    token
    |> fetch_user()
    |> handle_token_response(conn)
  end

  defp handle_token_response({:ok, %{body: body}}, conn) do
    with user <- Enum.map(body, fn {k, v} -> {String.to_atom(k), v} end) |> Enum.into(%{}) do
      conn
      |> put_private(:dcapi_user, user)
    end
  end

  defp handle_token_response({:error, reason}, conn) do
    with errors <- [error(reason.exception, reason.message)] do
      conn |> set_errors!(errors)
    end
  end

  def settings(key, default \\ nil) do
    with {_, settings} <-
           Application.get_env(:ueberauth, Ueberauth) |> get_in([:providers, :dcapi]) do
      settings |> Keyword.get(key, default)
    end
  end

  defp fetch_user(token) do
    Req.new(base_url: settings(:base_url))
    |> Req.get(url: "auth/whoami", auth: {:bearer, token})
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200} = response}), do: {:ok, response}

  defp handle_response({:ok, %Req.Response{status: status, body: body}}),
    do: {:error, %{exception: "Unknown Response", status_code: status, message: body}}

  defp handle_response({:error, error}) do
    with mod <- error.__struct__ do
      {:error, %{exception: mod, message: mod.message(error)}}
    end
  end
end
