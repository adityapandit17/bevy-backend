# Be sure to restart your server when you modify this file.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      "http://localhost:3001",
      "http://127.0.0.1:3001",
      "http://localhost:3002",
      "http://127.0.0.1:3002",
      "https://bevyhr.com",
      /https:\/\/.*\.bevyhr\.com/,
      # LAN / private-network dev (Expo Go, phone on same Wi‑Fi, lvh.me)
      /\Ahttp:\/\/192\.168\.\d{1,3}\.\d{1,3}(:\d+)?\z/,
      /\Ahttp:\/\/10\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\z/,
      /\Ahttp:\/\/172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}(:\d+)?\z/,
      /\Ahttp:\/\/.*\.lvh\.me(:\d+)?\z/
    ]
    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: false,
      expose: [ "Authorization" ]
  end
end
