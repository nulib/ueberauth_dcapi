import Config

config :ueberauth, Ueberauth,
  providers: [
    dcapi:
      {Ueberauth.Strategy.DcAPI,
       [
         base_url: "https://api.test.library.northwestern.edu/api/v2/",
         cookie: "dcApiCookie"
       ]}
  ]
