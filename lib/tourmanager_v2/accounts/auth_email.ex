defmodule TourmanagerV2.Accounts.AuthEmail do
  import Swoosh.Email

  def magic_link_email(email, url) do
    new()
    |> to(email)
    |> from({"Tour Manager", "noreply@tourmanager.live"})
    |> subject("Sign in to Tour Manager")
    |> text_body("""
    Sign in to Tour Manager

    Click the link below to sign in. This link expires in 15 minutes.

    #{url}

    If you didn't request this, you can safely ignore this email.
    """)
    |> html_body("""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; padding: 40px 20px;">
      <div style="background: #14110F; border-radius: 12px; overflow: hidden; border: 2px solid #14110F;">
        <div style="padding: 32px; background: #1C1917;">
          <div style="font-family: monospace; font-size: 10px; letter-spacing: 0.2em; color: #2B4FF0; margin-bottom: 8px;">TOUR MANAGER</div>
          <div style="font-size: 24px; font-weight: 800; color: #fff;">Sign in</div>
        </div>
        <div style="padding: 32px; background: #F5F1E8;">
          <p style="font-size: 14px; color: #44403C; line-height: 1.6; margin: 0 0 24px 0;">
            Click the button below to sign in to Tour Manager. This link expires in 15 minutes and can only be used once.
          </p>
          <a href="#{url}" style="display: block; text-align: center; padding: 14px 24px; background: #2B4FF0; color: #fff; font-family: monospace; font-size: 13px; font-weight: 700; letter-spacing: 0.06em; text-decoration: none; border-radius: 8px; border: 2px solid #14110F;">
            SIGN IN
          </a>
          <p style="font-family: monospace; font-size: 11px; color: #A8A29E; margin-top: 20px; text-align: center;">
            If the button doesn't work, copy this link:<br/>
            <span style="color: #78716C; word-break: break-all;">#{url}</span>
          </p>
        </div>
      </div>
    </div>
    """)
  end
end
