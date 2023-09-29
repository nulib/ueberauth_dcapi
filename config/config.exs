import Config

config :ueberauth, Ueberauth,
  providers: [
    dcapi:
      {Ueberauth.Strategy.DcAPI,
       [
         base_url: "https://api.dc.library.northwestern.edu/api/v2/",
         cookie: "dcapi56a927b"
       ]}
  ]

if File.exists?("config/#{Mix.env()}.exs"),
  do: import_config("#{Mix.env()}.exs")

if File.exists?("config/#{Mix.env()}.local.exs"),
  do: import_config("#{Mix.env()}.local.exs")
