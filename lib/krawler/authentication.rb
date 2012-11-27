module Krawler

  module Authentication

    def authenticate(agent, user, password, login_url)
      agent.get(login_url) do |page|
        login_form = page.form

        login_form['user[email]'] = user
        login_form['user[password]'] = password

        agent.submit(login_form, login_form.buttons.first)
      end
    end

    def use_authentication?
      !@username.nil? || !@password.nil? || !@login_url.nil?
    end

    def validate_authentication_options
      any_nil = [@login_url, @username, @password].any? {|v| v.nil?}
      all_nil = [@login_url, @username, @password].all? {|v| v.nil?}
      if (any_nil && !all_nil)
        puts "You must either provide all authentication options" +
          " (username, password, and loginurl) or provide none."
        return false
      else
        return true
      end
    end
  end

end