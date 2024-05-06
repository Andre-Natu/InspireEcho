defmodule Citacoes.Repo do
  use Ecto.Repo,
    otp_app: :citacoes,
    adapter: Ecto.Adapters.Postgres
end
