Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
             { scope: 'profile,email', hd: ENV['HOSTED_DOMAINS'], redirect_uri: 'https://production-vpn-wireguard.flowaccount.com/auth/google_oauth2/callback'}

end

OmniAuth.config.allowed_request_methods = %i[get]
